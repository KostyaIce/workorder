# macOS: crash on window focus (Qt 6.8 Cocoa)

## Symptom

After an error (e.g. Yandex Disk 403) or when clicking the app window, WorkOrder aborts in:

`+[NSImage _systemImageNamed:]` ← `QCocoaIntegration::focusWindowChanged`

## Cause

Qt 6.8.x Cocoa plugin calls `[NSImage imageNamed:NSImageNameApplicationIcon]` when the key window changes. On recent macOS (including 26.x) this API can assert and terminate the process.

## Mitigation in this project

`cpp/app/MacCocoaWorkaround.mm` swizzles `+[NSImage imageNamed:]` at load time and replaces `NSImageNameApplicationIcon` with a workspace bundle icon.

## Long-term

Update Qt to **6.8.5+** or **6.9.1+** when available in your kit (see Qt security/fix releases for image handling).
