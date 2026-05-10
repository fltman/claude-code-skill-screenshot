#!/usr/bin/env bash
# list_windows.sh - lists visible application windows with their CGWindowID.
# Output (tab-separated): <windowID>\t<appName>\t<windowTitle>
# Filters out menubar, dock, and other non-app windows (layer != 0).
#
# Implemented in Swift (via `swift -`) because JXA's bridging of
# CGWindowListCopyWindowInfo's CFArray result is unreliable. Swift is shipped
# with Xcode Command Line Tools, which any dev machine has.
set -euo pipefail

if ! command -v swift >/dev/null 2>&1; then
  echo "swift not found. Install Xcode Command Line Tools: xcode-select --install" >&2
  exit 1
fi

swift - <<'SWIFT'
import CoreGraphics
import Foundation

let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
guard let windows = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else {
    FileHandle.standardError.write("CGWindowListCopyWindowInfo returned nil\n".data(using: .utf8)!)
    exit(1)
}

for w in windows {
    let layer = w[kCGWindowLayer as String] as? Int ?? -1
    if layer != 0 { continue }   // skip menubar, dock, system overlays

    let id = w[kCGWindowNumber as String] as? Int ?? 0
    let owner = w[kCGWindowOwnerName as String] as? String ?? ""
    let name = w[kCGWindowName as String] as? String ?? ""

    if owner.isEmpty { continue }
    print("\(id)\t\(owner)\t\(name)")
}
SWIFT
