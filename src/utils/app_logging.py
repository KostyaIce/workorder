"""Application logging setup (desktop + Android file/logcat)."""
from __future__ import annotations

import logging
import sys
from pathlib import Path

from app_paths import data_dir, is_android_runtime

LOG_TAG = "workorder"
_LOG_FORMAT = "%(asctime)s [%(levelname)s] %(name)s: %(message)s"


class AndroidLogcatHandler(logging.Handler):
    """Mirror log records to stdout for p4a logcat (tag python)."""

    def emit(self, record: logging.LogRecord) -> None:
        try:
            print(f"[{LOG_TAG}] {record.getMessage()}", flush=True)
        except Exception:
            self.handleError(record)


def setup_app_logging() -> Path | None:
    root = logging.getLogger()
    root.setLevel(logging.DEBUG)

    formatter = logging.Formatter(_LOG_FORMAT)

    if not any(isinstance(h, logging.StreamHandler) and not isinstance(h, logging.FileHandler)
               for h in root.handlers):
        stream_handler = logging.StreamHandler(sys.stderr)
        stream_handler.setFormatter(formatter)
        root.addHandler(stream_handler)

    log_file = None
    if is_android_runtime():
        log_file = data_dir() / "debug.log"
        if not any(isinstance(h, logging.FileHandler) for h in root.handlers):
            file_handler = logging.FileHandler(log_file, encoding="utf-8")
            file_handler.setFormatter(formatter)
            root.addHandler(file_handler)

        if not any(isinstance(h, AndroidLogcatHandler) for h in root.handlers):
            root.addHandler(AndroidLogcatHandler())

    return log_file
