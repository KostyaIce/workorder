#!/usr/bin/env python3
"""Helpers for service unit values."""


def is_percent_unit(unit):
    """Return True when unit represents a coefficient in percent."""
    value = str(unit or "").strip().casefold().replace(" ", "")
    if not value:
        return False
    return value in ("%", "проц", "проц.", "процент", "percent") or "%" in value
