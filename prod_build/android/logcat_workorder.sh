#!/usr/bin/env bash
# Capture WorkOrder Android logs (logcat + optional file tail hint).
set -euo pipefail

PACKAGE="${WORKORDER_ANDROID_PACKAGE:-com.workorder}"

if ! command -v adb >/dev/null 2>&1; then
    echo "adb not found" >&2
    exit 1
fi

if ! adb get-state >/dev/null 2>&1; then
    echo "No device connected. Enable USB debugging and reconnect." >&2
    exit 1
fi

echo "Clearing logcat buffer..." >&2
adb logcat -c

PID="$(adb shell pidof "$PACKAGE" 2>/dev/null | tr -d '\r' || true)"
echo "Package: $PACKAGE" >&2
if [ -n "$PID" ]; then
    echo "PID: $PID (logcat filtered by process)" >&2
else
    echo "App not running yet — start WorkOrder on the device." >&2
fi
echo "File log on device: run-as $PACKAGE cat files/data/debug.log" >&2
echo "Press Ctrl+C to stop." >&2

if [ -n "$PID" ]; then
    adb logcat -v time --pid="$PID"
else
    adb logcat -v time 2>&1 | grep --line-buffered -iE \
        '\[workorder\]|python|Qt:|Traceback|AndroidRuntime|FATAL EXCEPTION|com\.workorder\.workorder'
fi
