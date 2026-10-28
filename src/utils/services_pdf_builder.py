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
from reportlab.platypus import Flowable, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

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


class _SectionTable(Flowable):
    """Keep a section label and the column header with the first service row."""

    def __init__(self, heading, table):
        super().__init__()
        self.heading = heading
        self.table = table
        self._gap = 6 if heading is not None else 0

    def wrap(self, availWidth, availHeight):
        height = 0
        if self.heading is not None:
            _, heading_height = self.heading.wrap(availWidth, availHeight)
            height += heading_height + self._gap
        _, table_height = self.table.wrap(availWidth, max(availHeight - height, 0))
        height += table_height
        self.width = availWidth
        self.height = height
        return availWidth, height

    def split(self, availWidth, availHeight):
        self.wrap(availWidth, availHeight)
        rows = getattr(self.table, "_rowHeights", None) or []
        heading_height = 0 if self.heading is None else self.heading.height + self._gap
        if len(rows) >= 2:
            needed = heading_height + rows[0] + rows[1]
            # A short remainder moves the heading and header onto the next page.
            # A fresh page that still cannot hold them has to split normally.
            if needed > availHeight and availHeight <= 180 * mm:
                return []

        parts = []
        if self.heading is not None:
            parts.append(self.heading)
        parts.append(self.table)
        return parts

    def draw(self):
        if self.heading is not None:
            self.heading.drawOn(self.canv, 0, self.table._height + self._gap)
        self.table.drawOn(self.canv, 0, 0)


class ServicesPdfBuilder:
    """Build grouped services catalog PDF presentation."""

    _TABLE_COL_WIDTHS = [126 * mm, 29 * mm, 19 * mm]

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
                fontSize=16,
                leading=20,
                spaceAfter=16,
                **base_kwargs,
            ),
            "section": ParagraphStyle(
                "ServicesPdfSection",
                parent=styles["Heading2"],
                fontSize=10,
                leading=13,
                spaceBefore=2,
                spaceAfter=6,
                **base_kwargs,
            ),
            "table_header": ParagraphStyle(
                "ServicesPdfTableHeader",
                parent=styles["Normal"],
                alignment=TA_CENTER,
                fontSize=10,
                leading=13,
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

    def _service_table_header(self):
        header = self._styles["table_header"]
        return [
            Paragraph("Услуга", header),
            Paragraph("Стоимость", header),
            Paragraph("Ед.", header),
        ]

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
            ("GRID", (0, 0), (-1, -1), 0.4, colors.Color(0.72, 0.75, 0.80)),
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
        groups = list(_group_services_by_paragraph(services))
        untitled = []
        wrote_table = False

        def append_table(heading, items):
            nonlocal wrote_table
            if wrote_table:
                story.append(Spacer(1, 10 * mm))
            rows = [self._service_table_header()]
            rows.extend(self._service_table_row(service) for service in items)
            table = Table(rows, colWidths=self._TABLE_COL_WIDTHS)
            table.setStyle(self._table_style())
            story.append(_SectionTable(heading, table))
            wrote_table = True

        for paragraph, items in groups:
            if not items:
                continue
            if not paragraph:
                untitled.extend(items)
                continue
            heading = Paragraph(self._escape(paragraph), self._styles["section"])
            append_table(heading, items)

        if untitled:
            append_table(None, untitled)

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
