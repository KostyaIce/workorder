#!/usr/bin/env python3
"""
QSettings storage wrapper.
Callers provide keys; organization, application name and QSettings instance are internal.
"""

from qt_compat import QCoreApplication, QSettings


class QSettingsStore:
    """Read and write application settings via QSettings."""

    _ORGANIZATION = "WorkOrderApp"
    _APPLICATION = "WorkOrder"

    def __init__(self):
        self._settings = self._create_settings()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.sync()
        return False

    def _create_settings(self):
        app = QCoreApplication.instance()
        if app is not None:
            if not app.organizationName():
                app.setOrganizationName(self._ORGANIZATION)
            if not app.applicationName():
                app.setApplicationName(self._APPLICATION)
            return QSettings()

        return QSettings(self._ORGANIZATION, self._APPLICATION)

    def read(self, key, default=None, value_type=None):
        """Read value by key. Optional value_type casts result (bool, int, str, ...)."""
        if value_type is not None:
            return self._settings.value(key, default, type=value_type)
        return self._settings.value(key, default)

    def write(self, key, value):
        """Write value by key. Persist on context exit or explicit sync()."""
        self._settings.setValue(key, value)

    def remove(self, key):
        """Remove key from storage. Persist on context exit or explicit sync()."""
        self._settings.remove(key)

    def contains(self, key):
        """Return True if key exists in storage."""
        return self._settings.contains(key)

    def sync(self):
        """Flush pending changes to disk."""
        self._settings.sync()
