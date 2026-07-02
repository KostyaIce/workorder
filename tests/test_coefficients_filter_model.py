#!/usr/bin/env python3
"""Tests for service and coefficient filter models."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from PyQt6.QtCore import QCoreApplication

from models.coefficients_filter_model import CoefficientsFilterModel
from models.services_filter_model import ServicesFilterModel
from models.services_model import ServiceModel
from utils.service_units import is_percent_unit

APP = QCoreApplication.instance() or QCoreApplication([])


class ServiceUnitsTest(unittest.TestCase):
    def test_is_percent_unit(self):
        self.assertTrue(is_percent_unit("%"))
        self.assertTrue(is_percent_unit("  % "))
        self.assertFalse(is_percent_unit("шт"))
        self.assertFalse(is_percent_unit(""))


class ServiceFilterModelsTest(unittest.TestCase):
    def setUp(self):
        self.services = ServiceModel()
        self.services.updateModel([
            {
                "id": "1",
                "name": "Монтаж",
                "note": "",
                "paragraph": "",
                "price": 10000,
                "unit": "м",
                "keywords": "монтаж",
                "created_at": "",
                "updated_at": "",
            },
            {
                "id": "2",
                "name": "Сложность",
                "note": "",
                "paragraph": "",
                "price": 1500,
                "unit": "%",
                "keywords": "сложность",
                "created_at": "",
                "updated_at": "",
            },
        ])
        self.services_filter = ServicesFilterModel()
        self.services_filter.setSourceModel(self.services)
        self.coefficients_filter = CoefficientsFilterModel()
        self.coefficients_filter.setSourceModel(self.services)

    def test_service_filter_excludes_percent_units(self):
        self.services_filter.setFilterText("Слож")
        self.assertEqual(self.services_filter.rowCount(), 0)

        self.services_filter.setFilterText("Монт")
        self.assertEqual(self.services_filter.rowCount(), 1)

    def test_coefficients_filter_includes_only_percent_units(self):
        self.coefficients_filter.setFilterText("Слож")
        self.assertEqual(self.coefficients_filter.rowCount(), 1)

        self.coefficients_filter.setFilterText("Монт")
        self.assertEqual(self.coefficients_filter.rowCount(), 0)


if __name__ == "__main__":
    unittest.main()
