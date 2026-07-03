#!/usr/bin/env python3
"""
SQLite storage helpers for works and application settings.
"""

import sqlite3
from pathlib import Path


def project_data_dir():
    """Return default data directory under project root."""
    return Path(__file__).resolve().parent.parent.parent / "data"


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
        "coefficients": data.get("coefficients", ""),
        "percent_sum": data.get("percent_sum", 100),
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
    for field in (
        "object_id", "service_id", "subobject_name", "name", "price", "unit", "quantity",
        "start_order_at", "coefficients", "percent_sum",
    ):
        if field in data:
            payload[field] = data[field]
    if "service" in data and "name" not in payload:
        payload["name"] = data["service"]

    return update_work(client_name, client_id, payload)


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
