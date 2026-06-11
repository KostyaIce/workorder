#!/usr/bin/env python3
"""
Build text reports for completed works.
"""

from datetime import datetime
from pathlib import Path

from utils.db_storage import default_reports_dir


def _kind_label(kind):
    if kind == "object":
        return "Объект"
    return "Заказчик"


def build_work_report(personal_info, client, works):
    """
    Build plain-text report body.

    Args:
        personal_info: Executor profile text from settings
        client: Client dict
        works: List of work dicts for the client
    """
    now = datetime.now().strftime("%d.%m.%Y %H:%M")
    lines = [
        "ОТЧЁТ О ПРОДЕЛАННЫХ РАБОТАХ",
        "=" * 40,
        "",
        f"Дата формирования: {now}",
        "",
        "Исполнитель:",
        personal_info.strip() or "—",
        "",
        f"{_kind_label(client.get('kind', 'customer'))}: {client.get('name', '')}",
    ]

    if client.get("contact_info"):
        lines.append(f"Контакт: {client['contact_info']}")
    if client.get("address"):
        lines.append(f"Адрес: {client['address']}")
    if client.get("notes"):
        lines.append(f"Примечание: {client['notes']}")

    lines.extend(["", "Перечень работ:", "-" * 40])

    if not works:
        lines.append("Нет записей о выполненных работах.")
    else:
        total = 0.0
        for index, work in enumerate(works, start=1):
            status = work.get("status", "completed")
            status_label = "Выполнено" if status == "completed" else "В процессе"
            lines.append(
                f"{index}. {work.get('service_name', '')} "
                f"({work.get('quantity', 1)} x {work.get('unit_price', 0):.2f} = "
                f"{work.get('total_price', 0):.2f})"
            )
            lines.append(
                f"   Номер: {work.get('work_number', '')}, "
                f"Дата: {work.get('completed_at', '')}, Статус: {status_label}"
            )
            if work.get("notes"):
                lines.append(f"   Комментарий: {work['notes']}")
            if status == "completed":
                total += float(work.get("total_price", 0))
        lines.extend(["", f"Итого по выполненным работам: {total:.2f}"])

    lines.append("")
    lines.append("=" * 40)
    return "\n".join(lines)


def save_work_report(personal_info, client, works, file_path=""):
    """Save report text to file and return path and content."""
    content = build_work_report(personal_info, client, works)
    reports_dir = default_reports_dir()
    reports_dir.mkdir(parents=True, exist_ok=True)

    if file_path:
        target = Path(file_path).expanduser().resolve()
    else:
        safe_name = "".join(ch if ch.isalnum() else "_" for ch in client.get("name", "client"))
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        target = reports_dir / f"report_{safe_name}_{stamp}.txt"

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
    return str(target), content
