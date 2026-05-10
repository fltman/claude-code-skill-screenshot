# claude-code-skill-screenshot

A Claude Code skill that lets Claude take macOS screenshots itself — full screen, a specific display, an exact region, an interactive selection, or a specific window — using the built-in `screencapture` command.

The skill writes PNGs to `/tmp/claude-screenshots/` and prints the path so Claude can read the image multimodally with the Read tool.

## Install

```bash
ln -s "$PWD" ~/.claude/skills/screenshot
chmod +x scripts/*.sh
```

Then in any Claude Code session, ask Claude to take a screenshot. The skill triggers automatically.

## macOS permissions

The terminal or app running Claude Code needs **Screen Recording** permission (System Settings → Privacy & Security → Screen Recording). Restart the app after granting.

## Files

- `SKILL.md` — skill instructions Claude reads
- `scripts/capture.sh` — wrapper around `screencapture`. Modes: `full`, `display N`, `region X Y W H`, `select`, `pick-window`, `window <id>`, `app <name>`
- `scripts/list_windows.sh` — Swift helper that lists visible windows with their CGWindowIDs
- `scripts/list_displays.sh` — Swift helper that lists active displays in the order `screencapture -D` uses
