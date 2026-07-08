# План: WorkOrder → APK (Android)

## Цель

Запуск **mobile (compact)** UI на Android в виде `.apk`, с сохранением Python-бэкенда и QML.

## Исходное состояние проекта

| Компонент | Статус |
|-----------|--------|
| UI mobile | `resources/qml/mobile/` — готов как основа |
| UI desktop | Не нужен на Android |
| Runtime | Python 3 + `qt_compat` (PyQt6 desktop / PySide6 Android) |
| Данные | `app_paths.data_dir()` — проект `./data/` или AppData на Android |
| PDF / Excel | reportlab, openpyxl (pure Python, в APK без нативной сборки) |
| БД | sqlite3 (stdlib) |
| Сборка сейчас | PyInstaller → macOS; CMake — dev/QML |

## Стратегия (рекомендуется)

**Вариант A (рекомендуется): PySide6 + `pyside6-android-deploy`**

- Лучше документирован Qt-путь для Android.
- Сборка APK — с **Linux** (Ubuntu).
- Потребуется замена `PyQt6` → `PySide6` (API близкий, но не идентичный).

**Вариант B (альтернатива): PyQt6 + pyqtdeploy**

- Остаёмся на PyQt6.
- Сложнее настройка sysroot/NDK, меньше примеров.
- Имеет смысл, если критично не менять bindings.

Ниже план для **варианта A**; для B этапы 0–3 те же, этап 4 — pyqtdeploy вместо pyside6-android-deploy.

---

## Этап 0. Подготовка (1–2 дня)

### 0.1. Окружение на Linux

- Ubuntu 22.04/24.04 (можно VM или отдельная машина).
- Qt 6.8.x for Android (через Qt Online Installer).
- Android SDK + NDK (через Qt Maintenance Tool / Android Studio).
- JDK 17.

Проверка: в Qt Creator kit **Android Qt 6.8.x** конфигурируется без ошибок.

### 0.2. Scope MVP для первого APK

**Включить в v0.1:**

- Запуск mobile UI.
- SQLite: клиенты, услуги, счета (локально на телефоне).
- Просмотр/редактирование offline.
- Генерация PDF (reportlab) и импорт/экспорт Excel (openpyxl) — **pure Python**, упаковываются в APK вместе с embedded Python, отдельной cross-compile не требуют.

**Отложить на v0.2:**

- FileDialog на внешние файлы (SAF / storage permissions).
- Подпись release AAB для Google Play.

### 0.3. Уже сделано в репозитории

| Компонент | Файл |
|-----------|------|
| Пути данных | `src/app_paths.py` — `data_dir()`, `is_android_runtime()` |
| Qt bindings | `src/qt_compat.py` — PySide6 / PyQt6 |
| Android entry | `android/main.py`, `android/pysidedeploy.spec` |
| Зависимости APK | `android/requirements.txt`, `requirements-android.txt` |
| Миграция imports | `src/backend/*`, `src/models/*` → `qt_compat` |

### 0.4. Ветка в git

```text
feature/android-apk
```

---

## Этап 1. Абстракция платформы — **выполнено**

Цель: один код для desktop и Android, без `./data/` в корне проекта.

### 1.1. Единый модуль путей — `src/app_paths.py`

| Платформа | Данные приложения |
|-----------|-------------------|
| Linux/macOS/Win | `<project>/data` или `WORKORDER_DATA_DIR` |
| Android | `QStandardPaths.AppDataLocation/data` |

Заменены вызовы `./data/` на `data_dir()` в:

- `src/utils/db_storage.py`
- `src/backend/settings_backend.py`
- `resources/qml/.../SettingsContent.qml` (через `defaultImportPath`)

### 1.2. Точка входа

- Android: `android/main.py` → `WORKORDER_PLATFORM=android`, `app_type=mobile`.
- Desktop: `run-desktop` / `run-mobile` без изменений.

### 1.3. Абстракция Qt bindings — `src/qt_compat.py`

PySide6 приоритетен (Android), fallback PyQt6 (desktop dev).

