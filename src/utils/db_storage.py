#!/usr/bin/env python3
"""
SQLite storage helpers for services and completed works.
"""

import sqlite3
import uuid
from datetime import datetime
from pathlib import Path

SERVICES_SCHEMA = """
CREATE TABLE IF NOT EXISTS services (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    price REAL NOT NULL CHECK(price >= 0)
);
"""

WORKS_SCHEMA = """
CREATE TABLE IF NOT EXISTS completed_works (
    id INTEGER PRIMARY KEY,
    work_number TEXT NOT NULL UNIQUE,
    service_id INTEGER,
    service_name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK(quantity > 0),
    unit_price REAL NOT NULL CHECK(unit_price >= 0),
    total_price REAL NOT NULL CHECK(total_price >= 0),
    client_id INTEGER,
    client_name TEXT NOT NULL DEFAULT '',
    completed_at TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'completed',
    notes TEXT NOT NULL DEFAULT ''
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

SAMPLE_WORKS = [
    (
        1,
        "WO-0001",
        2,
        "Ремонт компьютера",
        1,
        1500.0,
        1500.0,
        1,
        "Иванов И.И.",
        "2026-01-10",
        "completed",
        "Замена оперативной памяти",
    ),
    (
        2,
        "WO-0002",
        8,
        "Чистка от пыли",
        1,
        1000.0,
        1000.0,
        2,
        "Петрова А.С.",
        "2026-01-15",
        "completed",
        "Ноутбук перегревался",
    ),
    (
        3,
        "WO-0003",
        6,
        "Установка Windows",
        1,
        2500.0,
        2500.0,
        3,
        "Сидоров К.В.",
        "2026-01-22",
        "completed",
        "Windows 11, драйверы",
    ),
    (
        4,
        "WO-0004",
        4,
        "Замена экрана",
        1,
        3500.0,
        3500.0,
        4,
        "Козлова М.П.",
        "2026-02-03",
        "completed",
        "Матрица 15.6",
    ),
    (
        5,
        "WO-0005",
        1,
        "Диагностика оборудования",
        2,
        500.0,
        1000.0,
        5,
        "ООО ТехноСервис",
        "2026-02-18",
        "completed",
        "Два устройства",
    ),
    (
        6,
        "WO-0006",
        11,
        "Настройка сети",
        1,
        1200.0,
        1200.0,
        5,
        "ООО ТехноСервис",
        "2026-03-01",
        "completed",
        "Wi-Fi роутер и принтер",
    ),
    (
        7,
        "WO-0007",
        10,
        "Восстановление данных",
        1,
        3000.0,
        3000.0,
        6,
        "Белова Е.Н.",
        "2026-03-12",
        "completed",
        "Восстановлены документы",
    ),
    (
        8,
        "WO-0008",
        3,
        "Ремонт ноутбука",
        1,
        2000.0,
        2000.0,
        7,
        "Федоров П.Г.",
        "2026-03-25",
        "in_progress",
        "Диагностика материнской платы",
    ),
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


def default_works_db_path():
    return project_data_dir() / "works.db"


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


def create_object_database(client_name, client_id):
    path = object_db_path(client_name, client_id).resolve()
    with _connect(path) as conn:
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
    with _connect(path) as conn:
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

    with _connect(path) as conn:
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
    with _connect(path) as conn:
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
    with _connect(path) as conn:
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
    with _connect(path) as conn:
        current_time = int(datetime.now().timestamp())
        cursor = conn.execute("""
            UPDATE objects
            SET last_order_at = ?
            WHERE id = ?
        """, (current_time, object_id))
        conn.commit()
        return cursor.rowcount > 0

def create_works_database(client_name, client_id):
    path = object_db_path(client_name, client_id).resolve()
    with _connect(path) as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS works (
                id TEXT PRIMARY KEY,
                object_id TEXT NOT NULL,
                subobject_name TEXT,
                service TEXT NOT NULL,
                price DECIMAL(15, 2) NOT NULL,
                unit TEXT,
                amount DECIMAL(19, 4) NOT NULL, 
                tag TEXT,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
            )
        """)
        conn.commit()


