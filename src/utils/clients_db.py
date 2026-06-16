#!/usr/bin/env python3
"""
SQLite storage for clients catalog.
"""

import sqlite3
import uuid
from datetime import datetime
from pathlib import Path

from utils.db_storage import default_clients_db_path


def _connect(db_path=None):
    """Create connection to clients database."""
    if db_path is None:
        db_path = default_clients_db_path()
    db_path = Path(db_path)
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def create_client_table(db_path=None):
    """Create clients table if not exists."""
    with _connect(db_path) as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS clients (
                id TEXT PRIMARY KEY,
                kind TEXT NOT NULL,
                name TEXT NOT NULL,
                address TEXT,
                contact TEXT,
                notes TEXT,
                created_at TEXT,
                UNIQUE (name, address, contact)
            )
        """)
        conn.commit()


def add_client_entry(data, db_path=None):
    """Add new client entry."""
    if not data:
        return False
    
    path = default_clients_db_path() if db_path is None else Path(db_path)
    result = False
    with _connect(db_path) as conn:
        row = [
            str(uuid.uuid4()),
            data["kind"],
            data["name"],
            data.get("address", ""),
            data.get("contact", ""),
            data.get("notes", ""),
            datetime.now().isoformat(),
        ]
        cursor = conn.execute(
            """
            INSERT INTO clients(id, kind, name, address, contact, notes, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            row,
        )
        result = 0 < cursor.rowcount
        conn.commit()
    return result


def load_clients(db_path=None):
    """Load all customers and objects from database file."""
    path = default_clients_db_path() if db_path is None else Path(db_path)
    if not path.exists():
        return []

    with _connect(db_path) as conn:
        rows = conn.execute(
            """SELECT id, kind, name, contact, address, notes, created_at
               FROM clients
               ORDER BY id"""
        ).fetchall()

    return [
        {
            "id": row["id"],
            "kind": row["kind"],
            "name": row["name"],
            "contact_info": row["contact"],
            "address": row["address"],
            "notes": row["notes"],
            "created_at": row["created_at"],
        }
        for row in rows
    ]


def del_client_entry(data, db_path=None):
    """Delete client by id."""
    if not data:
        return False
    client_id = data.get("id")
    if not client_id:
        return False
    
    path = default_clients_db_path() if db_path is None else Path(db_path)
    with _connect(db_path) as conn:
        conn.execute(
            "DELETE FROM clients WHERE id = ?",
            (client_id,),
        )
        conn.commit()
    return True
