# Production build (portable)

Как в dapchainvpn-client: отдельно **build** и **pack**, артефакты по ОС.

```
prod_build/
├── build.sh / pack.sh     # общие entry (bash)
├── validate.sh
├── targets/               # windows.sh, osx.sh
├── packaging/             # windows.sh, osx.sh
├── windows/               # PowerShell build/pack + артефакты
└── mac/                   # bash build/pack + PyInstaller + артефакты
```

## Windows (C++ desktop)

```powershell
powershell -ExecutionPolicy Bypass -File .\prod_build\windows\build.ps1
powershell -ExecutionPolicy Bypass -File .\prod_build\windows\pack.ps1
```

Или одной цепочкой после `build`:

```powershell
.\prod_build\windows\build.ps1 -BuildType release
.\prod_build\windows\pack.ps1
```

Результат в `prod_build/windows/`:

| Путь | Кто создаёт |
|------|-------------|
| `build/` | cmake/ninja |
| `dist/WorkOrder.exe` | build |
| `WorkOrder/` | pack (windeployqt, portable) |
| `WorkOrder-desktop-<ver>-setup.exe` | pack (NSIS installer) |

Нужен [NSIS](https://nsis.sourceforge.io/Download) (`makensis`). Установка: `winget install NSIS.NSIS`.

Опционально zip: `.\prod_build\windows\pack.ps1 -AlsoZip`.

На другом ПК: запустить `WorkOrder-desktop-*-setup.exe` (или скопировать папку `WorkOrder/`).

## macOS (Python / PyInstaller)

```bash
./prod_build/mac/build.sh desktop
./prod_build/mac/pack.sh
```

Или через общие скрипты:

```bash
./prod_build/build.sh --target osx release
./prod_build/pack.sh --target osx release
```

Результат в `prod_build/mac/`:

| Путь | Кто создаёт |
|------|-------------|
| `dist/WorkOrder.app` | build |
| `WorkOrder.app` | pack |
| `WorkOrder-<type>-<ver>.dmg` | pack |

## Иконка Windows

`resources/icons/appIcons/icon_win32.ico` (из `icon_linux.png`):

```powershell
python scripts\generate_win_icon.py
```
