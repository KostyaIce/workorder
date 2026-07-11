# WorkOrder — быстрый старт

## Зависимости

```bash
cd workorder
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

## Запуск

```bash
# Desktop
python src/main.py --type desktop

# Mobile
python src/main.py --type mobile
```

## CMake

Отдельные проекты для Python и C++:

```bash
# Python
cmake --preset python
cmake --build build/python --target run-desktop

# C++ 
cmake --preset cpp
cmake --build build/cpp --target run-desktop
```

## PyCharm

```bash
cd workorder
python3 -m venv .venv && source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

**File → Open** → `workorder/`, интерпретатор `.venv`, Run **WorkOrder Desktop** или **WorkOrder Mobile**.

Подробнее: [pycharm.md](pycharm.md)

## Qt Creator

Открыть `python/CMakeLists.txt` или `cpp/CMakeLists.txt`. Подробнее: [qt-creator.md](qt-creator.md)
