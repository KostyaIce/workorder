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

## CMake (Type при конфигурации)

Один preset **WorkOrder**, переключение UI через `-DType=`:

```bash
cmake --preset workorder
cmake --build build --target run

# Mobile UI
cmake --preset workorder -DType=mobile
cmake --build build --target run
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

Открыть `CMakeLists.txt` или `WorkOrder.pro`. Подробнее: [qt-creator.md](qt-creator.md)
