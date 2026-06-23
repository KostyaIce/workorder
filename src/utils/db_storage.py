#!/usr/bin/env python3
"""
SQLite storage helpers for services and completed works.
"""

import sqlite3
from datetime import datetime
from pathlib import Path

SERVICES_SCHEMA = """
CREATE TABLE IF NOT EXISTS services (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    price REAL NOT NULL CHECK(price >= 0)
);
"""



CLIENTS_SCHEMA = """
CREATE TABLE IF NOT EXISTS clients (
    id INTEGER PRIMARY KEY,
    kind TEXT NOT NULL CHECK(kind IN ('customer', 'object')),
    name TEXT NOT NULL,
    contact_info TEXT NOT NULL DEFAULT '',
    address TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL
);
"""

SAMPLE_SERVICES = [
    (1, "Диагностика оборудования", 500.0),
    (2, "Ремонт компьютера", 1500.0),
    (3, "Ремонт ноутбука", 2000.0),
    (4, "Замена экрана", 3500.0),
    (5, "Замена батареи", 1200.0),
    (6, "Установка Windows", 2500.0),
    (7, "Установка программ", 800.0),
    (8, "Чистка от пыли", 1000.0),
    (9, "Замена термопасты", 600.0),
    (10, "Восстановление данных", 3000.0),
    (11, "Настройка сети", 1200.0),
    (12, "Консультация", 500.0),
    (13, "Ремонт материнской платы", 4500.0),
    (14, "Замена клавиатуры", 1800.0),
    (15, "Ремонт блока питания", 2200.0),
]



SAMPLE_CLIENTS = [
    (1, "customer", "Иванов И.И.", "+7 900 123-45-67", "г. Москва", ""),
    (2, "customer", "Петрова А.С.", "+7 901 222-33-44", "г. Санкт-Петербург", ""),
    (3, "customer", "Сидоров К.В.", "", "", "Частный клиент"),
    (4, "customer", "Козлова М.П.", "+7 903 555-66-77", "", ""),
    (
        5,
        "object",
        "ООО ТехноСервис",
        "info@technoserv.ru",
        "ул. Ленина, 10",
        "Серверная",
    ),
    (6, "customer", "Белова Е.Н.", "", "г. Казань", ""),
    (7, "object", "Склад Федоров", "", "пр. Мира, 25", "Производственный цех"),
]


def project_data_dir():
    """Return default data directory under project root."""
    return Path(__file__).resolve().parent.parent.parent / "data"


def default_services_db_path():
    return project_data_dir() / "services.db"


def default_clients_db_path():
    return project_data_dir() / "clients.db"

def object_db_path(client_name, client_id):
    name = client_name + "_" + client_id + ".db"
    return project_data_dir() / name

def default_settings_path():
    return project_data_dir() / "app_settings.json"


def default_reports_dir():
    return project_data_dir() / "reports"


def resolve_db_path(file_path, default_path):
    if file_path:
        return Path(file_path).expanduser().resolve()
    return default_path.resolve()


def _connect(db_path):
    db_path = Path(db_path)
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def create_services_database(file_path=""):
    """
    Create SQLite database with services catalog and sample rows.

    Returns:
        tuple: (resolved_path: str, inserted_count: int)
    """
    db_path = resolve_db_path(file_path, default_services_db_path())
    with _connect(db_path) as conn:
        conn.execute("DROP TABLE IF EXISTS services")
        conn.executescript(SERVICES_SCHEMA)
        conn.executemany(
            "INSERT INTO services (id, name, price) VALUES (?, ?, ?)",
            SAMPLE_SERVICES,
        )
        conn.commit()
    return str(db_path), len(SAMPLE_SERVICES)


def create_works_database(client_name, client_id):
    from utils.works_db import create_works_table

    path = object_db_path(client_name, client_id).resolve()
    create_works_table(client_name, client_id)
    return str(path), 0


def add_work_entry(client_name, client_id, data):
    """Add a new work entry."""
    from utils.works_db import add_work

    if not data:
        return False

    payload = {
        "object_id": data.get("object_id", ""),
        "service_id": data.get("service_id", ""),
        "subobject_name": data.get("subobject_name", ""),
        "name": data.get("name", data.get("service", "")),
        "price": data.get("price", 0),
        "unit": data.get("unit", ""),
        "quantity": data.get("quantity", 1),
    }
    return add_work(client_name, client_id, payload)


def load_works(client_name, client_id):
    """Load all works from database file."""
    from utils.works_db import load_works as load_works_from_db

    return load_works_from_db(client_name, client_id)


def del_work_entry(client_name, client_id, data):
    """Delete a work entry by id."""
    from utils.works_db import delete_work

    if not data:
        return False
    work_id = data.get("id")
    if not work_id:
        return False
    return delete_work(client_name, client_id, work_id)


