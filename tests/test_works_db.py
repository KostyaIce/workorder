#!/usr/bin/env python3
"""Tests for works SQLite storage."""

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from utils import works_db


class WorksDbTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.temp_dir.name) / "client_1.db"

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_add_work_with_coefficients(self):
        with patch.object(works_db, "object_db_path", return_value=self.db_path):
            works_db.create_works_table("Client", "1")
            work = works_db.add_work("Client", "1", {
                "object_id": "obj-1",
                "service_id": "svc-1",
                "subobject_name": "Room",
                "name": "Montage",
                "price": 10000,
                "unit": "m",
                "quantity": 2,
                "coefficients": "A, B",
                "percent_sum": 105,
            })
            loaded = works_db.load_works("Client", "1")

        self.assertEqual(work["coefficients"], "A, B")
        self.assertEqual(work["percent_sum"], 105)
        self.assertEqual(len(loaded), 1)
        self.assertEqual(loaded[0]["percent_sum"], 105)


if __name__ == "__main__":
    unittest.main()
