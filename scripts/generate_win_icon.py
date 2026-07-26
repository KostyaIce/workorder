#!/usr/bin/env python3
"""Regenerate resources/icons/appIcons/icon_win32.ico from icon_linux.png."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "resources" / "icons" / "appIcons" / "icon_linux.png"
DST = ROOT / "resources" / "icons" / "appIcons" / "icon_win32.ico"
SIZES = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]


def main() -> int:
    if not SRC.is_file():
        print(f"Error: source icon not found: {SRC}")
        return 1

    img = Image.open(SRC).convert("RGBA")
    images = [img.resize(size, Image.Resampling.LANCZOS) for size in SIZES]
    images[-1].save(DST, format="ICO", sizes=SIZES, append_images=images[:-1])
    print(f"Wrote {DST} ({DST.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
