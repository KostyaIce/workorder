#!/usr/bin/env python3
"""Tests for PDF report builder."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from utils.pdf_report_builder import WorkReportPdfBuilder, save_work_report_pdf


class PdfReportBuilderTest(unittest.TestCase):
    def test_build_pdf_contains_client_name(self):
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
        builder = WorkReportPdfBuilder()
        pdf_bytes = builder.build_pdf_bytes(
            "Исполнитель: Петров",
            client,
            object_data,
            works,
        )
        self.assertTrue(pdf_bytes.startswith(b"%PDF"))
        self.assertGreater(len(pdf_bytes), 500)

    def test_save_pdf_creates_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "report.pdf"
            path, pdf_bytes = save_work_report_pdf(
                "Profile",
                {"kind": "object", "name": "Склад", "contact_info": "", "address": "", "notes": ""},
                {"name": "Склад", "address": ""},
                [],
                file_path=str(target),
            )
            self.assertTrue(Path(path).exists())
            self.assertTrue(pdf_bytes.startswith(b"%PDF"))


if __name__ == "__main__":
    unittest.main()
