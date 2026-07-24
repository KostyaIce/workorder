#!/usr/bin/env python3
"""
SQLite storage for completed works.
"""

import logging
import sqlite3
import uuid
from datetime import datetime

from utils.db_storage import object_db_path

logger = logging.getLogger("workorder")

_WORKS_COLUMNS = frozenset({
    "id", "object_id", "service_id", "subobject_name", "name", "price", "unit", "quantity",
    "created_at", "updated_at", "start_order_at", "coefficients", "percent_sum",
})

_WORKS_SELECT_COLUMNS = """
    id, object_id, service_id, subobject_name, name, price, unit, quantity,
    created_at, updated_at, start_order_at, coefficients, percent_sum
"""


def _connect(client_name, client_id):
    """Create connection to works database."""
    db_path = object_db_path(client_name, client_id).resolve()
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def _table_columns(conn):
    return {row[1] for row in conn.execute("PRAGMA table_info(completed_works)").fetchall()}


def _parse_quantity(value):
    quantity = float(value if value is not None else 1)
    if quantity <= 0:
        quantity = 1.0
    return round(quantity, 3)


def _parse_percent_sum(value):
    try:
        percent_sum = int(value)
    except (TypeError, ValueError):
        percent_sum = 100
    return max(percent_sum, 100)


def _row_to_work(row):
    return {
        "id": row["id"],
        "object_id": row["object_id"],
        "service_id": row["service_id"],
        "subobject_name": row["subobject_name"],
        "name": row["name"],
        "price": row["price"],
        "unit": row["unit"],
        "quantity": row["quantity"],
        "created_at": row["created_at"],
        "updated_at": row["updated_at"],
        "start_order_at": row["start_order_at"],
        "coefficients": row["coefficients"],
        "percent_sum": row["percent_sum"],
    }


def create_works_table(client_name, client_id):
    """Create works table if not exists."""
    with _connect(client_name, client_id) as conn:
        columns = _table_columns(conn)
        if columns and columns != _WORKS_COLUMNS:
            logger.warning("completed_works table schema mismatch, recreating table")
            conn.execute("DROP TABLE completed_works")

        conn.execute("""
            CREATE TABLE IF NOT EXISTS completed_works (
                id TEXT PRIMARY KEY,
                object_id TEXT NOT NULL,
                service_id TEXT NOT NULL,
                subobject_name TEXT NOT NULL DEFAULT '',
                name TEXT NOT NULL,
                price INTEGER NOT NULL,
                unit TEXT,
                quantity NUMERIC(18, 3) NOT NULL DEFAULT 1,
                created_at INTEGER NOT NULL DEFAULT 0,
                updated_at INTEGER NOT NULL DEFAULT 0,
                start_order_at INTEGER NOT NULL DEFAULT 0,
                coefficients TEXT NOT NULL DEFAULT '',
                percent_sum INTEGER NOT NULL DEFAULT 100
            )
        """)
        conn.commit()


