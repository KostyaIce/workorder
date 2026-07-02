#!/usr/bin/env python3
"""Tests for coefficient handling in report backend."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from backend.report_backend import ReportBackend, ServiceItem


class ReportBackendCoefficientsTest(unittest.TestCase):
    def test_percent_points_from_price(self):
        self.assertEqual(ReportBackend._coefficient_percent_points(500), 5)
        self.assertEqual(ReportBackend._coefficient_percent_points(20000), 200)

    def test_service_item_defaults(self):
        item = ServiceItem(name="Work")
        self.assertEqual(item.coefficients, "")
        self.assertEqual(item.percent_sum, 100)

    def test_parse_coefficient_names(self):
        names = ReportBackend._parse_coefficient_names("A, B , ,C")
        self.assertEqual(names, ["A", "B", "C"])


if __name__ == "__main__":
    unittest.main()
