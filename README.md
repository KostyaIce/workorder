# WorkOrder

Приложение для создания счетов и управления базой услуг.

Стек: Python 3 + PyQt6, UI на QML, логика на Python.

## Структура проекта

```
workorder/
├── version.mk               # Версия приложения (MAJOR/MINOR/PATCH)
├── CMakeLists.txt           # Переключатель: WORKORDER_CMAKE_PRESET=python|cpp
├── CMakePresets.json        # Пресеты python / cpp
├── python/CMakeLists.txt    # Python/PyQt6 (IDE, run-desktop, run-mobile)
├── cpp/CMakeLists.txt       # C++ Qt6 (WorkOrder, run-desktop, run-mobile)
├── utils/hooks/             # Git hooks (авто-bump VERSION_PATCH)
├── WorkOrder.pro            # Альтернативное открытие в Qt Creator (qmake)
├── src/
│   ├── main.py              # Точка входа Python
│   └── backend/             # Python-логика
├── cpp/                     # C++ код (utils, models, backend, main.cpp)
├── resources/
│   ├── icons/appIcons/      # icon_macos.icns, icon_win32.ico, icon_linux.png
│   └── qml/
│   ├── desktop/             # QML для десктопа
│   └── mobile/              # QML для мобильных
├── tests/                   # Unit-тесты бэкенда
└── docs/                    # Документация
```

## Требования

- Python 3.9+
- PyQt6 6.4+
- CMake 3.16+ (для Qt Creator и пресетов)
- Qt Creator 11+ (опционально, для QML-редактора)

## Установка зависимостей

```bash
cd workorder
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

## Запуск

### Через Python (без CMake)

```bash
# Desktop
python src/main.py --type desktop

# Mobile
python src/main.py --type mobile
```

### Через CMake

**Python** (PyQt6):

```bash
cmake --preset python
cmake --build build/python --target run-desktop
cmake --build build/python --target run-mobile
```

**C++** (Qt6):

```bash
cmake --preset cpp
cmake --build build/cpp --target WorkOrder
cmake --build build/cpp --target run-desktop
```

В Qt Creator можно открыть напрямую `python/CMakeLists.txt` или `cpp/CMakeLists.txt`.

При сборке через CMake тип UI фиксируется в `build/*/workorder_config.py` и имеет приоритет над `--type`.

### Версия приложения

Источник версии — `version.mk`. Подробности и установка Git-хука авто-bump: [docs/versioning.md](docs/versioning.md).

### macOS: иконка приложения

```bash
cmake --build build --target app-bundle
```

Создаёт `build/WorkOrder.app` с иконкой в Finder. Запуск:

```bash
open build/WorkOrder.app
# или
cmake --build build --target run
```

Для постоянного ярлыка перетащите `WorkOrder.app` в Dock или `/Applications`.

## PyCharm

1. **File → Open** → каталог `workorder/`
2. **Settings → Python Interpreter** → `.venv` (создать или указать существующий), затем `python3 -m pip install -r requirements.txt`
3. Запуск: конфигурации **WorkOrder Desktop** / **WorkOrder Mobile** (▶) или вручную `src/main.py` с `--type desktop|mobile`

Подробнее: [docs/pycharm.md](docs/pycharm.md)

## Qt Creator

1. **File → Open File or Project** → выбрать `CMakeLists.txt` или `WorkOrder.pro`
2. Выбрать kit (Desktop Qt или Generic)
3. Configure с пресетом **Desktop** или **Mobile**
4. Build target **run** для запуска приложения

Подробнее: [docs/qt-creator.md](docs/qt-creator.md)

## Тесты

```bash
python -m unittest discover -s tests -v
```

Или через CMake:

```bash
cmake --build build/desktop --target test
```

## Окна приложения

1. **Создание счета** — выбор услуги, количество, расчёт стоимости
2. **База услуг** — CRUD услуг и цен
3. **Настройки** — тема, язык, параметры счетов и БД
