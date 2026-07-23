#!/usr/bin/env python3
"""
Application logging via Qt message handler (same approach as C++ AppLogging / DapLogger).

Application code should use qDebug/qInfo/qWarning (or Python logging which is
mirrored into the same file). Do not invent a parallel log API.
"""

from __future__ import annotations

import logging
import sys
from datetime import datetime, timedelta
from pathlib import Path

from app_paths import data_dir, is_android_runtime
from qt_compat import QtMsgType, qInstallMessageHandler

_LOG_DIR: Path | None = None
_LOG_FILE: Path | None = None
_FILE_HANDLE = None


def path_to_log() -> Path | None:
    return _LOG_DIR


def path_to_file() -> Path | None:
    return _LOG_FILE


def _level_tag(mode) -> str:
    if mode == QtMsgType.QtInfoMsg:
        return "INF"
    if mode == QtMsgType.QtWarningMsg:
        return "WAR"
    if mode == QtMsgType.QtCriticalMsg:
        return "ERR"
    if mode == QtMsgType.QtFatalMsg:
        return "FATAL"
    return "DEB"


def _format_line(mode, message: str, category: str = "default") -> str:
    stamp = datetime.now().isoformat(timespec="seconds")
    return f" [{stamp}] [{_level_tag(mode)}] {category}: {message}"


def _ensure_log_file() -> None:
    global _LOG_DIR, _LOG_FILE, _FILE_HANDLE
    if _FILE_HANDLE is not None:
        return

    _LOG_DIR = data_dir() / "logs"
    _LOG_DIR.mkdir(parents=True, exist_ok=True)

    # Drop logs older than 2 days
    cutoff = datetime.now() - timedelta(days=2)
    for path in _LOG_DIR.glob("WorkOrder_*.log"):
        try:
            if datetime.fromtimestamp(path.stat().st_mtime) < cutoff:
                path.unlink(missing_ok=True)
        except OSError:
            pass

    _LOG_FILE = _LOG_DIR / f"WorkOrder_{datetime.now().strftime('%d-%m-%Y')}.log"
    _FILE_HANDLE = open(_LOG_FILE, "a", encoding="utf-8")


def _write_line(line: str, mode=None) -> None:
    _ensure_log_file()
    if _FILE_HANDLE is not None:
        _FILE_HANDLE.write(line + "\n")
        _FILE_HANDLE.flush()

    if is_android_runtime():
        print(f"[workorder] {line}", flush=True)
    else:
        print(line, file=sys.stderr, flush=True)


def _qt_message_handler(mode, context, message: str) -> None:
    category = "default"
    if context is not None:
        cat = getattr(context, "category", None)
        if cat:
            category = str(cat)
    line = _format_line(mode, message, category)
    _write_line(line, mode)


class _QtMirrorHandler(logging.Handler):
    """Forward Python logging records into the same sink as Qt messages."""

    def emit(self, record: logging.LogRecord) -> None:
        try:
            if record.levelno >= logging.CRITICAL:
                mode = QtMsgType.QtFatalMsg
            elif record.levelno >= logging.ERROR:
                mode = QtMsgType.QtCriticalMsg
            elif record.levelno >= logging.WARNING:
                mode = QtMsgType.QtWarningMsg
            elif record.levelno >= logging.INFO:
                mode = QtMsgType.QtInfoMsg
            else:
                mode = QtMsgType.QtDebugMsg
            line = _format_line(mode, record.getMessage(), record.name or "workorder")
            _write_line(line, mode)
        except Exception:
            self.handleError(record)


def setup_app_logging() -> Path | None:
    """Install qInstallMessageHandler and mirror Python logging to the same file."""
    _ensure_log_file()
    qInstallMessageHandler(_qt_message_handler)

    root = logging.getLogger()
    root.setLevel(logging.DEBUG)
    # Avoid duplicate stream handlers; one mirror into Qt sink is enough.
    root.handlers.clear()
    root.addHandler(_QtMirrorHandler())

    return _LOG_FILE
