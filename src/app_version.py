#!/usr/bin/env python3
"""Read application version from version.mk (single source of truth)."""

from __future__ import annotations

import re
from pathlib import Path

_VERSION_RE = {
    "major": re.compile(r"^VERSION_MAJOR=(\d+)\s*$", re.MULTILINE),
    "minor": re.compile(r"^VERSION_MINOR=(\d+)\s*$", re.MULTILINE),
    "patch": re.compile(r"^VERSION_PATCH=(\d+)\s*$", re.MULTILINE),
}


def _project_root() -> Path:
    return Path(__file__).resolve().parents[1]


def read_version_parts(version_mk: Path | None = None) -> tuple[int, int, int]:
    path = version_mk or (_project_root() / "version.mk")
    if not path.is_file():
        return 1, 0, 0
    text = path.read_text(encoding="utf-8")
    major = _VERSION_RE["major"].search(text)
    minor = _VERSION_RE["minor"].search(text)
    patch = _VERSION_RE["patch"].search(text)
    if not major or not minor or not patch:
        return 1, 0, 0
    return int(major.group(1)), int(minor.group(1)), int(patch.group(1))


def get_version(version_mk: Path | None = None) -> str:
    major, minor, patch = read_version_parts(version_mk)
    return f"{major}.{minor}.{patch}"


def get_version_name(version_mk: Path | None = None) -> str:
    """Android-style version name: MAJOR.MINOR-PATCH."""
    major, minor, patch = read_version_parts(version_mk)
    return f"{major}.{minor}-{patch}"
