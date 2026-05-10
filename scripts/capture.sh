#!/usr/bin/env bash
# capture.sh - macOS screenshot wrapper for the `screenshot` Claude Code skill.
# Prints the absolute path of the saved PNG on stdout.
set -euo pipefail

OUTDIR="${CLAUDE_SCREENSHOT_DIR:-/tmp/claude-screenshots}"
mkdir -p "$OUTDIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTFILE="$OUTDIR/screenshot-$TIMESTAMP.png"

usage() {
  cat >&2 <<EOF
Usage: capture.sh <mode> [args...]

Modes:
  full                       Capture all displays (merged into one image)
  display <N>                Capture display N (1 = primary)
  region <X> <Y> <W> <H>     Capture an exact rectangle (top-left origin)
  select                     Interactive: user drags a rectangle
  pick-window                Interactive: user clicks a window
  window <windowID>          Capture a specific window by ID (see list_windows.sh)
  app <appName>              Capture the frontmost window of a named app (e.g. Safari, "Visual Studio Code")

Output goes to \$CLAUDE_SCREENSHOT_DIR (default: /tmp/claude-screenshots/).
EOF
  exit 1
}

# Find the frontmost on-screen window ID for an app whose owner name matches
# (case-insensitive substring) the given query. Prints the window ID on stdout,
# or exits non-zero with a message on stderr.
find_app_window_id() {
  local query="$1"
  swift - "$query" <<'SWIFT'
import CoreGraphics
import Foundation

let args = CommandLine.arguments
guard args.count >= 2 else { exit(2) }
let query = args[1].lowercased()

let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
guard let windows = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else {
    FileHandle.standardError.write("CGWindowListCopyWindowInfo returned nil\n".data(using: .utf8)!)
    exit(1)
}

// CGWindowList returns windows in front-to-back order. First layer-0 match wins.
for w in windows {
    let layer = w[kCGWindowLayer as String] as? Int ?? -1
    if layer != 0 { continue }
    let owner = (w[kCGWindowOwnerName as String] as? String ?? "").lowercased()
    if owner.contains(query) {
        if let id = w[kCGWindowNumber as String] as? Int {
            print(id)
            exit(0)
        }
    }
}

FileHandle.standardError.write("No on-screen window found for app matching: \(args[1])\n".data(using: .utf8)!)
exit(3)
SWIFT
}

MODE="${1:-}"
[ -z "$MODE" ] && usage
shift || true

case "$MODE" in
  full)
    screencapture -x "$OUTFILE"
    ;;
  display)
    DISPLAY_NUM="${1:-1}"
    screencapture -x -D "$DISPLAY_NUM" "$OUTFILE"
    ;;
  region)
    [ $# -lt 4 ] && { echo "region needs X Y W H" >&2; usage; }
    screencapture -x -R "$1,$2,$3,$4" "$OUTFILE"
    ;;
  select)
    screencapture -i "$OUTFILE"
    ;;
  pick-window)
    screencapture -iWo "$OUTFILE"
    ;;
  window)
    [ -z "${1:-}" ] && { echo "window needs <windowID>" >&2; usage; }
    screencapture -x -o -l "$1" "$OUTFILE"
    ;;
  app)
    [ -z "${1:-}" ] && { echo "app needs <appName>" >&2; usage; }
    WIN_ID=$(find_app_window_id "$1")
    screencapture -x -o -l "$WIN_ID" "$OUTFILE"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    usage
    ;;
esac

if [ ! -f "$OUTFILE" ]; then
  echo "No screenshot was created (interactive selection cancelled?)" >&2
  exit 2
fi

echo "$OUTFILE"
