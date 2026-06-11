#!/usr/bin/env python3
"""Basic backend smoke tests (no GUI)."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from backend.invoice_backend import InvoiceBackend
from backend.database_backend import DatabaseBackend
from backend.settings_backend import SettingsBackend


class InvoiceBackendTest(unittest.TestCase):
    def setUp(self):
        self.backend = InvoiceBackend()

    def test_select_service_and_total(self):
        self.backend.selectServiceById(1)
        self.backend.setQuantity(2)
        self.backend.addLineFromSelection()
        self.assertEqual(self.backend.currentServiceName, "Диагностика оборудования")
        self.assertEqual(self.backend.currentTotal, 1000.0)

    def test_create_invoice_requires_service(self):
        self.assertFalse(self.backend.createInvoice())
        self.backend.setCurrentClient(1, "Иванов И.И.", "customer")
        self.backend.selectServiceById(1)
        self.backend.setQuantity(2)
        self.assertTrue(self.backend.addLineFromSelection())
        self.assertEqual(self.backend.lineCount, 1)
        self.assertEqual(self.backend.currentTotal, 1000.0)
        self.assertEqual(self.backend.currentClientLabel, "Заказчик: Иванов И.И.")
        self.assertTrue(self.backend.createInvoice())
        self.assertEqual(self.backend.lineCount, 0)
        self.assertTrue(self.backend.hasCurrentClient)


class DatabaseBackendTest(unittest.TestCase):
    def setUp(self):
        self.backend = DatabaseBackend()

    def test_add_service(self):
        count_before = self.backend.serviceCount
        self.assertTrue(self.backend.addService("Тестовая услуга", 100.0))
        self.assertEqual(self.backend.serviceCount, count_before + 1)


class SettingsBackendTest(unittest.TestCase):
    def setUp(self):
        self.backend = SettingsBackend()

    def test_reset_settings(self):
        self.backend.setTheme("dark")
        self.backend.resetSettings()
        self.assertEqual(self.backend.theme, "light")


if __name__ == "__main__":
    unittest.main()
