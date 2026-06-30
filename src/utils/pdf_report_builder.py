#!/usr/bin/env python3
"""
Build PDF reports for completed works using reportlab.
"""

import io
from collections import defaultdict
from datetime import datetime
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import HRFlowable, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from utils.db_storage import default_reports_dir
from utils.report_builder import _format_money


_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
_DEFAULT_FONT_DIR = _PROJECT_ROOT / "resources" / "fonts"
_DEFAULT_FONT_FILE = _DEFAULT_FONT_DIR / "DejaVuSans.ttf"
_REGISTERED_FONT_NAME = "WorkOrderReportFont"

_SYSTEM_FONT_CANDIDATES = (
    "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
    "/Library/Fonts/Arial Unicode.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/TTF/DejaVuSans.ttf",
    "C:/Windows/Fonts/arial.ttf",
)


def resolve_report_font_path(font_path=""):
    """Return path to TTF font that supports Cyrillic."""
    if font_path:
        path = Path(font_path).expanduser().resolve()
        if path.is_file():
            return path

    if _DEFAULT_FONT_FILE.is_file():
        return _DEFAULT_FONT_FILE

    for candidate in _SYSTEM_FONT_CANDIDATES:
        path = Path(candidate)
        if path.is_file():
            return path

    raise FileNotFoundError(
        "Report font not found. Place DejaVuSans.ttf in resources/fonts/ "
        "or install a system font with Cyrillic support."
    )


def register_report_font(font_path=""):
    """Register TTF font for reportlab and return registered name."""
    path = resolve_report_font_path(font_path)
    if _REGISTERED_FONT_NAME not in pdfmetrics.getRegisteredFontNames():
        pdfmetrics.registerFont(TTFont(_REGISTERED_FONT_NAME, str(path)))
    return _REGISTERED_FONT_NAME


