#!/usr/bin/env bash
# list_displays.sh - lists active displays in the order screencapture's -D flag uses.
# Output (tab-separated): <displayNumber>\t<width>x<height>\t<main|secondary>
#
# Note: `screencapture -D N` is 1-indexed. The N here matches that order.
set -euo pipefail

if ! command -v swift >/dev/null 2>&1; then
  echo "swift not found. Install Xcode Command Line Tools: xcode-select --install" >&2
  exit 1
fi

swift - <<'SWIFT'
import CoreGraphics
import Foundation

var count: UInt32 = 0
guard CGGetActiveDisplayList(0, nil, &count) == .success else {
    FileHandle.standardError.write("CGGetActiveDisplayList failed\n".data(using: .utf8)!)
    exit(1)
}

var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
guard CGGetActiveDisplayList(count, &displays, &count) == .success else {
    FileHandle.standardError.write("CGGetActiveDisplayList (fill) failed\n".data(using: .utf8)!)
    exit(1)
}

let mainID = CGMainDisplayID()
for (i, id) in displays.enumerated() {
    let w = CGDisplayPixelsWide(id)
    let h = CGDisplayPixelsHigh(id)
    let role = (id == mainID) ? "main" : "secondary"
    // 1-indexed to match screencapture -D
    print("\(i + 1)\t\(w)x\(h)\t\(role)")
}
SWIFT