### 1.4. Тесты на desktop

```bash
WORKORDER_APP_TYPE=mobile PYTHONPATH=src python src/main.py --type mobile
python -m unittest discover -s tests -v
```

---

## Этап 2. Миграция PyQt6 → qt_compat — **выполнено**

Desktop остаётся на PyQt6 через fallback в `qt_compat.py`. Android-сборка использует PySide6.

### 2.1. Зависимости

```text
# requirements.txt (desktop)
PyQt6>=6.4.0
reportlab>=4.0.0
openpyxl>=3.1.0

# requirements-android.txt / android/requirements.txt
PySide6>=6.8.0
reportlab>=4.0.0
openpyxl>=3.1.0
```

reportlab и openpyxl — **без C-расширений под Android ABI**; pip ставит их в site-packages внутри APK.

### 2.2. Типичные замены

| PyQt6 | PySide6 |
|-------|---------|
| `from PyQt6.QtCore import ...` | `from PySide6.QtCore import ...` |
| `pyqtSignal` | `Signal` |
| `pyqtSlot` | `Slot` |
| `pyqtProperty` | `Property` |
| `@pyqtSlot` | `@Slot` |

Файлы для правки (grep по `PyQt6`, `pyqt`):

- `src/main.py`
- `src/backend/*.py`
- `src/models/*.py`
- `tests/`

### 2.3. QML

Обычно менять не нужно — тот же Qt Quick.

Проверить mobile QML на эмуляторе/desktop через `run-mobile`.

### 2.4. Desktop-сборка после миграции

- Linux: `run-desktop`, `run-mobile`.
- macOS: `run-desktop`, app-bundle (обновить скрипты под PySide6 или оставить PyQt6 на main, PySide6 только в android-ветке — хуже, лучше один bindings).

---

## Этап 3. Адаптация UI/UX под Android (2–3 дня)

### 3.1. Mobile-only на Android

- Фиксированный `app_type=mobile`.
- Проверить все экраны: Счёт, База, Отчёты, Настройки.

### 3.2. Экран и DPI

- Уже есть mobile layout; проверить на разных DPI (эмулятор 720p, 1080p).
- `QGuiApplication.setHighDpiScaleFactorRoundingPolicy` — проверить на Android.

### 3.3. FileDialog (v0.2)

- Запрос разрешений (READ/WRITE storage или SAF).
- Сохранение PDF/XLSX в `Downloads` или через share intent.

### 3.4. PDF / Excel на Android

- reportlab и openpyxl уже в `android/requirements.txt`.
- После первого APK: smoke-test `import reportlab`, `import openpyxl`, экспорт PDF и XLSX в app data dir.
- Если понадобится выбор файла с SD-карты — SAF в v0.2, не блокирует MVP.

### 3.4. Иконка и имя

- `resources/icons/appIcons/icon_linux.png` → adaptive icon для Android.
- `AndroidManifest.xml` (генерируется deploy-инструментом) — имя «WorkOrder».

---

## Этап 4. Сборка APK (3–7 дней, с отладкой)

### 4.1. Cross-compile PySide6 wheels (один раз на версию Qt)

По документации Qt for Python 6.8:

- Склонировать `pyside-setup`.
- Собрать wheels для `aarch64` (arm64-v8a) — основная архитектура телефонов.
- Опционально: `x86_64` для эмулятора.

### 4.2. Структура для deploy

```text
android/
  main.py              # entry для pyside6-android-deploy (p4a ищет main.py в корне app)
  pysidedeploy.spec    # package com.workorder.app, arm64-v8a
  requirements.txt     # PySide6, Pillow, reportlab 4.2.5, openpyxl, chardet
  src -> ../src        # symlink, создаёт build_apk.sh перед сборкой
  resources -> ../resources
```

Требование инструмента: entry point должен называться **`main.py`**.

Buildozer запускается из `android/` с `source.dir = .` (относительно cwd). Без симлинков `src/` и `resources/` в каталог app попадают только `_applibs/` и `sitecustomize.py` — p4a падает с «No main.py(c) found».

