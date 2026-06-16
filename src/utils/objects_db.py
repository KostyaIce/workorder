#!/usr/bin/env python3
"""
SQLite storage for objects catalog.
"""

import sqlite3
import uuid
from datetime import datetime

from utils.db_storage import object_db_path


def _connect(client_name, client_id):
    """Create connection to object database."""
    from pathlib import Path
    db_path = object_db_path(client_name, client_id).resolve()
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def create_object_database(client_name, client_id):
    path = object_db_path(client_name, client_id).resolve()
    with _connect(client_name, client_id) as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS objects (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                address TEXT NOT NULL DEFAULT '',
                updated_at INTEGER NOT NULL,
                last_order_at INTEGER NOT NULL DEFAULT 0
            )
        """)
        conn.commit()


def add_object_entry(client_name, client_id, name, address=""):
    result = False
    path = object_db_path(client_name, client_id).resolve()
    with _connect(client_name, client_id) as conn:
        current_time = int(datetime.now().timestamp())
        cursor = conn.execute("""
                  INSERT INTO objects(id, name, address, updated_at, last_order_at)
                  VALUES (?, ?, ?, ?, ?)
                   """,
            (str(uuid.uuid4()), name, address, current_time, 0))
        result = 0 < cursor.rowcount
        conn.commit()
    return result


def load_objects(client_name, client_id):
    """Load all customers and objects from database file."""
    path = object_db_path(client_name, client_id).resolve()
    if not path.exists():
        return []

    with _connect(client_name, client_id) as conn:
        rows = conn.execute(
            """SELECT id, name, address, updated_at, last_order_at
               FROM objects
               ORDER BY updated_at"""
        ).fetchall()

    return [
        {
            "id": row["id"],
            "name": row["name"],
            "address": row["address"],
            "updated_at": row["updated_at"],
            "last_order_at": row["last_order_at"]
        }
        for row in rows
    ]


def del_object_entry(client_name, client_id, data):
    if not data:
        return False
    object_id = data.get("id")
    path = object_db_path(client_name, client_id).resolve()
    with _connect(client_name, client_id) as conn:
        conn.execute(
            """
        DELETE FROM objects
        WHERE id = ?""",
            (object_id,),
        )
        conn.commit()
    return True


def update_object_name(client_name, client_id, data):
    if not data:
        return False
    object_id = data.get("id")
    name = data.get("name")
    address = data.get("address", "")
    path = object_db_path(client_name, client_id).resolve()
    with _connect(client_name, client_id) as conn:
        current_time = int(datetime.now().timestamp())
        cursor = conn.execute("""
                              UPDATE objects
                              SET updated_at = ?, name = ?, address = ?
                              WHERE id = ?
                              """, (current_time, name, address, object_id))

        conn.commit()
        return cursor.rowcount > 0


def update_object_last_order_at(client_name, client_id, object_id):
    """Update only last_order_at field for an object."""
    if not object_id:
        return False
    path = object_db_path(client_name, client_id).resolve()
    with _connect(client_name, client_id) as conn:
        current_time = int(datetime.now().timestamp())
        cursor = conn.execute("""
            UPDATE objects
            SET last_order_at = ?
            WHERE id = ?
        """, (current_time, object_id))
        conn.commit()
        return cursor.rowcount > 0