def add_work(client_name, client_id, data):
    """Add new work entry."""
    if not data:
        return {}

    name = data.get("name", "").strip()
    if not name:
        return {}

    work_id = str(uuid.uuid4())
    object_id = data.get("object_id", "")
    service_id = data.get("service_id", "")
    subobject_name = data.get("subobject_name", "").strip()
    price = int(data.get("price", 0))
    unit = data.get("unit", "").strip()
    quantity = _parse_quantity(data.get("quantity", 1))
    coefficients = str(data.get("coefficients", "")).strip()
    percent_sum = _parse_percent_sum(data.get("percent_sum", 100))
    now = int(datetime.now().timestamp())
    start_order_at = int(data.get("start_order_at", now))

    create_works_table(client_name, client_id)

    try:
        with _connect(client_name, client_id) as conn:
            conn.execute("""
                INSERT INTO completed_works (
                    id, object_id, service_id, subobject_name, name, price, unit, quantity,
                    created_at, updated_at, start_order_at, coefficients, percent_sum
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                work_id, object_id, service_id, subobject_name, name, price, unit, quantity,
                now, now, start_order_at, coefficients, percent_sum,
            ))
            conn.commit()
            return {
                "id": work_id,
                "object_id": object_id,
                "service_id": service_id,
                "subobject_name": subobject_name,
                "name": name,
                "price": price,
                "unit": unit,
                "quantity": quantity,
                "created_at": now,
                "updated_at": now,
                "start_order_at": start_order_at,
                "coefficients": coefficients,
                "percent_sum": percent_sum,
            }
    except sqlite3.IntegrityError:
        return {}


def load_works(client_name, client_id):
    """Load all works ordered by start_order_at desc."""
    create_works_table(client_name, client_id)

    with _connect(client_name, client_id) as conn:
        rows = conn.execute(
            f"""SELECT {_WORKS_SELECT_COLUMNS}
               FROM completed_works
               ORDER BY start_order_at DESC, updated_at DESC"""
        ).fetchall()

    return [_row_to_work(row) for row in rows]


def load_works_by_object(client_name, client_id, object_id):
    """Load works for specific object."""
    if not object_id:
        return []

    create_works_table(client_name, client_id)

    with _connect(client_name, client_id) as conn:
        rows = conn.execute(
            f"""SELECT {_WORKS_SELECT_COLUMNS}
               FROM completed_works
               WHERE object_id = ?
               ORDER BY start_order_at DESC, updated_at DESC""",
            (object_id,)
        ).fetchall()

    return [_row_to_work(row) for row in rows]


def load_works_by_start_order(client_name, client_id, object_id, start_order_at):
    """Load works for specific object and order."""
    if not object_id or not start_order_at:
        return []

    create_works_table(client_name, client_id)

    with _connect(client_name, client_id) as conn:
        rows = conn.execute(
            f"""SELECT {_WORKS_SELECT_COLUMNS}
               FROM completed_works
               WHERE object_id = ? AND start_order_at = ?
               ORDER BY start_order_at DESC, updated_at DESC""",
            (object_id, start_order_at)
        ).fetchall()

    return [_row_to_work(row) for row in rows]


def load_works_by_select_at(client_name, client_id, object_id, start_order_at):
    """Load works for specific object and selected order."""
    if not object_id or not start_order_at:
        return []

    create_works_table(client_name, client_id)

    with _connect(client_name, client_id) as conn:
        rows = conn.execute(
            f"""SELECT {_WORKS_SELECT_COLUMNS}
               FROM completed_works
               WHERE object_id = ? AND start_order_at = ?
               ORDER BY updated_at DESC""",
            (object_id, start_order_at)
        ).fetchall()

    return [_row_to_work(row) for row in rows]


def load_subobject_names(client_name, client_id, object_id):
    """Load distinct subobject names for object."""
    if not object_id:
        return []

    create_works_table(client_name, client_id)

    with _connect(client_name, client_id) as conn:
        rows = conn.execute(
            """
            SELECT DISTINCT subobject_name
            FROM completed_works
            WHERE object_id = ? AND subobject_name != ''
            ORDER BY subobject_name
            """,
            (object_id,),
        ).fetchall()

    return [row["subobject_name"] for row in rows]


def delete_work(client_name, client_id, work_id):
    """Delete work by id."""
    if not work_id:
        return False

    with _connect(client_name, client_id) as conn:
        cursor = conn.execute(
            "DELETE FROM completed_works WHERE id = ?",
            (work_id,)
        )
        conn.commit()
        return cursor.rowcount > 0


def update_work(client_name, client_id, data):
    """Update work entry."""
    if not data:
        return False

    work_id = data.get("id")
    if not work_id:
        return False

    updates = []
    params = []

    if "object_id" in data:
        updates.append("object_id = ?")
        params.append(data["object_id"])

    if "service_id" in data:
        updates.append("service_id = ?")
        params.append(data["service_id"])

    if "subobject_name" in data:
        updates.append("subobject_name = ?")
        params.append(data["subobject_name"].strip())

    if "name" in data:
        name = data["name"].strip()
        if name:
            updates.append("name = ?")
            params.append(name)

    if "price" in data:
        updates.append("price = ?")
        params.append(int(data["price"]))

    if "unit" in data:
        updates.append("unit = ?")
        params.append(data["unit"].strip())

    if "quantity" in data:
        updates.append("quantity = ?")
        params.append(_parse_quantity(data["quantity"]))

    if "start_order_at" in data:
        updates.append("start_order_at = ?")
        params.append(int(data["start_order_at"]))

    if "coefficients" in data:
        updates.append("coefficients = ?")
        params.append(str(data["coefficients"]).strip())

    if "percent_sum" in data:
        updates.append("percent_sum = ?")
        params.append(_parse_percent_sum(data["percent_sum"]))

    if not updates:
        return False

    updates.append("updated_at = ?")
    params.append(int(datetime.now().timestamp()))
    params.append(work_id)

    try:
        with _connect(client_name, client_id) as conn:
            cursor = conn.execute(f"""
                UPDATE completed_works
                SET {', '.join(updates)}
                WHERE id = ?
            """, params)
            conn.commit()
            return cursor.rowcount > 0
    except sqlite3.IntegrityError:
        return False


def get_orders(client_name, client_id, object_id):

    with _connect(client_name, client_id) as conn:
        rows = conn.execute("""
            SELECT start_order_at,
            SUM(quantity * price * (percent_sum / 100.0)) AS total_price
            FROM completed_works
            WHERE object_id = ?
            GROUP BY start_order_at
        """, (object_id,)).fetchall()
        return [
            {
                "start_order_at": row["start_order_at"],
                "total_price": row["total_price"]
            }
            for row in rows
        ]


def get_result_works(client_name, client_id, object_ids, orders_at):
    if not orders_at or not object_ids:
        return []
    with _connect(client_name, client_id) as conn:
        place_hold_objects = ",".join("?" * len(object_ids))
        place_hold_orders = ",".join("?" * len(orders_at))
        sql = f"""
        SELECT
            subobject_name,
            name,
            price,
            unit,
            quantity,
            start_order_at,
            coefficients,
            percent_sum
        FROM completed_works
        WHERE object_id IN ({place_hold_objects})
          AND start_order_at IN ({place_hold_orders})
        ORDER BY subobject_name
        """

        rows = conn.execute(
            sql,
            tuple(object_ids) + tuple(orders_at),
        ).fetchall()

    return [_row_to_result(row) for row in rows]


def _row_to_result(row):
    return {
        "subobject_name": row["subobject_name"],
        "name": row["name"],
        "price": row["price"],
        "unit": row["unit"],
        "quantity": row["quantity"],
        "start_order_at": row["start_order_at"],
        "coefficients": row["coefficients"],
        "percent_sum": row["percent_sum"],
    }


def merge_from_database(source_db_path, client_name, client_id):
    """Insert works from source db that are missing in target (by id)."""
    from pathlib import Path

    source = Path(source_db_path)
    if not source.exists() or not client_name or not client_id:
        return 0

    create_works_table(client_name, client_id)
    inserted = 0
    with sqlite3.connect(source) as src, _connect(client_name, client_id) as dst:
        src.row_factory = sqlite3.Row
        rows = src.execute(
            f"SELECT {_WORKS_SELECT_COLUMNS} FROM completed_works"
        ).fetchall()
        for row in rows:
            cursor = dst.execute(
                """
                INSERT OR IGNORE INTO completed_works (
                    id, object_id, service_id, subobject_name, name, price, unit, quantity,
                    created_at, updated_at, start_order_at, coefficients, percent_sum
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    row["id"],
                    row["object_id"],
                    row["service_id"],
                    row["subobject_name"],
                    row["name"],
                    row["price"],
                    row["unit"],
                    row["quantity"],
                    row["created_at"],
                    row["updated_at"],
                    row["start_order_at"],
                    row["coefficients"],
                    row["percent_sum"],
                ),
            )
            if cursor.rowcount and cursor.rowcount > 0:
                inserted += 1
        dst.commit()
    return inserted
