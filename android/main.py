#!/usr/bin/env python3
"""Android entry point for pyside6-android-deploy (requires main.py name)."""
import os
import sys
import traceback
from pathlib import Path

_here = Path(__file__).resolve().parent
if (_here / "src").is_dir():
    ROOT = _here
elif (_here.parent / "src").is_dir():
    ROOT = _here.parent
else:
    ROOT = _here.parent
SRC = ROOT / "src"

sys.path.insert(0, str(SRC))
os.environ.setdefault("WORKORDER_PLATFORM", "android")
os.environ.setdefault("WORKORDER_APP_TYPE", "mobile")

if __name__ == "__main__":
    try:
        from main import main
        main()
    except Exception:
        traceback.print_exc()
        sys.stdout.flush()
        sys.stderr.flush()
        raise
