#!/usr/bin/env python3
"""
Build and read Excel files for services catalog import/export.
"""

from decimal import Decimal, InvalidOperation
from pathlib import Path
from urllib.parse import unquote, urlparse

from openpyxl import Workbook, load_workbook


def resolve_excel_path(file_url, ensure_extension=False):
    """Resolve local path from plain path or file:// URL."""
    value = (file_url or "").strip()
    if not value:
        return ""

    if value.startswith("file:"):
        parsed = urlparse(value)
        path = unquote(parsed.path)
        if path.startswith("/") and len(path) > 2 and path[2] == ":":
            path = path[1:]
    else:
        path = value

    if ensure_extension and not path.lower().endswith(".xlsx"):
        path += ".xlsx"
    return path


def _cell_text(value):
    if value is None:
        return ""
    return str(value).strip()


def _normalize_price_text(value):
    if value is None or isinstance(value, bool):
        return None

    if isinstance(value, int):
        return str(value)

    if isinstance(value, float):
        if value.is_integer():
            return str(int(value))
        text = f"{value:.10f}".rstrip("0").rstrip(".")
        return text.replace(",", ".")

    text = str(value).strip().replace(",", ".")
    return text or None


def parse_excel_price(value):
    """
    Parse price from Excel cell.

    Empty value means paragraph row.
    Without decimal separator the value is multiplied by 100 (rubles to kopecks).
    With decimal separator rubles and kopecks are parsed from the text.
    """
    text = _normalize_price_text(value)
    if text is None:
        return None

    try:
        if "." not in text:
            return int(Decimal(text) * 100)

        whole, fraction = text.split(".", 1)
        whole = whole or "0"
        fraction = (fraction + "00")[:2]
        return int(whole) * 100 + int(fraction)
    except (InvalidOperation, ValueError):
        return None


def _price_for_db(cents):
    return f"{cents / 100:.2f}"


def _row_is_empty(cells):
    return all(_cell_text(cell) == "" for cell in cells[:4])


class ServicesExcelBuilder:
    """Read and write services catalog Excel files."""

    def read_services(self, file_path):
        """
        Read services from Excel.

        Row without price is a paragraph applied to following service rows.
        Service row columns: name, note, price, unit.
        """
        path = Path(file_path)
        if not path.is_file():
            raise FileNotFoundError(f"Services import file not found: {path}")

        services = []
        current_paragraph = ""

        workbook = load_workbook(path, read_only=True, data_only=True)
        try:
            sheet = workbook.active
            for row in sheet.iter_rows(values_only=True):
                cells = list(row)
                if len(cells) < 4:
                    cells.extend([None] * (4 - len(cells)))

                if _row_is_empty(cells):
                    continue

                name = _cell_text(cells[0])
                note = _cell_text(cells[1])
                price_cents = parse_excel_price(cells[2])
                unit = _cell_text(cells[3])

                if price_cents is None:
                    paragraph_text = name or note
                    if paragraph_text:
                        current_paragraph = paragraph_text
                    continue

                if not name:
                    continue

                services.append({
                    "name": name,
                    "note": note,
                    "paragraph": current_paragraph,
                    "price": _price_for_db(price_cents),
                    "unit": unit,
                })
        finally:
            workbook.close()

        return services

    def write_empty_export(self, file_path):
        """Create an empty Excel file for services export."""
        path = Path(file_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        workbook = Workbook()
        try:
            workbook.save(path)
        finally:
            workbook.close()
        return str(path.resolve())


def import_services_from_excel(file_url):
    """Read services list from Excel file referenced by path or URL."""
    path = resolve_excel_path(file_url)
    if not path:
        raise ValueError("Services import path is empty")
    return ServicesExcelBuilder().read_services(path)


def export_services_excel(file_url):
    """Create empty services Excel file at the given path or URL."""
    path = resolve_excel_path(file_url, ensure_extension=True)
    if not path:
        raise ValueError("Services export path is empty")
    return ServicesExcelBuilder().write_empty_export(path)