class WorkReportPdfBuilder:
    """Build PDF work reports with the same content as plain-text reports."""

    _TABLE_COL_WIDTHS = [80 * mm, 20 * mm, 15 * mm, 30 * mm, 29 * mm]
    _META_COL_WIDTHS = [87 * mm, 87 * mm]

    def __init__(self, font_path=""):
        self._font_name = register_report_font(font_path)
        self._styles = self._build_styles()

    def _build_styles(self):
        styles = getSampleStyleSheet()
        base_kwargs = {"fontName": self._font_name}

        return {
            "title": ParagraphStyle(
                "ReportTitle",
                parent=styles["Heading1"],
                alignment=TA_CENTER,
                fontSize=14,
                leading=18,
                spaceAfter=6,
                **base_kwargs,
            ),
            "section": ParagraphStyle(
                "ReportSection",
                parent=styles["Heading2"],
                fontSize=11,
                leading=15,
                spaceBefore=8,
                spaceAfter=4,
                **base_kwargs,
            ),
            "normal": ParagraphStyle(
                "ReportNormal",
                parent=styles["Normal"],
                fontSize=10,
                leading=14,
                **base_kwargs,
            ),
            "table_header": ParagraphStyle(
                "ReportTableHeader",
                parent=styles["Normal"],
                alignment=TA_CENTER,
                fontSize=10,
                leading=12,
                spaceBefore=0,
                spaceAfter=0,
                **base_kwargs,
            ),
            "table_cell": ParagraphStyle(
                "ReportTableCell",
                parent=styles["Normal"],
                alignment=TA_LEFT,
                fontSize=10,
                leading=12,
                spaceBefore=0,
                spaceAfter=0,
                **base_kwargs,
            ),
            "table_total": ParagraphStyle(
                "ReportTableTotal",
                parent=styles["Normal"],
                alignment=TA_RIGHT,
                fontSize=11,
                leading=14,
                spaceBefore=0,
                spaceAfter=0,
                **base_kwargs,
            ),
        }

    def _table_style(self, include_total_row):
        commands = [
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("BACKGROUND", (0, 0), (-1, 0), colors.lightgrey),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("TOPPADDING", (0, 0), (-1, -1), 3),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ("ALIGN", (0, 0), (-1, 0), "CENTER"),
            ("ALIGN", (0, 1), (0, -2 if include_total_row else -1), "LEFT"),
            ("ALIGN", (1, 1), (-1, -2 if include_total_row else -1), "RIGHT"),
        ]
        if include_total_row:
            commands.extend([
                ("BACKGROUND", (0, -1), (-1, -1), colors.whitesmoke),
                ("ALIGN", (0, -1), (3, -1), "RIGHT"),
                ("SPAN", (0, -1), (3, -1)),
            ])
        return TableStyle(commands)

    def _work_table_header(self):
        return [
            Paragraph("Работа", self._styles["table_header"]),
            Paragraph("Кол-во", self._styles["table_header"]),
            Paragraph("Ед.", self._styles["table_header"]),
            Paragraph("Цена", self._styles["table_header"]),
            Paragraph("Сумма", self._styles["table_header"]),
        ]

    def _merge_works_by_name_price(self, works):
        """Merge rows with the same work name and price inside one table."""
        merged = {}
        order = []
        for work in works:
            name = work.get("name", "")
            price = int(work.get("price", 0))
            key = (name, price)
            if key not in merged:
                merged[key] = {
                    "name": name,
                    "price": price,
                    "quantity": float(work.get("quantity", 1)),
                    "unit": work.get("unit", ""),
                }
                order.append(key)
                continue
            merged[key]["quantity"] += float(work.get("quantity", 1))
        return [merged[key] for key in order]

    def _work_table_row(self, work):
        price = float(work.get("price", 0)) / 100.0
        quantity = float(work.get("quantity", 1))
        line_total = price * quantity
        unit = work.get("unit", "")
        return [
            Paragraph(self._escape(work.get("name", "")), self._styles["table_cell"]),
            Paragraph(self._escape(f"{quantity:g}"), self._styles["table_cell"]),
            Paragraph(self._escape(unit), self._styles["table_cell"]),
            Paragraph(self._escape(_format_money(price)), self._styles["table_cell"]),
            Paragraph(self._escape(_format_money(line_total)), self._styles["table_cell"]),
        ], line_total

    def _work_table_total_row(self, total):
        return [
            Paragraph("Итого:", self._styles["table_total"]),
            Paragraph("", self._styles["table_total"]),
            Paragraph("", self._styles["table_total"]),
            Paragraph("", self._styles["table_total"]),
            Paragraph(self._escape(_format_money(total)), self._styles["table_total"]),
        ]

    def _append_work_table(self, story, works, include_total_row=False):
        data = [self._work_table_header()]
        total = 0.0
        for work in self._merge_works_by_name_price(works):
            row, line_total = self._work_table_row(work)
            data.append(row)
            total += line_total

        if include_total_row:
            data.append(self._work_table_total_row(total))

        table = Table(data, colWidths=self._TABLE_COL_WIDTHS, repeatRows=1)
        table.setStyle(self._table_style(include_total_row))
        story.append(table)
        return total

    def _escape(self, value):
        text = str(value or "")
        return (
            text.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
        )

    def _paragraph(self, text, style_name="normal"):
        return Paragraph(self._escape(text), self._styles[style_name])

    def _append_header(self, story, options):
        if not options.get("include_report_header", True):
            return

        header_text = (options.get("report_header_text") or "").strip()
        if not header_text:
            header_text = "ОТЧЁТ О ПРОДЕЛАННЫХ РАБОТАХ"

        for line in header_text.splitlines() or [header_text]:
            story.append(self._paragraph(line, "title"))

        story.append(Spacer(1, 2 * mm))
        story.append(HRFlowable(width="100%", thickness=1, color=colors.black))
        story.append(Spacer(1, 4 * mm))

    def _meta_column_body(self, lines):
        if not lines:
            return self._paragraph("—")
        body = "<br/>".join(self._escape(line) for line in lines)
        return Paragraph(body, self._styles["normal"])

    def _meta_layout_style(self):
        return TableStyle([
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (-1, -1), 0),
            ("RIGHTPADDING", (0, 0), (0, -1), 8),
            ("TOPPADDING", (0, 0), (-1, -1), 0),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 0),
        ])

    def _append_meta(self, story, personal_info, client, object_data, options):
        story.append(Spacer(1, 6 * mm))
        
        if options.get("include_report_date", True):
            now = datetime.now().strftime("%d.%m.%Y %H:%M")
            story.append(self._paragraph(f"Дата формирования: {now}"))
            story.append(Spacer(1, 3 * mm))

        show_personal = options.get("include_personal_info", True)
        show_client = options.get("include_client_name", True)
        show_address = options.get("include_client_address", True)
        if not show_personal and not show_client and not show_address:
            return

        left_lines = []
        if show_personal:
            text = (personal_info or "").strip() or "—"
            left_lines = text.splitlines() or [text]

        right_lines = []
        if show_client:
            name = (client.get("name") or "").strip()
            if name:
                right_lines.append(name)
        if show_address:
            address = (object_data or {}).get("address") or client.get("address", "")
            if address:
                right_lines.append(f"Адрес: {address}")
            object_name = (object_data or {}).get("name", "")
            if object_name:
                right_lines.append(f"Объект: {object_name}")

        data = [
            [
                self._paragraph("Исполнитель:", "section"),
                self._paragraph("Заказчик:", "section"),
            ],
            [
                self._meta_column_body(left_lines),
                self._meta_column_body(right_lines),
            ],
        ]
        table = Table(data, colWidths=self._META_COL_WIDTHS)
        table.setStyle(self._meta_layout_style())
        story.append(table)
        story.append(Spacer(1, 4 * mm))

    def _append_works(self, story, works, options):
        story.append(Spacer(1, 2 * mm))

        if not works:
            story.append(self._paragraph("Нет записей о выполненных работах."))
            return

        total = 0.0
        if options.get("group_by_subobjects", True):
            groups = defaultdict(list)
            for work in works:
                key = (work.get("subobject_name") or "").strip()
                groups[key].append(work)

            for subobject_name in sorted(groups.keys(), key=str.casefold):
                group_works = groups[subobject_name]
                story.append(Spacer(1, 2 * mm))
                if subobject_name != '':
                    story.append(self._paragraph(f"{subobject_name}:", "section"))
                total += self._append_work_table(story, group_works)
        else:
            story.append(Spacer(1, 2 * mm))
            total = self._append_work_table(story, works, include_total_row=True)
            return

        story.append(Spacer(1, 2 * mm))
        total_table = Table(
            [self._work_table_total_row(total)],
            colWidths=self._TABLE_COL_WIDTHS,
        )
        total_table.setStyle(TableStyle([
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("BACKGROUND", (0, 0), (-1, -1), colors.whitesmoke),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("TOPPADDING", (0, 0), (-1, -1), 3),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ("ALIGN", (0, 0), (3, 0), "RIGHT"),
            ("SPAN", (0, 0), (3, 0)),
        ]))
        story.append(total_table)

    def build_story(self, personal_info, client, object_data, works, options=None):
        """Return reportlab flowables for the report body."""
        options = options or {}
        story = []

        self._append_header(story, options)
        self._append_works(story, works, options)
        self._append_meta(story, personal_info, client, object_data, options)

        story.append(Spacer(1, 6 * mm))
        # story.append(HRFlowable(width="100%", thickness=1, color=colors.black))
        return story

    def build_pdf_bytes(self, personal_info, client, object_data, works, options=None):
        """Build PDF document and return bytes."""
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            leftMargin=18 * mm,
            rightMargin=18 * mm,
            topMargin=18 * mm,
            bottomMargin=18 * mm,
            title="Work report",
        )
        doc.build(self.build_story(personal_info, client, object_data, works, options))
        return buffer.getvalue()

    def save_work_report(
        self,
        personal_info,
        client,
        object_data,
        works,
        options=None,
        file_path="",
    ):
        """Save PDF report to file and return path and bytes."""
        pdf_bytes = self.build_pdf_bytes(
            personal_info,
            client,
            object_data,
            works,
            options,
        )
        reports_dir = default_reports_dir()
        reports_dir.mkdir(parents=True, exist_ok=True)

        if file_path:
            target = Path(file_path).expanduser().resolve()
        else:
            safe_name = "".join(
                ch if ch.isalnum() else "_" for ch in client.get("name", "client")
            )
            stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            target = reports_dir / f"report_{safe_name}_{stamp}.pdf"

        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(pdf_bytes)
        return str(target), pdf_bytes


def save_work_report_pdf(
    personal_info,
    client,
    object_data,
    works,
    options=None,
    file_path="",
    font_path="",
):
    """Save PDF report using default builder."""
    builder = WorkReportPdfBuilder(font_path=font_path)
    return builder.save_work_report(
        personal_info,
        client,
        object_data,
        works,
        options,
        file_path=file_path,
    )
