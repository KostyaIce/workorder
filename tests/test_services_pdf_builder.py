#!/usr/bin/env python3
"""Tests for services PDF presentation builder."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from utils.services_pdf_builder import (
    ServicesPdfBuilder,
    _format_price_for_pdf,
    export_services_pdf,
    resolve_pdf_path,
)


class ServicesPdfBuilderTest(unittest.TestCase):
    def test_resolve_pdf_path(self):
        self.assertTrue(resolve_pdf_path("/tmp/catalog").endswith(".pdf"))
        self.assertTrue(resolve_pdf_path("/tmp/catalog.xlsx").endswith(".pdf"))

    def test_format_price_for_pdf(self):
        self.assertEqual(_format_price_for_pdf(50000, "шт"), "500.00 \u20bd")
        self.assertEqual(_format_price_for_pdf(550, "%"), "5.5")

    def test_build_pdf_bytes(self):
        services = [
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
        ]

        pdf_bytes = ServicesPdfBuilder().build_pdf_bytes(services)
        self.assertTrue(pdf_bytes.startswith(b"%PDF"))
        self.assertGreater(len(pdf_bytes), 500)

    def test_export_services_pdf(self):
        services = [
            {
                "name": "Монтаж",
                "note": "Базовый",
                "paragraph": "Общие работы",
                "price": 10000,
                "unit": "м",
            },
        ]

        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "presentation"
            saved_path = export_services_pdf(str(target), services)
            self.assertTrue(saved_path.endswith(".pdf"))
            self.assertTrue(Path(saved_path).exists())
            self.assertTrue(Path(saved_path).read_bytes().startswith(b"%PDF"))


if __name__ == "__main__":
    unittest.main()
