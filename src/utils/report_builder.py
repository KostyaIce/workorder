#!/usr/bin/env python3
"""
Build text reports for completed works.
"""

from collections import defaultdict
from datetime import datetime
from pathlib import Path

from utils.db_storage import default_reports_dir


def _format_money(value):
    return f"{float(value):.2f}"


def _work_line(work):
    price = float(work.get("price", 0)) / 100.0
    quantity = float(work.get("quantity", 1))
    total = price * quantity
    unit = work.get("unit", "")
    unit_suffix = f" {unit}" if unit else ""
    return (
        f"- {work.get('name', '')}: {quantity:g}{unit_suffix} x "
        f"{_format_money(price)} = {_format_money(total)}"
    ), total


def _append_work_lines(lines, works):
    total = 0.0
    for work in works:
        line, line_total = _work_line(work)
        lines.append(line)
        total += line_total
    return total


def build_work_report(personal_info, client, object_data, works, options=None):
    """
    Build plain-text report body.

    Args:
        personal_info: Executor profile text from settings
        client: Client dict
        object_data: Object dict with name and address
        works: List of work dicts
        options: Report layout options dict
    """
    options = options or {}
    lines = []

    if options.get("include_report_header", True):
        header_text = (options.get("report_header_text") or "").strip()
        if not header_text:
            header_text = "ОТЧЁТ О ПРОДЕЛАННЫХ РАБОТАХ"

        header_lines = header_text.splitlines() or [header_text]
        lines.extend(header_lines)
        separator_len = max(len(line) for line in header_lines)
        lines.append("=" * min(separator_len, 40))
        lines.append("")

    if options.get("include_report_date", True):
        now = datetime.now().strftime("%d.%m.%Y %H:%M")
        lines.append(f"Дата формирования: {now}")
        lines.append("")

    if options.get("include_personal_info", True):
        lines.append("Исполнитель:")
        lines.append((personal_info or "").strip() or "—")
        lines.append("")

    if options.get("include_client_name", True):
        lines.append(f"Заказчик: {client.get('name', '')}")

    if options.get("include_client_address", True):
        address = (object_data or {}).get("address") or client.get("address", "")
        if address:
            lines.append(f"Адрес: {address}")
        object_name = (object_data or {}).get("name", "")
        if object_name:
            lines.append(f"Объект: {object_name}")

    if options.get("include_client_name", True) or options.get("include_client_address", True):
        lines.append("")

    lines.extend(["Перечень работ:", "-" * 40])

    if not works:
        lines.append("Нет записей о выполненных работах.")
    else:
        total = 0.0
        if options.get("group_by_subobjects", True):
            groups = defaultdict(list)
            for work in works:
                key = (work.get("subobject_name") or "").strip() or "Без субобъекта"
                groups[key].append(work)

            for subobject_name in sorted(groups.keys(), key=str.casefold):
                group_works = groups[subobject_name]
                lines.append("")
                lines.append(subobject_name + ":")
                total += _append_work_lines(lines, group_works)
        else:
            lines.append("")
            for index, work in enumerate(works, start=1):
                line, line_total = _work_line(work)
                lines.append(f"{index}. {line[2:]}")
                total += line_total

        lines.extend(["", f"Итого: {_format_money(total)}"])

    lines.append("")
    lines.append("=" * 40)
    return "\n".join(lines)


def save_work_report(personal_info, client, object_data, works, options=None, file_path=""):
    """Save report text to file and return path and content."""
    content = build_work_report(personal_info, client, object_data, works, options)
    reports_dir = default_reports_dir()
    reports_dir.mkdir(parents=True, exist_ok=True)

    if file_path:
        target = Path(file_path).expanduser().resolve()
    else:
        safe_name = "".join(
            ch if ch.isalnum() else "_" for ch in client.get("name", "client")
        )
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        target = reports_dir / f"report_{safe_name}_{stamp}.txt"

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
    return str(target), content
