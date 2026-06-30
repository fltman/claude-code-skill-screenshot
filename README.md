# claude-code-skill-screenshot

[![Support me on Patreon](https://img.shields.io/badge/Patreon-Support%20my%20work-FF424D?style=flat&logo=patreon&logoColor=white)](https://www.patreon.com/AndersBjarby)

A [Claude Code](https://docs.claude.com/en/docs/claude-code) skill that lets Claude take macOS screenshots itself — full screen, a specific display, an exact region, an interactively-selected rectangle, or a specific window — using the built-in `screencapture` command.

The skill saves PNGs to `/tmp/claude-screenshots/` and hands the path back to Claude, which then reads the image and can describe what it sees. Useful when you're debugging a UI bug, want Claude to look at an error dialog, or just want to share what's on your screen without manually taking the shot and dragging it in.

## What you can ask Claude to do

Once installed, just talk to Claude in plain language. The skill triggers automatically:

- "Take a screenshot of the whole screen"
- "Screenshot Safari" — captures the frontmost Safari window
- "Capture this window" — Claude will let you click which one
- "Show me what you see in VS Code"
- "Grab a screenshot — I'll select the area"

You don't need to remember any flags or commands.

## Requirements

- **macOS** (any recent version — uses the built-in `/usr/sbin/screencapture`)
- **Claude Code** installed ([install guide](https://docs.claude.com/en/docs/claude-code/setup))
- **Xcode Command Line Tools** for the helper scripts that list windows/displays. If `swift --version` works in your terminal, you're set. Otherwise install with:
  ```bash
  xcode-select --install
  ```
  (This pops up a system installer — takes a few minutes, no Xcode account needed.)

## Install

### Step 1 — clone the repo into your Claude skills folder

```bash
git clone https://github.com/fltman/claude-code-skill-screenshot ~/.claude/skills/screenshot
```

The path `~/.claude/skills/screenshot` is where Claude Code looks for user-installed skills. The folder name (`screenshot`) becomes the skill's identifier.

If you'd rather keep the repo somewhere else (e.g. `~/Projects/`) and symlink it in:

```bash
git clone https://github.com/fltman/claude-code-skill-screenshot ~/Projects/claude-code-skill-screenshot
ln -s ~/Projects/claude-code-skill-screenshot ~/.claude/skills/screenshot
```

### Step 2 — make the helper scripts executable

```bash
chmod +x ~/.claude/skills/screenshot/scripts/*.sh
```

### Step 3 — grant Screen Recording permission

macOS blocks screen capture by default. The terminal (or app) you run Claude Code in needs **Screen Recording** permission, otherwise `screencapture` will produce a black image with no warning.

1. Open **System Settings → Privacy & Security → Screen Recording**
2. Find the app you run Claude Code in (Terminal, iTerm, Ghostty, Warp, etc.) — or click **+** and add it
3. Toggle it **on**
4. **Quit and restart that app completely** (Cmd-Q, not just close the window) — macOS only re-checks permission on launch

### Step 4 — verify

Open Claude Code in your terminal and ask:

```
take a screenshot of the whole screen and tell me what's on it
```

Claude should run the capture script, read the resulting PNG, and describe it. If you instead get "the image is mostly black" or similar — that's the permission step above.

## Updating

Skills don't auto-update. To pull the latest version:

```bash
cd ~/.claude/skills/screenshot && git pull
```

## Uninstall

```bash
rm -rf ~/.claude/skills/screenshot
```

## Troubleshooting

**"swift not found"** when Claude tries to list windows
→ Run `xcode-select --install` and wait for the system installer to finish.

**Screenshots are mostly black**
→ Screen Recording permission isn't granted to your terminal app, or you didn't fully restart it after granting. See step 3 above.

**Claude doesn't trigger the skill when you ask for a screenshot**
→ The skill must live at `~/.claude/skills/screenshot/SKILL.md`. Verify with `ls ~/.claude/skills/screenshot/`. If it's somewhere else, move it or symlink.

**`scripts/capture.sh: Permission denied`**
→ Re-run step 2: `chmod +x ~/.claude/skills/screenshot/scripts/*.sh`

**Captures pile up in `/tmp/claude-screenshots/`**
→ macOS clears `/tmp` automatically across reboots. To put them somewhere permanent, set the env var when starting Claude Code:
```bash
CLAUDE_SCREENSHOT_DIR=~/Pictures/claude-shots claude
```

## How it works

Internally the skill is just a `SKILL.md` (instructions Claude reads) plus three small shell scripts:

- `scripts/capture.sh` — wraps `screencapture` with named modes: `full`, `display N`, `region X Y W H`, `select`, `pick-window`, `window <id>`, `app <name>`
- `scripts/list_windows.sh` — Swift one-liner that lists visible windows with their CGWindowIDs (so Claude can target a specific one non-interactively)
- `scripts/list_displays.sh` — Swift one-liner that lists active displays in the order `screencapture -D` numbers them

When you ask for a screenshot, Claude picks the right mode, runs the script via its Bash tool, gets the PNG path back, and reads the image with its multimodal Read tool. No third-party dependencies — everything is Apple-native.
