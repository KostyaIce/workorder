#!/usr/bin/env python3
"""
SQLite storage for services catalog.
Услуги с уникальным названием (name).
"""

import logging
import sqlite3
import uuid
from datetime import datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path

from utils.db_storage import project_data_dir

logger = logging.getLogger("workorder")

_SERVICES_COLUMNS = frozenset({
    "id", "name", "note", "paragraph", "price", "unit", "keywords", "created_at", "updated_at",
})

_CREATE_SERVICES_SQL = """
    CREATE TABLE IF NOT EXISTS services (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        note TEXT,
        paragraph TEXT,
        price INTEGER NOT NULL,
        unit TEXT,
        keywords TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
    )
"""


def default_services_db_path():
    return project_data_dir() / "services.db"


def _connect():
    """Create connection to database."""
    db_path = default_services_db_path()
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def _keywords_from_name(name):
    """Generate keywords from service name."""
    words = [word.lower() for word in name.split() if len(word) > 2]
    return ", ".join(words) if words else name.lower()


def _table_columns(conn):
    return {row[1] for row in conn.execute("PRAGMA table_info(services)").fetchall()}


def _parse_price_cents(value) -> int:
    text = str(value or "0").strip().replace(",", ".")
    if not text:
        return 0
    try:
        return int(Decimal(text) * 100)
    except (InvalidOperation, ValueError):
        return 0


def create_services_table():
    """Create services table if not exists."""
    with _connect() as conn:
        columns = _table_columns(conn)
        if columns and columns != _SERVICES_COLUMNS:
            logger.warning("services table schema mismatch, recreating table")
            conn.execute("DROP TABLE services")

        conn.execute(_CREATE_SERVICES_SQL)
        conn.commit()


def add_service(data):
    """Add new service. Returns True if success, False if name already exists."""
    if not data:
        return False

    name = str(data.get("name", "")).strip()
    if not name:
        return False

    service_id = str(uuid.uuid4())
    price = _parse_price_cents(data.get("price", "0"))
    note = str(data.get("note", "")).strip()
    paragraph = str(data.get("paragraph", "")).strip()
    unit = str(data.get("unit", "")).strip()
    keywords = str(data.get("keywords", "")).strip()
    if not keywords:
        keywords = _keywords_from_name(name)

    now = datetime.now().isoformat()

    try:
        create_services_table()
        with _connect() as conn:
            conn.execute(
                """
                INSERT INTO services (
                    id, name, note, paragraph, price, unit, keywords, created_at, updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (service_id, name, note, paragraph, price, unit, keywords, now, now),
            )
            conn.commit()
        return True
    except sqlite3.IntegrityError:
        logger.warning("Service already exists: %s", name)
        return False


def delete_service(service_id):
    """Delete service by id."""
    if not service_id:
        return False

    with _connect() as conn:
        cursor = conn.execute(
            "DELETE FROM services WHERE id = ?",
            (service_id,),
        )
        conn.commit()
        return cursor.rowcount > 0


def update_service(data):
    """Update service fields."""
    if not data:
        return False

    name = str(data.get("name", "")).strip()
    if not name:
        return False

    service_id = str(data.get("id", "")).strip()
    if not service_id:
        return False

    price = _parse_price_cents(data.get("price", "0"))
    note = str(data.get("note", "")).strip()
    paragraph = str(data.get("paragraph", "")).strip()
    unit = str(data.get("unit", "")).strip()
    keywords = str(data.get("keywords", "")).strip()
    if not keywords:
        keywords = _keywords_from_name(name)

    now = datetime.now().isoformat()

    try:
        with _connect() as conn:
            cursor = conn.execute(
                """
                UPDATE services
                SET name = ?, note = ?, paragraph = ?, price = ?, unit = ?, keywords = ?, updated_at = ?
                WHERE id = ?
                """,
                (name, note, paragraph, price, unit, keywords, now, service_id),
            )
            conn.commit()
            return cursor.rowcount > 0
    except sqlite3.IntegrityError:
        logger.warning("Service name already exists: %s", name)
        return False


def load_services():
    """Load all services ordered by name."""
    create_services_table()

    with _connect() as conn:
        rows = conn.execute(
            """SELECT id, name, note, paragraph, price, unit, keywords, created_at, updated_at
               FROM services
               ORDER BY name"""
        ).fetchall()

    return [
        {
            "id": row["id"],
            "name": row["name"],
            "note": row["note"],
            "paragraph": row["paragraph"],
            "price": row["price"],
            "unit": row["unit"],
            "keywords": row["keywords"],
            "created_at": row["created_at"],
            "updated_at": row["updated_at"],
        }
        for row in rows
    ]


def get_service_by_id(service_id):
    """Get single service by id."""
    with _connect() as conn:
        row = conn.execute(
            """SELECT id, name, note, paragraph, price, unit, keywords, created_at, updated_at
               FROM services
               WHERE id = ?""",
            (service_id,),
        ).fetchone()

    if row:
        return {
            "id": row["id"],
            "name": row["name"],
            "note": row["note"],
            "paragraph": row["paragraph"],
            "price": row["price"],
            "unit": row["unit"],
            "keywords": row["keywords"],
            "created_at": row["created_at"],
            "updated_at": row["updated_at"],
        }
    return None


def search_services(query):
    """Search services by name or keywords (case-insensitive)."""
    if not query:
        return load_services()

    query = f"%{query.strip()}%"

    with _connect() as conn:
        rows = conn.execute(
            """SELECT id, name, note, paragraph, price, unit, keywords, created_at, updated_at
               FROM services
               WHERE name LIKE ? OR keywords LIKE ?
               ORDER BY name""",
            (query, query),
        ).fetchall()

    return [
        {
            "id": row["id"],
            "name": row["name"],
            "note": row["note"],
            "paragraph": row["paragraph"],
            "price": row["price"],
            "unit": row["unit"],
            "keywords": row["keywords"],
            "created_at": row["created_at"],
            "updated_at": row["updated_at"],
        }
        for row in rows
    ]


def merge_from_database(source_db_path):
    """Insert services from source that are missing locally (by id)."""
    source = Path(source_db_path)
    if not source.exists():
        return 0

    create_services_table()
    inserted = 0
    with sqlite3.connect(source) as src, _connect() as dst:
        src.row_factory = sqlite3.Row
        rows = src.execute(
            """SELECT id, name, note, paragraph, price, unit, keywords, created_at, updated_at
               FROM services"""
        ).fetchall()
        for row in rows:
            cursor = dst.execute(
                """
                INSERT OR IGNORE INTO services (
                    id, name, note, paragraph, price, unit, keywords, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    row["id"],
                    row["name"],
                    row["note"],
                    row["paragraph"],
                    row["price"],
                    row["unit"],
                    row["keywords"],
                    row["created_at"],
                    row["updated_at"],
                ),
            )
            if cursor.rowcount and cursor.rowcount > 0:
                inserted += 1
        dst.commit()
    return inserted
