# Cloud disk (Yandex.Disk)

Settings → **Облачный диск**: connect OAuth token, list `app:/workOrder`, upload/download database files.

Справочник REST API Яндекс.Диска (эндпоинты, коды, upload/download): [yandex-disk-api.md](yandex-disk-api.md).

## Auth flow (desktop + mobile)

WorkOrder uses a fixed Yandex OAuth Client ID (`d3e1a705454a448b841e617117fec451`).
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

Local DB files live in `AppPaths::dataDir()` / `data_dir()`:

- `clients.db`
- `services.db`
- `{clientName}_{clientId}.db`

| QML / method | Behavior |
|--------------|----------|
| `syncDatabases()` | Stub — status «Синхронизация пока не реализована» |
| `forceUploadDatabases()` | Delete all items in `app:/workOrder`, then upload every local `*.db` |
| `downloadDatabases()` | Delete local `*.db` / `*.db-wal` / `*.db-shm`, then download every remote `*.db` from `app:/workOrder` |

Before upload/download the C++ backend closes all `QSqlDatabase` connections so files can be replaced safely.

Upload API: `GET .../resources/upload?path=app:/workOrder/<file>&overwrite=true` → `PUT` to `href`.  
Download API: `GET .../resources/download?path=...` → `GET` `href` (follow redirects).  
Cloud clear: `DELETE .../resources?path=...&permanently=true` for each listed item.

## Code

- C++: `cpp/backend/CloudDiskBackend.*`, QML context `cloudDiskBackend`
- Python: `src/backend/cloud_disk_backend.py`
- UI: `CloudDiskDialog.qml`, section in `SettingsContent.qml`
