# Cloud disk (Yandex.Disk)

Settings → **Облачный диск**: connect OAuth token, list `app:/workOrder`, upload/download database files.

Справочник REST API Яндекс.Диска (эндпоинты, коды, upload/download): [yandex-disk-api.md](yandex-disk-api.md).

## Auth flow (desktop + mobile)

WorkOrder uses the Yandex OAuth Client ID from `cpp/CMakeLists.txt` (`e015e5639e814d569f163477e7eb9415`).
Users do not enter Client ID.

1. Press **Открыть авторизацию** (system browser via `QDesktopServices`).
2. Sign in and allow access.
3. Copy the token from the redirect URL (`access_token=...`) or paste the whole URL.
4. Press **Подключить** — token is stored in `QSettings` (`cloud_disk/*`).

Redirect URI for the registered app must be `https://oauth.yandex.ru/verification_code`.

## Storage keys

| Key | Meaning |
|-----|---------|
| `cloud_disk/token` | OAuth token |
| `cloud_disk/disk_url` | API base (default `https://cloud-api.yandex.net/v1/disk`) |

Client ID is compiled into the app, not stored in settings.

## App folder

`ensureWorkOrderDirectory()` checks `app:/workOrder` (GET) and creates it (PUT) if missing.
Called automatically after a successful connect; also available from QML as `cloudDiskBackend.ensureWorkOrderDirectory()`.

OAuth scope: **`cloud_api:disk.app_folder`** only — paths must use `app:/...`, not `disk:/` or `/`.

After connect, backend lists:

`GET {disk_url}/resources?path=app:/workOrder&limit=1000`  
Header: `Authorization: OAuth <token>`

Results are shown in the dialog list.

## Database transfer

Local DB files stay SQLite in `AppPaths::dbDir()` (`{STORAGE}/data/db`):

- `clients.db`
- `services.db`
- `{clientName}_{clientId}.db`

Cloud copies in `app:/workOrder` are JSON with the same base name and a `.json` suffix. Sync exports SQLite to JSON before upload and merges downloaded JSON back into SQLite.

| QML / method | Behavior |
|--------------|----------|
| `syncDatabases()` | Download cloud `*.json` (and leftover `*.db` JSON) to temp → merge into local SQLite by latest revision → upload `*.json` |
| `forceUploadDatabases()` | Delete all items in `app:/workOrder`, then upload every local `*.db` |
| `downloadDatabases()` | Delete local `*.db` / `*.db-wal` / `*.db-shm`, then download every remote `*.db` from `app:/workOrder` |

### Sync merge rules

`syncDatabases()` compares every record from downloaded JSON with the local SQLite row
that has the same `id`. The comparison is applied to all synced tables:

- `clients` and `services` use their ISO `updated_at`;
- `objects`, `completed_works` and `expenses` use their integer `updated_at` timestamp.

For each record:

- Missing locally → insert it;
- Exists locally and remote `updated_at` is newer → replace the local row;
- Exists locally and remote `updated_at` is older or equal → keep the local row.

After merging, the backend re-exports every local database to JSON, so the uploaded
files contain the merged result. The file names stay the same (`clients.json`,
`services.json`, `{clientName}_{clientId}.json`). Files whose merged JSON did not
change are not uploaded again; local-only changes are uploaded as well, which lets
the same merge rules resolve conflicts on the next device.

A write failure returns `-1` and stops the sync instead of being reported as
"0 changed records".

Before upload/download/merge the C++ backend closes all `QSqlDatabase` connections so files can be replaced safely.

Upload API: `GET .../resources/upload?path=app:/workOrder/<file>&overwrite=true` → `PUT` to `href`.  
Download API: `GET .../resources/download?path=...` → `GET` `href` (follow redirects).  
Cloud clear: `DELETE .../resources?path=...&permanently=true` for each listed item.

## Code

- C++: `cpp/backend/CloudDiskBackend.*`, QML context `cloudDiskBackend`
- Python: `src/backend/cloud_disk_backend.py`
- UI: `CloudDiskDialog.qml`, section in `SettingsContent.qml`
