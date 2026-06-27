#!/usr/bin/env python3
"""Tests for report builder and report backend."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from backend.report_backend import ReportBackend
from backend.report_options_backend import ReportOptionsBackend
from backend.settings_backend import SettingsBackend
from utils.db_storage import create_clients_database, create_works_database
from utils.report_builder import build_work_report, save_work_report


class ReportBuilderTest(unittest.TestCase):
    def test_build_report_contains_personal_info(self):
        client = {
            "kind": "customer",
            "name": "Иванов И.И.",
            "contact_info": "+7 900",
            "address": "Москва",
            "notes": "",
        }
        object_data = {
            "name": "Квартира",
            "address": "Москва",
        }
        works = [{
            "name": "Диагностика",
            "quantity": 1,
            "price": 50000,
            "unit": "шт",
            "subobject_name": "Кухня",
        }]
        text = build_work_report("Исполнитель: Петров", client, object_data, works)
        self.assertIn("Исполнитель: Петров", text)
        self.assertIn("Иванов И.И.", text)
        self.assertIn("Диагностика", text)

    def test_save_report_creates_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "report.txt"
            path, content = save_work_report(
                "Profile",
                {"kind": "object", "name": "Склад", "contact_info": "", "address": "", "notes": ""},
                {"name": "Склад", "address": ""},
                [],
                file_path=str(target),
            )
            self.assertTrue(Path(path).exists())
            self.assertIn("Склад", content)


class ReportBackendTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.clients_path = str(Path(self.temp_dir.name) / "clients.db")
        self.works_path = str(Path(self.temp_dir.name) / "works.db")
        self.settings = SettingsBackend()
        self.settings.personalInfo = "ООО Ремонт\n+7 999"
        self.report_options = ReportOptionsBackend()
        self.backend = ReportBackend(self.settings, self.report_options)
        self.backend._clients_db_path = self.clients_path
        self.backend._works_db_path = self.works_path

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_add_client_and_generate_report(self):
        create_clients_database(self.clients_path)
        create_works_database(self.works_path)
        self.backend.initializeData()

        self.assertTrue(self.backend.addClient(
            "customer", "Новый клиент", "phone", "addr", "note"
        ))
        self.assertTrue(self.backend.addWorkForClient(
            self.backend.selectedClientId,
            "Тестовая работа",
            1000,
            2,
            "done",
        ))
        self.assertTrue(self.backend.generateReport(self.backend.selectedClientId))
        self.assertIn("Новый клиент", self.backend.lastReportText)
        self.assertIn("ООО Ремонт", self.backend.lastReportText)


if __name__ == "__main__":
    unittest.main()