def update_work_entry(client_name, client_id, data):
    """Update editable fields of a work entry."""
    from utils.works_db import update_work

    if not data:
        return False

    work_id = data.get("id")
    if not work_id:
        return False

    payload = {"id": work_id}
    for field in ("object_id", "service_id", "subobject_name", "name", "price", "unit", "quantity", "start_order_at"):
        if field in data:
            payload[field] = data[field]
    if "service" in data and "name" not in payload:
        payload["name"] = data["service"]

    return update_work(client_name, client_id, payload)


def load_services(db_path):
    """Load all services from database file."""
    path = resolve_db_path(db_path, default_services_db_path())
    if not path.exists():
        return []

    with _connect(path) as conn:
        rows = conn.execute(
            "SELECT id, name, price FROM services ORDER BY id"
        ).fetchall()

    return [
        {"id": row["id"], "name": row["name"], "price": row["price"]} for row in rows
    ]


def get_services_statistics(db_path=""):
    """Return aggregate stats for services database."""
    services = load_services(db_path)
    if not services:
        return {
            "count": 0,
            "min_price": 0,
            "max_price": 0,
            "avg_price": 0,
            "total_value": 0,
        }

    prices = [item["price"] for item in services]
    return {
        "count": len(services),
        "min_price": min(prices),
        "max_price": max(prices),
        "avg_price": sum(prices) / len(prices),
        "total_value": sum(prices),
    }


def save_services(db_path, services):
    """Persist services list to SQLite file."""
    path = resolve_db_path(db_path, default_services_db_path())
    with _connect(path) as conn:
        conn.execute("DROP TABLE IF EXISTS services")
        conn.executescript(SERVICES_SCHEMA)
        if services:
            rows = [
                (item["id"], item["name"].strip(), float(item["price"]))
                for item in services
            ]
            conn.executemany(
                "INSERT INTO services (id, name, price) VALUES (?, ?, ?)",
                rows,
            )
        conn.commit()
    return str(path)


def _normalize_service_row(row):
    service_id = int(row["id"])
    name = (row["name"] or "").strip()
    price = max(float(row["price"]), 0.0)
    return service_id, name, price


def repair_services_database(file_path=""):
    """
    Check and repair services database structure and rows.

    Returns:
        tuple: (report: dict, resolved_path: str)
    """
    db_path = resolve_db_path(file_path, default_services_db_path())
    report = {
        "database": "services",
        "path": str(db_path),
        "fixed": [],
        "removed": 0,
        "kept": 0,
        "integrity_ok": True,
    }

    if not db_path.exists():
        path, count = create_services_database(str(db_path))
        report["fixed"].append("created_missing_database")
        report["kept"] = count
        return report, path

    try:
        with _connect(db_path) as conn:
            integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
            if integrity != "ok":
                report["integrity_ok"] = False
                report["fixed"].append(f"integrity_check:{integrity}")

            conn.executescript(SERVICES_SCHEMA)
            rows = conn.execute(
                "SELECT id, name, price FROM services ORDER BY id"
            ).fetchall()
    except sqlite3.DatabaseError as exc:
        path, count = create_services_database(str(db_path))
        report["fixed"].append(f"recreated_corrupted_database:{exc}")
        report["kept"] = count
        return report, path

    cleaned = []
    seen_names = set()
    next_id = 1
    for row in rows:
        service_id, name, price = _normalize_service_row(row)
        if not name:
            report["removed"] += 1
            report["fixed"].append(f"removed_empty_name:id={service_id}")
            continue

        name_key = name.lower()
        if name_key in seen_names:
            report["removed"] += 1
            report["fixed"].append(f"removed_duplicate_name:{name}")
            continue

        if service_id <= 0 or service_id != next_id:
            report["fixed"].append(f"reassigned_id:{service_id}->{next_id}")

        if float(row["price"]) < 0:
            report["fixed"].append(f"fixed_negative_price:id={service_id}")

        if name != (row["name"] or "").strip():
            report["fixed"].append(f"trimmed_name:id={next_id}")

        cleaned.append({"id": next_id, "name": name, "price": price})
        seen_names.add(name_key)
        next_id += 1

    save_services(db_path, cleaned)
    report["kept"] = len(cleaned)
    if not report["fixed"]:
        report["fixed"].append("no_changes_required")
    return report, str(db_path)


def load_app_settings(file_path=""):
    """Load application settings from JSON file."""
    import json

    path = resolve_db_path(file_path, default_settings_path())
    if not path.exists():
        return {}

    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def save_app_settings(settings, file_path=""):
    """Save application settings to JSON file."""
    import json

    path = resolve_db_path(file_path, default_settings_path())
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(settings, handle, ensure_ascii=False, indent=2)
    return str(path)



