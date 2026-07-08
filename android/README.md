# WorkOrder Android build

Entry point: `main.py` (required by `pyside6-android-deploy`).

## На этой машине (Linux)

| Компонент | Путь |
|-----------|------|
| Qt 6.8.3 Android | `~/Qt/6.8.3` |
| Android SDK | `~/Android/Sdk` |
| NDK | `~/Android/Sdk/ndk/26.1.10909125` |
| adb | `/usr/bin/adb` |

### Python 3.11 на Ubuntu 24.04

В стандартных репозиториях нет `python3.11`. Варианты:

1. **Standalone** (уже установлен): `~/.local/python311/bin/python3.11`  
   Однократно нужен symlink (скрипт создаст сам через sudo):
   ```bash
   sudo ln -sfn ~/.local/python311 /install
   ```
2. **deadsnakes PPA**: `sudo add-apt-repository ppa:deadsnakes/ppa && sudo apt install python3.11 python3.11-dev`

Скрипт сам подберёт Python 3.11, если `PYTHON311` не задан или указывает на несуществующий путь.

### Системные пакеты (один раз)

```bash
sudo apt install libffi-dev liblzma-dev uuid-dev zlib1g-dev libssl-dev \
    build-essential git pkg-config ninja-build p7zip-full
```

Не используйте `venv` для cross-compile — только прямой запуск Python 3.11.

### libclang для shiboken6

Системный `llvm-18-dev` **не подходит** (CMake ищет отсутствующие `.a`). Нужен **Qt prebuilt libclang**:

```bash
sudo apt install p7zip-full   # для распаковки .7z
export LLVM_INSTALL_DIR=~/.local/libclang
./scripts/android/build_wheels.sh aarch64   # скачает libclang автоматически
```

Или вручную: [libclang 18.1.5 для Linux x86_64](https://download.qt.io/development_releases/prebuilt/libclang/libclang-release_18.1.5-based-linux-Rhel8.6-gcc10.3-x86_64.7z)

```bash
7z x libclang-release_18.1.5-based-linux-Rhel8.6-gcc10.3-x86_64.7z -o$HOME/.local
export LLVM_INSTALL_DIR=$HOME/.local/libclang
```

Важно: используйте `$HOME/.local`, а не `-o~/.local` — иначе 7z создаст каталог `~/Загрузки/~/.local/`.

## Быстрый старт

```bash
# 1. Зависимости deploy (если ещё нет PySide6)
cd /path/to/workorder
.venv/bin/pip install 'PySide6>=6.8'
.venv/bin/pip install -r .venv/lib/python3.12/site-packages/PySide6/scripts/requirements-android.txt

# 2. Cross-compile wheels (один раз, ~30–90 мин)
./scripts/android/build_wheels.sh aarch64

# 3. Собрать APK (deploy только через Python 3.11!)
export LLVM_INSTALL_DIR=$HOME/.local/libclang
./scripts/android/build_apk.sh
adb install -r WorkOrder*.apk
```

Переменные окружения — `scripts/android/env.sh`.

## Альтернатива: готовые wheels с Qt CDN

С Qt 6.8+ есть официальные wheels для `android_aarch64` / `android_x86_64`.
Скачать с https://download.qt.io/official_releases/QtForPython/pyside6/ и передать:

```bash
export WHEEL_PYSIDE=/path/to/PySide6-...-android_aarch64.whl
export WHEEL_SHIBOKEN=/path/to/shiboken6-...-android_aarch64.whl
./scripts/android/build_apk.sh
```

## Runtime

- UI: always **mobile** (`resources/qml/mobile/`)
- Data: `QStandardPaths.AppDataLocation/data/`
- Dependencies: reportlab, openpyxl (pure Python, bundled in APK)

See [docs/android-apk-plan.md](../docs/android-apk-plan.md).