def add_work_entry(client_name, client_id, data):
    """Add a new work entry."""
    if not data:
        return False
    
    path = object_db_path(client_name, client_id).resolve()
    current_time = int(datetime.now().timestamp())
    
    with _connect(path) as conn:
        cursor = conn.execute("""
            INSERT INTO works(id, object_id, subobject_name, service, price, unit, amount, tag, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            str(uuid.uuid4()),
            data.get("object_id", ""),
            data.get("subobject_name", ""),
            data.get("service", ""),
            data.get("price", 0.0),
            data.get("unit", ""),
            data.get("amount", 0.0),
            data.get("tag", ""),
            current_time,
            current_time
        ))
        conn.commit()
        return cursor.rowcount > 0


def load_works(client_name, client_id):
    """Load all works from database file."""
    path = object_db_path(client_name, client_id).resolve()
    if not path.exists():
        return []

    with _connect(path) as conn:
        rows = conn.execute(
            """SELECT id, object_id, subobject_name, service, price, unit, amount, tag, created_at, updated_at
               FROM works
               ORDER BY updated_at DESC"""
        ).fetchall()

    return [
        {
            "id": row["id"],
            "object_id": row["object_id"],
            "subobject_name": row["subobject_name"],
            "service": row["service"],
            "price": row["price"],
            "unit": row["unit"],
            "amount": row["amount"],
            "tag": row["tag"],
            "created_at": row["created_at"],
            "updated_at": row["updated_at"]
        }
        for row in rows
    ]


def del_work_entry(client_name, client_id, data):
    """Delete a work entry by id."""
    if not data:
        return False
    work_id = data.get("id")
    if not work_id:
        return False
    
    path = object_db_path(client_name, client_id).resolve()
    with _connect(path) as conn:
        conn.execute("DELETE FROM works WHERE id = ?", (work_id,))
        conn.commit()
    return True


def update_work_entry(client_name, client_id, data):
    """Update editable fields of a work entry."""
    if not data:
        return False
    
    work_id = data.get("id")
    if not work_id:
        return False
    
    path = object_db_path(client_name, client_id).resolve()
    current_time = int(datetime.now().timestamp())
    
    with _connect(path) as conn:
        cursor = conn.execute("""
            UPDATE works
            SET subobject_name = ?,
                service = ?,
                price = ?,
                unit = ?,
                amount = ?,
                tag = ?,
                updated_at = ?
            WHERE id = ?
        """, (
            data.get("subobject_name", ""),
            data.get("service", ""),
            data.get("price", 0.0),
            data.get("unit", ""),
            data.get("amount", 0.0),
            data.get("tag", ""),
            current_time,
            work_id
        ))
        conn.commit()
        return cursor.rowcount > 0


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


def load_completed_works(db_path):
    """Load all completed works from database file."""
    path = resolve_db_path(db_path, default_works_db_path())
    if not path.exists():
        return []

    with _connect(path) as conn:
        _migrate_works_table(conn)
        rows = conn.execute(
            """SELECT id, work_number, service_id, service_name, quantity, unit_price,
                      total_price, client_id, client_name, completed_at, status, notes
               FROM completed_works
               ORDER BY id"""
        ).fetchall()

    return [
        {
            "id": row["id"],
            "work_number": row["work_number"],
            "service_id": row["service_id"],
            "service_name": row["service_name"],
            "quantity": row["quantity"],
            "unit_price": row["unit_price"],
            "total_price": row["total_price"],
            "client_id": row["client_id"] or 0,
            "client_name": row["client_name"],
            "completed_at": row["completed_at"],
            "status": row["status"],
            "notes": row["notes"],
        }
        for row in rows
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


def get_works_statistics(db_path=""):
    """Return aggregate stats for completed works database."""
    works = load_completed_works(db_path)
    if not works:
        return {
            "count": 0,
            "completed_count": 0,
            "in_progress_count": 0,
            "total_amount": 0,
        }

    completed = [item for item in works if item["status"] == "completed"]
    in_progress = [item for item in works if item["status"] != "completed"]
    return {
        "count": len(works),
        "completed_count": len(completed),
        "in_progress_count": len(in_progress),
        "total_amount": sum(item["total_price"] for item in completed),
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


def save_completed_works(db_path, works):
    """Persist completed works list to SQLite file."""
    path = resolve_db_path(db_path, default_works_db_path())
    with _connect(path) as conn:
        conn.execute("DROP TABLE IF EXISTS completed_works")
        conn.executescript(WORKS_SCHEMA)
        if works:
            rows = [
                (
                    item["id"],
                    item["work_number"],
                    item.get("service_id"),
                    item["service_name"].strip(),
                    int(item["quantity"]),
                    float(item["unit_price"]),
                    float(item["total_price"]),
                    item.get("client_id") or None,
                    item.get("client_name", ""),
                    item["completed_at"],
                    item.get("status", "completed"),
                    item.get("notes", ""),
                )
                for item in works
            ]
            conn.executemany(
                """INSERT INTO completed_works
                   (id, work_number, service_id, service_name, quantity, unit_price,
                    total_price, client_id, client_name, completed_at, status, notes)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                rows,
            )
        conn.commit()
    return str(path)


def _migrate_works_table(conn):
    conn.executescript(WORKS_SCHEMA)
    columns = [
        row[1] for row in conn.execute("PRAGMA table_info(completed_works)").fetchall()
    ]
    if "client_id" not in columns:
        conn.execute("ALTER TABLE completed_works ADD COLUMN client_id INTEGER")


