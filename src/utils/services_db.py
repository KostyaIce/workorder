#!/usr/bin/env python3
"""
SQLite storage for services catalog.
Услуги с уникальным названием (name).
"""

import sqlite3
from datetime import datetime
from decimal import Decimal
import uuid
from utils.db_storage import default_services_db_path


def _connect():
    """Create connection to database."""
    db_path = default_services_db_path()
    from pathlib import Path
    db_path = Path(db_path)
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def _keywords_from_name(name):
    """Generate keywords from service name."""
    words = [word.lower() for word in name.split() if len(word) > 2]
    return ", ".join(words) if words else name.lower()


def create_services_table():
    """Create services table if not exists."""
    with _connect() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS services (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                price INTEGER NOT NULL,
                unit TEXT,
                keywords TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
        """)
        conn.commit()


def add_service(data):
    """Add new service. Returns True if success, False if name already exists."""
    if not data:
        return False
    
    name = data.get("name", "").strip()
    if not name:
        return False
    
    id = str(uuid.uuid4())
    price = int(Decimal(data.get("price", "0")) * 100)
    unit = data.get("unit", "").strip()
    keywords = data.get("keywords", "")
    if not keywords:
        keywords = _keywords_from_name(name)
    
    now = datetime.now().isoformat()

    with _connect() as conn:
        conn.execute("""
                     INSERT INTO services (id, name, price, unit, keywords, created_at, updated_at)
                     VALUES (?, ?, ?, ?, ?, ?, ?)
                     """, (id, name, price, unit, keywords, now, now))
        conn.commit()
        return True

    # try:
    #     with _connect() as conn:
    #         conn.execute("""
    #             INSERT INTO services (id, name, price, unit, keywords, created_at, updated_at)
    #             VALUES (?, ?, ?, ?, ?, ?, ?)
    #         """, (id, name, price, unit, keywords, now, now))
    #         conn.commit()
    #         return True
    # except sqlite3.IntegrityError:
    #     # Name already exists (UNIQUE constraint)
    #     return False


def delete_service(service_id):
    """Delete service by id."""
    if not service_id:
        return False
    
    with _connect() as conn:
        cursor = conn.execute(
            "DELETE FROM services WHERE id = ?",
            (service_id,)
        )
        conn.commit()
        return cursor.rowcount > 0


def update_service(data):
    """Update service name, price, unit and/or keywords."""
    if not data:
        return False

    name = data.get("name", "").strip()
    if not name:
        return False

    id = data.get("id").strip()
    price = int(Decimal(data.get("price", "0")) * 100)
    unit = data.get("unit", "").strip()
    keywords = data.get("keywords", "")
    if not keywords:
        keywords = _keywords_from_name(name)

    now = datetime.now().isoformat()
    
    updates = []
    params = []
    
    if name is not None and name.strip():
        updates.append("name = ?")
        params.append(name.strip())
    
    if price is not None:
        updates.append("price = ?")
        params.append(float(price))
    
    if unit is not None:
        updates.append("unit = ?")
        params.append(unit.strip())
    
    if keywords is not None:
        updates.append("keywords = ?")
        params.append(keywords)
    
    if not updates:
        return False
    
    updates.append("updated_at = ?")
    params.append(now)
    params.append(id)
    
    try:
        with _connect() as conn:
            cursor = conn.execute(f"""
                UPDATE services
                SET {', '.join(updates)}
                WHERE id = ?
            """, params)
            conn.commit()
            return cursor.rowcount > 0
    except sqlite3.IntegrityError:
        # Name already exists (UNIQUE constraint)
        return False


def load_services():
    """Load all services ordered by name."""
    create_services_table()
    
    with _connect() as conn:
        rows = conn.execute(
            """SELECT id, name, price, unit, keywords, created_at, updated_at
               FROM services
               ORDER BY name"""
        ).fetchall()
    
    return [
        {
            "id": row["id"],
            "name": row["name"],
            "price": row["price"],
            "unit": row["unit"],
            "keywords": row["keywords"],
            "created_at": row["created_at"],
            "updated_at": row["updated_at"]
        }
        for row in rows
    ]


def get_service_by_id(service_id):
    """Get single service by id."""
    with _connect() as conn:
        row = conn.execute(
            """SELECT id, name, price, unit, keywords, created_at, updated_at
               FROM services
               WHERE id = ?""",
            (service_id,)
        ).fetchone()
    
    if row:
        return {
            "id": row["id"],
            "name": row["name"],
            "price": row["price"],
            "unit": row["unit"],
            "keywords": row["keywords"],
            "created_at": row["created_at"],
            "updated_at": row["updated_at"]
        }
    return None


def search_services(query):
    """Search services by name or keywords (case-insensitive)."""
    if not query:
        return load_services()
    
    query = f"%{query.strip()}%"
    
    with _connect() as conn:
        rows = conn.execute(
            """SELECT id, name, price, unit, keywords, created_at, updated_at
               FROM services
               WHERE name LIKE ? OR keywords LIKE ?
               ORDER BY name""",
            (query, query)
        ).fetchall()
    
    return [
        {
            "id": row["id"],
            "name": row["name"],
            "price": row["price"],
            "unit": row["unit"],
            "keywords": row["keywords"],
            "created_at": row["created_at"],
            "updated_at": row["updated_at"]
        }
        for row in rows
    ]
