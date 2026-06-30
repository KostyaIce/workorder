#!/usr/bin/env python3
"""macOS Dock icon helpers for PyQt6 apps launched outside .app bundle."""

from __future__ import annotations

import ctypes
import ctypes.util
import logging
import sys

logger = logging.getLogger("workorder")

_OBJC = None


def _objc_library():
    global _OBJC
    if _OBJC is None:
        _OBJC = ctypes.cdll.LoadLibrary(ctypes.util.find_library("objc"))
    return _OBJC


def _sel(name: str):
    lib = _objc_library()
    lib.sel_registerName.restype = ctypes.c_void_p
    lib.sel_registerName.argtypes = [ctypes.c_char_p]
    return lib.sel_registerName(name.encode("utf-8"))


def _cls(name: str):
    lib = _objc_library()
    lib.objc_getClass.restype = ctypes.c_void_p
    lib.objc_getClass.argtypes = [ctypes.c_char_p]
    return lib.objc_getClass(name.encode("utf-8"))


def _msg_send0(receiver, selector):
    lib = _objc_library()
    lib.objc_msgSend.restype = ctypes.c_void_p
    lib.objc_msgSend.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
    return lib.objc_msgSend(receiver, selector)


def _msg_send1(receiver, selector, arg1):
    lib = _objc_library()
    lib.objc_msgSend.restype = ctypes.c_void_p
    lib.objc_msgSend.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p]
    return lib.objc_msgSend(receiver, selector, arg1)


def _ns_string(value: str):
    ns_string_class = _cls("NSString")
    return _msg_send1(
        ns_string_class,
        _sel("stringWithUTF8String:"),
        ctypes.c_char_p(value.encode("utf-8")),
    )


def set_dock_icon(icon_path: str) -> bool:
    """Set Dock icon via AppKit. Required when app is not started from .app bundle."""
    if sys.platform != "darwin":
        return False

    try:
        ns_app = _msg_send0(_cls("NSApplication"), _sel("sharedApplication"))
        if not ns_app:
            return False

        ns_image = _msg_send1(
            _msg_send0(_cls("NSImage"), _sel("alloc")),
            _sel("initWithContentsOfFile:"),
            _ns_string(icon_path),
        )
        if not ns_image:
            logger.warning("Failed to load macOS icon: %s", icon_path)
            return False

        _msg_send1(ns_app, _sel("setApplicationIconImage:"), ns_image)
        return True
    except Exception as exc:
        logger.warning("Failed to set macOS Dock icon: %s", exc)
        return False
