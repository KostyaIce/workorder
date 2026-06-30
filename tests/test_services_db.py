#!/usr/bin/env python3
"""Tests for services SQLite storage."""

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from utils import services_db


class ServicesDbTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.temp_dir.name) / "services.db"

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_create_services_table(self):
        with patch.object(services_db, "default_services_db_path", return_value=self.db_path):
            services_db.create_services_table()
            services_db.add_service({"name": "Диагностика", "price": "500", "unit": "шт"})
            services = services_db.load_services()

        self.assertEqual(len(services), 1)
        self.assertEqual(services[0]["name"], "Диагностика")
        self.assertEqual(services[0]["price"], 50000)


if __name__ == "__main__":
    unittest.main()
