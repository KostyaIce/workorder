#!/usr/bin/env python3
"""
Build PDF presentation for services catalog export.
"""

import io
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from utils.pdf_report_builder import register_report_font
from utils.service_units import is_percent_unit
from utils.services_excel_builder import _group_services_by_paragraph, resolve_excel_path


def resolve_pdf_path(file_url):
    """Resolve local PDF path from plain path or file:// URL."""
    path = resolve_excel_path(file_url)
    if not path:
        return ""

    if path.lower().endswith(".xlsx"):
        path = path[:-5]

    if not path.lower().endswith(".pdf"):
        path += ".pdf"
    return path


def _format_price_for_pdf(cents, unit):
    value = int(cents or 0)
    if is_percent_unit(unit):
        if value % 100 == 0:
            return str(value // 100)
        text = f"{value / 100:.2f}".rstrip("0").rstrip(".")
        return text

    return f"{value / 100:.2f} \u20bd"


class ServicesPdfBuilder:
    """Build grouped services catalog PDF presentation."""

    _TABLE_COL_WIDTHS = [105 * mm, 35 * mm, 34 * mm]

    def __init__(self, font_path=""):
        self._font_name = register_report_font(font_path)
        self._styles = self._build_styles()

    def _build_styles(self):
        styles = getSampleStyleSheet()
        base_kwargs = {"fontName": self._font_name}

        return {
            "title": ParagraphStyle(
                "ServicesPdfTitle",
                parent=styles["Heading1"],
                alignment=TA_CENTER,
                fontSize=14,
                leading=18,
                spaceAfter=8,
                **base_kwargs,
            ),
            "section": ParagraphStyle(
                "ServicesPdfSection",
                parent=styles["Heading2"],
                fontSize=11,
                leading=15,
                spaceBefore=6,
                spaceAfter=4,
                **base_kwargs,
            ),
            "table_cell": ParagraphStyle(
                "ServicesPdfTableCell",
                parent=styles["Normal"],
                alignment=TA_LEFT,
                fontSize=10,
                leading=13,
                **base_kwargs,
            ),
            "table_price": ParagraphStyle(
                "ServicesPdfTablePrice",
                parent=styles["Normal"],
                alignment=TA_RIGHT,
                fontSize=10,
                leading=13,
                **base_kwargs,
            ),
            "table_unit": ParagraphStyle(
                "ServicesPdfTableUnit",
                parent=styles["Normal"],
                alignment=TA_CENTER,
                fontSize=10,
                leading=13,
                **base_kwargs,
            ),
        }

    def _escape(self, value):
        text = str(value or "")
        return (
            text.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
        )

    def _service_description(self, name, note):
        name_text = self._escape(str(name or "").strip())
        note_text = self._escape(str(note or "").strip())
        if note_text:
            return f"{name_text}<br/>{note_text}"
        return name_text

    def _service_table_row(self, service):
        name = str(service.get("name") or "").strip()
        note = str(service.get("note") or "").strip()
        unit = str(service.get("unit") or "").strip()
        price_text = _format_price_for_pdf(service.get("price", 0), unit)

        return [
            Paragraph(self._service_description(name, note), self._styles["table_cell"]),
            Paragraph(self._escape(price_text), self._styles["table_price"]),
            Paragraph(self._escape(unit), self._styles["table_unit"]),
        ]

    def _table_style(self):
        return TableStyle([
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("TOPPADDING", (0, 0), (-1, -1), 4),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ("LEFTPADDING", (0, 0), (-1, -1), 4),
            ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ])

    def build_pdf_bytes(self, services, title="Презентация услуг"):
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            leftMargin=18 * mm,
            rightMargin=18 * mm,
            topMargin=16 * mm,
            bottomMargin=16 * mm,
            title=title,
        )

        story = [Paragraph(self._escape(title), self._styles["title"])]

        for paragraph, items in _group_services_by_paragraph(services):
            if paragraph:
                story.append(Paragraph(self._escape(paragraph), self._styles["section"]))

            if not items:
                continue

            data = [self._service_table_row(service) for service in items]
            table = Table(data, colWidths=self._TABLE_COL_WIDTHS)
            table.setStyle(self._table_style())
            story.append(table)
            story.append(Spacer(1, 4 * mm))

        doc.build(story)
        return buffer.getvalue()

    def save_pdf(self, file_path, services, title="Презентация услуг"):
        path = Path(file_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        pdf_bytes = self.build_pdf_bytes(services, title=title)
        path.write_bytes(pdf_bytes)
        return str(path.resolve())


def export_services_pdf(file_url, services=None, title="Презентация услуг"):
    """Write services catalog presentation PDF at the given path or URL."""
    path = resolve_pdf_path(file_url)
    if not path:
        raise ValueError("Services presentation path is empty")

    if services is None:
        from utils.services_db import load_services
        services = load_services()

    return ServicesPdfBuilder().save_pdf(path, services, title=title)