def _row_client_id(row):
    if "client_id" in row.keys() and row["client_id"] is not None:
        return int(row["client_id"])
    return 0


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


def repair_works_database(file_path=""):
    """
    Check and repair completed works database structure and rows.

    Returns:
        tuple: (report: dict, resolved_path: str)
    """
    db_path = resolve_db_path(file_path, default_works_db_path())
    report = {
        "database": "works",
        "path": str(db_path),
        "fixed": [],
        "removed": 0,
        "kept": 0,
        "integrity_ok": True,
    }

    if not db_path.exists():
        path, count = create_works_database(str(db_path))
        report["fixed"].append("created_missing_database")
        report["kept"] = count
        return report, path

    try:
        with _connect(db_path) as conn:
            integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
            if integrity != "ok":
                report["integrity_ok"] = False
                report["fixed"].append(f"integrity_check:{integrity}")

            conn.executescript(WORKS_SCHEMA)
            _migrate_works_table(conn)
            rows = conn.execute(
                """SELECT id, work_number, service_id, service_name, quantity, unit_price,
                          total_price, client_id, client_name, completed_at, status, notes
                   FROM completed_works
                   ORDER BY id"""
            ).fetchall()
    except sqlite3.DatabaseError as exc:
        path, count = create_works_database(str(db_path))
        report["fixed"].append(f"recreated_corrupted_database:{exc}")
        report["kept"] = count
        return report, path

    cleaned = []
    seen_numbers = set()
    next_id = 1
    for row in rows:
        work_number = (row["work_number"] or "").strip()
        service_name = (row["service_name"] or "").strip()
        if not work_number or not service_name:
            report["removed"] += 1
            report["fixed"].append(f"removed_invalid_row:id={row['id']}")
            continue

        if work_number in seen_numbers:
            work_number = f"WO-{next_id:04d}"
            report["fixed"].append(f"renamed_duplicate_work_number:id={next_id}")

        quantity = max(int(row["quantity"]), 1)
        unit_price = max(float(row["unit_price"]), 0.0)
        total_price = round(quantity * unit_price, 2)
        if abs(total_price - float(row["total_price"])) > 0.001:
            report["fixed"].append(f"recalculated_total:id={row['id']}")

        cleaned.append(
            {
                "id": next_id,
                "work_number": work_number,
                "service_id": row["service_id"],
                "service_name": service_name,
                "quantity": quantity,
                "unit_price": unit_price,
                "total_price": total_price,
                "client_id": _row_client_id(row),
                "client_name": (row["client_name"] or "").strip(),
                "completed_at": (row["completed_at"] or "").strip() or "1970-01-01",
                "status": (row["status"] or "completed").strip() or "completed",
                "notes": (row["notes"] or "").strip(),
            }
        )
        seen_numbers.add(work_number)
        next_id += 1

    save_completed_works(db_path, cleaned)
    report["kept"] = len(cleaned)
    if not report["fixed"]:
        report["fixed"].append("no_changes_required")
    return report, str(db_path)


def save_clients(db_path, clients):
    """Persist clients list to SQLite file."""
    # path = resolve_db_path(db_path, default_clients_db_path())
    # with _connect(path) as conn:
    #     conn.execute("DROP TABLE IF EXISTS clients")
    #     conn.executescript(CLIENTS_SCHEMA)
    #     if clients:
    #         rows = [
    #             (
    #                 item["id"],
    #                 item["kind"],
    #                 item["name"].strip(),
    #                 item.get("contact_info", ""),
    #                 item.get("address", ""),
    #                 item.get("notes", ""),
    #                 item.get("created_at", "2026-01-01"),
    #             )
    #             for item in clients
    #         ]
    #         conn.executemany(
    #             """INSERT INTO clients
    #                (id, kind, name, contact_info, address, notes, created_at)
    #                VALUES (?, ?, ?, ?, ?, ?, ?)""",
    #             rows,
    #         )
    #     conn.commit()
    return str(path)


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


def create_client_table():
    result = False
    path = default_clients_db_path().resolve()
    with _connect(path) as conn:
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
    return result

def add_client_entry(data):
    path = default_clients_db_path().resolve()
    result = False
    with _connect(path) as conn:
        if data:
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


def load_clients():
    """Load all customers and objects from database file."""
    path = default_clients_db_path().resolve()
    if not path.exists():
        return []

    with _connect(path) as conn:
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


def del_client_entry(data):
    if not data:
        return False
    client_id = data.get("id")
    path = default_clients_db_path().resolve()
    with _connect(path) as conn:
        conn.execute(
            """
        DELETE FROM clients
        WHERE id = ?""",
            (client_id,),
        )
        conn.commit()
    return True
