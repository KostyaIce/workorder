# Qt Creator

## Один проект вместо двух

Используется **один** configure preset **WorkOrder** → каталог `build/`.

Переключение UI — через переменную **`Type`** в CMake cache:

| Type | UI |
|------|-----|
| `desktop` | Боковое меню |
| `mobile` | Нижняя навигация |

**Projects → CMake → Current Configuration → CMake Variables → `Type`** → `desktop` или `mobile` → **Reconfigure**.

Старые каталоги `build/desktop` и `build/mobile` можно удалить.

## Первичная настройка

1. **File → Open** → `CMakeLists.txt`
2. Kit: **Qt 6.x for macOS**
3. Preset: **WorkOrder** (один, не Desktop/Mobile отдельно)
4. **Configure Project**

## Сборка и запуск

| Кнопка / target | Назначение |
|-----------------|------------|
| **build** (Build) | Проверка конфигурации, без линковки C++ |
| **run** (Run) | Запуск приложения |

В **Projects → Run** выбрать CMake target **`run`**.

Перед первым запуском:

```bash
cd workorder
python3 -m venv .venv && source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

## Если desktop не собирался раньше

Причина: два отдельных preset (`desktop` / `mobile`) создавали два проекта; desktop часто конфигурировался без kit Qt Creator.

Решение:

```bash
rm -rf build build/desktop build/mobile
```

Затем в Creator: **Build → Clear CMake Configuration** → preset **WorkOrder** → Configure.

## QML-редактор

После configure в логе должно быть:

```
Qt6 6.8.x found at ...
QML_IMPORT_PATH=.../resources/qml/desktop;.../Qt/6.8.3/macos/qml
```

При смене `Type` на `mobile` путь QML обновится после Reconfigure.