`android/main.py` определяет корень проекта автоматически: рядом лежит `src/` (упакованный APK) или родительский каталог (разработка из репозитория).

### 4.3. Первая сборка (debug APK)

```bash
P4A_CLEAN=1 ./scripts/android/build_apk.sh
```

Результат: `WorkOrder.apk` в каталоге проекта.

### 4.4. Установка на устройство

```bash
adb install -r WorkOrder.apk
adb logcat | grep -i python   # отладка
```

### 4.5. Release (AAB для Google Play)

- `pysidedeploy.spec`: mode = release.
- Подпись keystore.
- Сборка `.aab`.

---

## Этап 5. Дополнительно (опционально)

### 5.1. Pillow + reportlab (полный PDF/Excel)

В APK включаются:

| Пакет | Назначение | Сборка p4a |
|-------|------------|------------|
| **Pillow** | зависимость reportlab 4.2.5 | нативная (jpeg, png, freetype) |
| **reportlab 4.2.5** | PDF отчёты и презентации услуг | pure-Python wheel, рецепт `scripts/android/p4a_recipes/reportlab/` |
| **openpyxl + et_xmlfile** | импорт/экспорт Excel | pip |
| **DejaVuSans.ttf** | кириллица в PDF | `source.include_exts` → `ttf` |

Важно: не смешивать старый p4a-рецепт reportlab 3.5 (compiled) с wheel 4.2.5 — перед пересборкой:

```bash
P4A_CLEAN=1 ./scripts/android/build_apk.sh
```

Права на файлы: `READ/WRITE_EXTERNAL_STORAGE` (импорт/экспорт через Qt FileDialog).

### 5.2. CI и поддержка

- GitHub Actions / GitLab CI на Linux runner.
- Артефакт: debug APK по тегу.
- Отдельный job: desktop PySide6 tests.

---

## Риски

| Риск | Вероятность | Митигация |
|------|-------------|-----------|
| Cross-compile PySide6 wheels | Средняя | Документация Qt 6.8, один раз на версию |
| openpyxl/reportlab/Pillow на Android | Средняя | Pillow — native p4a; reportlab — кастомный wheel-рецепт; `P4A_CLEAN=1` при смене рецепта |
| Большой размер APK (100+ MB) | Высокая | Принять или strip debug |
| qt_compat регрессии desktop | Средняя | Тесты + desktop QA |
| Пути к файлам на Android | Средняя | `data_dir()` уже в коде |
| Сборка только с Linux | Средняя | VM / CI |

---

## Оценка сроков

| Этап | Срок |
|------|------|
| 0–2. Подготовка, пути, qt_compat | **готово** |
| 3. UI Android | 2–3 дня |
| 4. Первый APK (MVP + PDF/Excel) | 3–7 дней |
| **Итого до APK** | **~1–2 недели** |

---

## Чеклист MVP (Definition of Done)

- [ ] APK устанавливается на Android 10+ (arm64)
- [ ] Открывается mobile UI (4 вкладки)
- [ ] SQLite создаётся в app data dir
- [ ] CRUD услуг и клиентов работает offline
- [ ] PDF-отчёт и Excel export/import работают (reportlab, openpyxl)
- [ ] Desktop (Linux/macOS) через PyQt6 не сломан
- [ ] Размер APK задокументирован
- [ ] Логи через `adb logcat` читаемы

---

## Порядок работ (кратко)

```text
1. ~~data_dir() + qt_compat~~
2. ~~android/main.py + requirements~~
3. Cross-compile PySide6 wheels (Linux)
4. pyside6-android-deploy → debug APK
5. Тест на телефоне: UI, SQLite, PDF, Excel
6. FileDialog / SAF (v0.2)
7. Release AAB (если нужен Store)
```

---

## Что не делать

- Не пытаться собрать APK через PyInstaller.
- Не полагаться на CMake Android kit — он не упакует Python.
- Не тащить desktop UI на Android.
- Не откладывать reportlab/openpyxl — они pure Python и уже в `android/requirements.txt`.
