#!/usr/bin/env python3
"""Tests for SQLite storage helpers."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from utils.db_storage import (
    create_works_database,
    default_settings_path,
    load_app_settings,
    save_app_settings,
)


class DbStorageTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_create_works_database(self):
        db_path, count = create_works_database("Иванов", "1")
        self.assertEqual(count, 0)
        self.assertTrue(Path(db_path).exists())

    def test_app_settings_roundtrip(self):
        settings_path = Path(self.temp_dir.name) / "app_settings.json"
        payload = {"theme": "dark", "language": "ru"}

        save_app_settings(payload, str(settings_path))
        loaded = load_app_settings(str(settings_path))

        self.assertEqual(loaded, payload)


if __name__ == "__main__":
    unittest.main()
