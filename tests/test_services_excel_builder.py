#!/usr/bin/env python3
"""Tests for services Excel import parser."""

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from openpyxl import Workbook

from utils import services_db
from utils.services_excel_builder import (
    ServicesExcelBuilder,
    export_services_excel,
    import_services_from_excel,
    parse_excel_price,
)


class ServicesExcelBuilderTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.file_path = Path(self.temp_dir.name) / "services.xlsx"

    def tearDown(self):
        self.temp_dir.cleanup()

    def _write_workbook(self, rows):
        workbook = Workbook()
        sheet = workbook.active
        for row in rows:
            sheet.append(row)
        workbook.save(self.file_path)
        workbook.close()

    def test_parse_excel_price(self):
        self.assertIsNone(parse_excel_price(None))
        self.assertIsNone(parse_excel_price(""))
        self.assertEqual(parse_excel_price(500), 50000)
        self.assertEqual(parse_excel_price("500"), 50000)
        self.assertEqual(parse_excel_price("5.50"), 550)
        self.assertEqual(parse_excel_price(5.5), 550)

    def test_read_services_with_paragraphs(self):
        self._write_workbook([
            ["Раздел А", None, None, None],
            ["Диагностика", "Первичный осмотр", 500, "шт"],
            ["Консультация", "Устная", "5.50", "%"],
            ["Раздел Б", None, None, None],
            ["Ремонт", "", 1200, ""],
        ])

        services = ServicesExcelBuilder().read_services(self.file_path)

        self.assertEqual(len(services), 3)
        self.assertEqual(services[0]["name"], "Диагностика")
        self.assertEqual(services[0]["note"], "Первичный осмотр")
        self.assertEqual(services[0]["paragraph"], "Раздел А")
        self.assertEqual(services[0]["price"], "500.00")
        self.assertEqual(services[0]["unit"], "шт")
        self.assertEqual(services[1]["unit"], "%")
        self.assertEqual(services[1]["price"], "5.50")
        self.assertEqual(services[2]["paragraph"], "Раздел Б")
        self.assertEqual(services[2]["unit"], "")

    def test_import_services_from_excel_to_db(self):
        self._write_workbook([
            ["Общие работы", None, None, None],
            ["Монтаж", "Базовый", 100, "м"],
        ])

        db_path = Path(self.temp_dir.name) / "services.db"
        with patch.object(services_db, "default_services_db_path", return_value=db_path):
            services = import_services_from_excel(str(self.file_path))
            services_db.create_services_table()
            for item in services:
                services_db.add_service(item)
            loaded = services_db.load_services()

        self.assertEqual(len(loaded), 1)
        self.assertEqual(loaded[0]["name"], "Монтаж")
        self.assertEqual(loaded[0]["paragraph"], "Общие работы")
        self.assertEqual(loaded[0]["price"], 10000)

    def test_write_export_groups_by_paragraph(self):
        services = [
            {
                "name": "Ремонт",
                "note": "",
                "paragraph": "Раздел Б",
                "price": 120000,
                "unit": "",
            },
            {
                "name": "Диагностика",
                "note": "Первичный осмотр",
                "paragraph": "Раздел А",
                "price": 50000,
                "unit": "шт",
            },
            {
                "name": "Консультация",
                "note": "Устная",
                "paragraph": "Раздел А",
                "price": 550,
                "unit": "%",
            },
            {
                "name": "Без раздела",
                "note": "note",
                "paragraph": "",
                "price": 10000,
                "unit": "м",
            },
        ]

        export_path = Path(self.temp_dir.name) / "export.xlsx"
        ServicesExcelBuilder().write_export(export_path, services)
        imported = ServicesExcelBuilder().read_services(export_path)

        self.assertEqual(len(imported), 4)
        self.assertEqual(imported[0]["name"], "Без раздела")
        self.assertEqual(imported[0]["paragraph"], "")
        self.assertEqual(imported[1]["name"], "Диагностика")
        self.assertEqual(imported[1]["paragraph"], "Раздел А")
        self.assertEqual(imported[1]["price"], "500.00")
        self.assertEqual(imported[2]["name"], "Консультация")
        self.assertEqual(imported[2]["price"], "5.50")
        self.assertEqual(imported[3]["name"], "Ремонт")
        self.assertEqual(imported[3]["paragraph"], "Раздел Б")

    def test_export_services_excel(self):
        services = [
            {
                "name": "Монтаж",
                "note": "Базовый",
                "paragraph": "Общие работы",
                "price": 10000,
                "unit": "м",
            },
        ]
        export_path = Path(self.temp_dir.name) / "catalog"
        saved_path = export_services_excel(str(export_path), services)

        self.assertTrue(saved_path.endswith(".xlsx"))
        imported = import_services_from_excel(saved_path)
        self.assertEqual(len(imported), 1)
        self.assertEqual(imported[0]["paragraph"], "Общие работы")
        self.assertEqual(imported[0]["price"], "100.00")


if __name__ == "__main__":
    unittest.main()
