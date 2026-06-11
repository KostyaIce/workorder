#!/usr/bin/env python3
"""Tests for SQLite storage helpers."""

import sys
import sqlite3
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from utils.db_storage import (
    create_services_database,
    create_works_database,
    get_services_statistics,
    get_works_statistics,
    load_completed_works,
    load_services,
    repair_services_database,
    repair_works_database,
)


class DbStorageTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.services_path = Path(self.temp_dir.name) / "services.db"
        self.works_path = Path(self.temp_dir.name) / "works.db"

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_create_services_database(self):
        db_path, count = create_services_database(str(self.services_path))
        self.assertEqual(db_path, str(self.services_path.resolve()))
        self.assertEqual(count, 15)

        services = load_services(db_path)
        self.assertEqual(len(services), 15)
        self.assertEqual(services[0]["name"], "Диагностика оборудования")

    def test_create_works_database(self):
        db_path, count = create_works_database(str(self.works_path))
        self.assertEqual(count, 8)

        works = load_completed_works(db_path)
        self.assertEqual(len(works), 8)
        self.assertEqual(works[0]["work_number"], "WO-0001")
        self.assertEqual(works[-1]["status"], "in_progress")

    def test_statistics(self):
        create_services_database(str(self.services_path))
        create_works_database(str(self.works_path))

        services_stats = get_services_statistics(str(self.services_path))
        works_stats = get_works_statistics(str(self.works_path))

        self.assertEqual(services_stats["count"], 15)
        self.assertGreater(services_stats["max_price"], services_stats["min_price"])
        self.assertEqual(works_stats["count"], 8)
        self.assertEqual(works_stats["completed_count"], 7)
        self.assertEqual(works_stats["in_progress_count"], 1)

    def test_repair_services_database(self):
        create_services_database(str(self.services_path))
        with sqlite3.connect(self.services_path) as conn:
            conn.execute("UPDATE services SET name = '' WHERE id = 15")
            conn.execute(
                "UPDATE services SET name = ? WHERE id = ?",
                ("ремонт компьютера", 14),
            )
            conn.commit()

        report, _ = repair_services_database(str(self.services_path))
        services = load_services(str(self.services_path))

        self.assertGreater(report["removed"], 0)
        self.assertEqual(len(services), 13)

    def test_repair_works_database_recalculates_total(self):
        create_works_database(str(self.works_path))
        with sqlite3.connect(self.works_path) as conn:
            conn.execute(
                "UPDATE completed_works SET total_price = 1, quantity = 2, unit_price = 500 WHERE id = 1"
            )
            conn.commit()

        report, _ = repair_works_database(str(self.works_path))
        works = load_completed_works(str(self.works_path))

        self.assertTrue(any("recalculated_total" in item for item in report["fixed"]))
        self.assertEqual(works[0]["total_price"], 1000.0)


class DatabaseBackendDbTest(unittest.TestCase):
    def setUp(self):
        from backend.database_backend import DatabaseBackend

        self.temp_dir = tempfile.TemporaryDirectory()
        self.backend = DatabaseBackend()
        self.services_path = str(Path(self.temp_dir.name) / "services.db")
        self.works_path = str(Path(self.temp_dir.name) / "works.db")

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_backend_create_and_load_databases(self):
        self.assertTrue(self.backend.createServicesDatabase(self.services_path))
        self.assertEqual(self.backend.serviceCount, 15)
        self.assertEqual(
            Path(self.backend.servicesDbPath),
            Path(self.services_path).resolve(),
        )

        self.assertTrue(self.backend.createWorksDatabase(self.works_path))
        self.assertEqual(self.backend.workCount, 8)
        works = self.backend.getAllCompletedWorks()
        self.assertEqual(works[0]["client_name"], "Иванов И.И.")

        stats = self.backend.getWorksStatistics(self.works_path)
        self.assertEqual(stats["completed_count"], 7)

    def test_backend_repair_database(self):
        self.backend.createServicesDatabase(self.services_path)
        self.assertTrue(self.backend.repairDatabase(self.services_path))
        self.assertEqual(self.backend.serviceCount, 15)


if __name__ == "__main__":
    unittest.main()
