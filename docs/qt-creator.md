# Qt Creator

## Desktop и Mobile (compact)

Два режима UI — **разные run target**, не только переменная CMake `Type`:

| Режим | Target запуска ▶ | Окно |
|-------|-------------------|------|
| **Desktop** | **`run-desktop`** | Широкое, боковое меню |
| **Mobile (compact)** | **`run-mobile`** | Узкое (375px), нижняя навигация |

Переменная **`Type`** в CMake cache влияет на QML-пути редактора, но **не переключает UI при Run**, если выбран не тот target.

**Projects → Run → Add → CMake Target → `run-mobile`** — для компактной версии.

После Run CMake в логе при старте:
```
Starting WorkOrder, type=mobile
```
и заголовок окна **WorkOrder - Mobile**.

Общие компоненты: `resources/qml/WorkOrder/Common/`.

В дереве проекта Qt Creator:

- **`desktop-ui`** — только desktop QML
- **`mobile-ui`** — только mobile QML (compact)
- **`common-ui`** — общие QML-компоненты
- **`workorder_ide`** — все файлы с группировкой `UI/Desktop`, `UI/Mobile (compact)`, `UI/Common`

Переключать режим **не нужно через Reconfigure** — достаточно выбрать нужный run target.

## Первичная настройка

1. **File → Open** → `CMakeLists.txt`
2. Kit: **Desktop Qt 6.8.x GCC 64bit** (Linux) или **Qt 6.x for macOS**
3. **Configure Project**
4. Оставить активным **один** kit (Desktop Qt 6.8.3), отключить Qt 5.15 / Android

## Запуск

**Важно:** target **`build`** только проверяет конфигурацию и **не запускает приложение**.
Для ▶ нужен **`run-desktop`** или **`run-mobile`**.

| Target | Назначение |
|--------|------------|
| **`run-desktop`** | Запуск desktop UI (рекомендуется) |
| **`run-mobile`** | Запуск compact/mobile UI |
| **`build`** | Только подготовка (для кнопки молотка) |
| **`test`** | Unit-тесты |

### Настройка Run в Qt Creator

1. Слева **Projects** (шестерёнка) → **Run**
2. **Run configuration** → если там `build`, удалите или не используйте
3. **Add** → **CMake Target** → **`run-desktop`**
4. При необходимости добавьте вторую конфигурацию **`run-mobile`**
5. Выберите нужную конфигурацию в выпадающем списке рядом с ▶
6. **Build → Run CMake** (после обновления CMakeLists)

После Reconfigure Qt Creator должен сам предложить **`run-desktop`** и **`run-mobile`**
(у них свойство `FOLDER = qtc_runnable`).

Кнопка **молоток** (Build) → target `build` — это нормально.
Кнопка **▶** (Run) → должен быть `run-desktop` или `run-mobile`.

Перед первым запуском:

```bash
cd workorder
# Linux: если venv перенесён с macOS или PyQt6 не найден
sudo apt install python3-venv   # один раз, Ubuntu/Debian
cmake --build build/desktop --target install-deps
```

В Qt Creator: собрать target **`install-deps`**, затем **Run CMake**, затем ▶ **`run-desktop`**.

Если `.venv` был скопирован с macOS — он нерабочий на Linux. Target **`install-deps`** пересоздаёт его (`venv --clear`).

## macOS

| Target | Назначение |
|--------|------------|
| **`run-desktop`** | `WorkOrder-desktop.app` |
| **`run-mobile`** | `WorkOrder-mobile.app` |
| **`app-bundle`** | `WorkOrder.app` (по cache `Type`) |

## QML-редактор

После configure в логе:

```
Qt6 6.8.x found at ...
QML_IMPORT_PATH=.../resources/qml;.../desktop;.../mobile;...
```

Оба режима доступны для QML completion одновременно.

## Пустое дерево проекта

1. **Build → Run CMake**
2. Должны быть targets **`desktop-ui`**, **`mobile-ui`**, **`workorder_ide`**
3. Kit: **Desktop Qt 6.8.3 GCC 64bit**

## Отдельные build-директории (опционально)

CMake presets **WorkOrder Desktop** / **WorkOrder Mobile (compact)** → `build/desktop` и `build/mobile`.
Обычно достаточно одного kit и targets **`run-desktop`** / **`run-mobile`**.
