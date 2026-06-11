# PyCharm

Запуск Python-части приложения без CMake. QML подхватывается из `resources/qml/` автоматически.

## Открытие проекта

1. **File → Open** → каталог `workorder/` (где лежат `src/`, `requirements.txt`, `.idea/`).
2. Не открывайте родительский `WorkOrder/`, если там нет своего venv — рабочая директория должна быть корнем `workorder/`.

## Интерпретатор Python

1. **Settings → Project: workorder → Python Interpreter**.
2. **Add Interpreter → Add Local Interpreter → Virtualenv Environment**.
3. Location: `workorder/.venv`, base: системный Python 3.9+.
4. После создания: в терминале PyCharm (с активированным venv):

```bash
python3 -m pip install -r requirements.txt
```

Либо выберите уже существующий `.venv/bin/python`, если venv создан заранее.

## Структура модулей

Каталог `src/` помечен как **Sources Root** (см. `.idea/workorder.iml`). Импорты вида `from backend.settings_backend import ...` работают без ручного `PYTHONPATH`.

Точка входа: `src/main.py`.

## Run Configuration

### Вариант A — готовые конфигурации

Если в проекте есть `.idea/runConfigurations/`:

| Конфигурация | Назначение |
|--------------|------------|
| **WorkOrder Desktop** | UI с боковым меню |
| **WorkOrder Mobile** | UI с нижней навигацией |

Выберите конфигурацию в списке Run и нажмите **Run** (▶).

### Вариант B — создать вручную

1. **Run → Edit Configurations → + → Python**.
2. Параметры:

| Поле | Значение |
|------|----------|
| Name | `WorkOrder Desktop` |
| Script | `$PROJECT_DIR$/src/main.py` |
| Parameters | `--type desktop` |
| Working directory | `$PROJECT_DIR$` |
| Python interpreter | `.venv` проекта |

3. Для mobile — дубликат с `--type mobile`.

Переменная `QT_QUICK_CONTROLS_STYLE=Basic` задаётся в `main.py`; в Run Configuration добавлять не обязательно.

## Запуск из терминала PyCharm

```bash
source .venv/bin/activate
python src/main.py --type desktop
python src/main.py --type mobile
```

## Отладка

1. Поставьте breakpoint в `src/backend/*.py` или в `src/main.py`.
2. **Run → Debug** с конфигурацией Desktop или Mobile.

QML-ошибки смотрите в консоли Run (логгер `workorder`).

## QML и UI

PyCharm удобен для Python-бэкенда и тестов. Для правки QML и превью удобнее **Qt Creator** — см. [qt-creator.md](qt-creator.md).

## Частые проблемы

| Симптом | Решение |
|---------|---------|
| `ModuleNotFoundError: PyQt6` | Активируйте `.venv` и выполните `python3 -m pip install -r requirements.txt` |
| `command not found: pip` | На macOS используйте `python3 -m pip` или `.venv/bin/python -m pip` |
| `ModuleNotFoundError: backend` | Working directory = корень `workorder/`, каталог `src` — Sources Root |
| Пустое окно / QML не грузится | Проверьте `--type` и вывод в консоли (`Failed to load QML`) |
| macOS: некорректные кнопки | Убедитесь, что используется свежий PyQt6 из `requirements.txt` |
