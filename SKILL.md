---
name: screenshot
description: Capture macOS screenshots from Claude Code — full screen, a specific display, an exact region by coordinates, an interactively-dragged rectangle, or a specific window (by ID or by clicking). Saves PNGs to /tmp/claude-screenshots/ and returns the path so Claude can read the image multimodally with the Read tool. Use whenever the user asks to take a screenshot, capture the screen, grab a window, screencap something, or wants Claude to see what's on their screen — including UI debugging where Claude needs to see the actual rendered output, or when the user describes a visual problem and seeing it directly would help.
---

# Screenshot

Capture screenshots on macOS using the built-in `screencapture` command, then read the resulting image back with the Read tool so you can actually see what's on the user's screen.

## When to use this skill

- The user asks for a screenshot ("ta en screenshot", "screencap", "capture this", "show me what's on screen")
- The user is debugging a UI issue and you need to see the rendered output
- The user pastes a description of a visual problem and a picture would clarify it
- You're about to ask the user to manually attach a screenshot — try this skill first

## Output

All captures are written to `/tmp/claude-screenshots/screenshot-<YYYYMMDD-HHMMSS>.png`. The capture script prints the absolute path on stdout. After running it, immediately call the Read tool on that path to view the image.

## Modes

The capture script (`scripts/capture.sh`) takes a mode as the first argument. Pick the mode that matches the user's intent — when in doubt, ask the user, but lean toward `select` (interactive region) since it's the most common case and matches what people mean by "take a screenshot of X".

### Full screen — all displays merged

```bash
scripts/capture.sh full
```

Use when the user wants everything visible across all monitors.

### Specific display

```bash
scripts/capture.sh display 1   # primary display
scripts/capture.sh display 2   # second monitor
```

Use when the user has multiple monitors and only wants one. Run `scripts/list_displays.sh` first to see what's available — it prints `<displayN>\t<WxH>\t<main|secondary>` and the `displayN` matches the argument to `display`.

### Exact region (non-interactive)

```bash
scripts/capture.sh region X Y W H
# example: top-left 800x600 region
scripts/capture.sh region 0 0 800 600
```

Coordinates are in screen points, origin top-left. Use when you already know the precise region (rare — usually you'll use `select` instead).

### Interactive region (user drags a rectangle)

```bash
scripts/capture.sh select
```

The macOS crosshair appears and the user drags out a rectangle. Press space to switch to window mode, Esc to cancel. **Use a long Bash timeout (300000 ms = 5 min)** since the command blocks until the user finishes selecting.

This is the right default when the user says "take a screenshot of X" without further specifics.

### Interactive window picker (user clicks a window)

```bash
scripts/capture.sh pick-window
```

The crosshair turns into a camera. The user clicks the window they want. Window shadow is excluded (`-o`). Same long-timeout caveat as `select`.

Use when the user wants a specific app window and it's easier for them to click it than to describe it.

### Capture a window by ID (non-interactive)

```bash
scripts/capture.sh window 12345
```

Use when you've already discovered the window ID via `list-windows` (below) and want to capture it without bothering the user. Window shadow is excluded.

### Capture the frontmost window of a named app (non-interactive)

```bash
scripts/capture.sh app Safari
scripts/capture.sh app "Visual Studio Code"
scripts/capture.sh app terminal     # case-insensitive substring match
```

Use this when the user names an app — "screenshot Safari", "fånga VS Code", "ta en bild av Slack". It picks the topmost on-screen window owned by the matching app. Much friendlier than asking the user for a window ID. Fails with a clear message if no matching window is open.

### List visible windows with their IDs

```bash
scripts/list_windows.sh
```

Prints one line per visible window: `<windowID>\t<appName>\t<windowTitle>`. Use this to find the ID of a specific window before calling `capture.sh window <id>`. (For the common case of "capture the frontmost window of app X", prefer `capture.sh app <name>` instead — it does the lookup for you.)

### List active displays

```bash
scripts/list_displays.sh
```

Prints `<displayN>\t<WxH>\t<main|secondary>`. The `displayN` is what you pass to `capture.sh display N`.

Example flow:

```bash
$ scripts/list_windows.sh
4127    Safari  Anthropic — Hello, world
4128    Visual Studio Code  SKILL.md — claude-code-skill-screenshot
4131    Terminal        bash — 80x24

$ scripts/capture.sh window 4128
/tmp/claude-screenshots/screenshot-20260510-143022.png
```

## After capturing

The script prints the path. Read it with the Read tool so you can see the image:

```
Read("/tmp/claude-screenshots/screenshot-20260510-143022.png")
```

Then describe what you see, or use it as context for the user's question.

## Permissions

On macOS 10.15+, the parent process (Terminal, iTerm, the Claude Code app) needs **Screen Recording** permission in System Settings → Privacy & Security → Screen Recording. If `screencapture` produces a black image or fails, that's the cause — direct the user there. The setting requires the parent app to be restarted after granting.

## Customizing the output directory

Set `CLAUDE_SCREENSHOT_DIR` to override `/tmp/claude-screenshots`:

```bash
CLAUDE_SCREENSHOT_DIR=~/Pictures/claude scripts/capture.sh full
```

## Why these defaults

- **PNG, not JPG**: lossless, captures UI text crisply, and the multimodal Read tool handles it natively.
- **Silent (`-x`)**: no shutter sound when Claude triggers the capture programmatically. The user didn't press the button, so the sound would be confusing.
- **No window shadow (`-o` for window modes)**: shadows add transparent padding that wastes pixels and confuses anyone trying to crop the result.
- **Timestamped filenames in `/tmp`**: avoids collisions, lets macOS clean them up automatically, and the path is easy to pass to the Read tool.
