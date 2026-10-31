# Коэффициенты

Коэффициенты хранятся отдельно от услуг: своя таблица, своя модель и свой раздел
в Excel-файле.

## Хранилище

Таблица `coefficients` находится в том же файле `services.db`:

```sql
CREATE TABLE coefficients (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  price INTEGER NOT NULL,      -- процент * 100, то есть 150% = 15000
  unit TEXT NOT NULL DEFAULT '%',
  keywords TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

Слой БД: `cpp/utils/CoefficientsDatabase.{h,cpp}`.

### Миграция

Раньше коэффициенты лежали в таблице `services` и отличались только процентной
единицей измерения. `CoefficientsDatabase::createCoefficientsTable()` один раз
переносит такие строки в `coefficients` и удаляет их из `services`
(`CoefficientsDatabase::migratePercentServices()`).

## Модель

- `CoefficientItem`, `CoefficientsModel` — роли `id, name, price, unit, keywords,
  created_at, updated_at`;
- `CoefficientsFilterModel` — поиск по названию и ключевым словам, при пустой
  строке показывает все коэффициенты;
- `ServicesFilterModel` больше не фильтрует строки по процентной единице.

QML-контекст: `coefficientsModel`, `coefficientsFilterModel`.
CRUD в `InvoiceBackend`: `addCoefficient(data)` (возвращает новый id),
`updateCoefficient(data)`, `deleteCoefficient(id)`, `getAllCoefficients()`.

Правило процентов: `100 = +0%`, `150 = +50%`. Итог — сумма надбавок плюс 100,
например `105 + 150 = 155`. Формула в `ReportBackend::coefficientPercentPoints()`.

## Excel

Один лист `Services`, колонки `A = название`, `B = примечание/ключевые слова`,
`C = цена`, `D = единица`.

- экспорт: сначала разделы услуг (по полю `paragraph`), затем отдельный раздел
  **`Коэффициенты`**; в колонке `B` у коэффициентов хранятся ключевые слова;
- импорт: строки раздела `Коэффициенты` попадают в таблицу `coefficients`;
  строки с процентной единицей попадают туда же даже без раздела (старые файлы);
  заголовок раздела распознаётся без учёта регистра, принимаются написания
  `Коэффициенты`, `Коэфициенты`, `Coefficients`.

Код: `cpp/utils/ServicesExcelBuilder.{h,cpp}` (`ExcelCatalog`,
`importCatalogFromExcel`, `exportCatalogExcel`).

## PDF-презентация услуг

`exportServicesPdf()` принимает услуги и коэффициенты. В конце документа
коэффициенты выводятся отдельным разделом **«Коэффициенты»** (название, значение,
единица).

## Облачная синхронизация

`services.json` содержит два массива: `"services"` и `"coefficients"`. Оба
сливаются по `updated_at` (см. [cloud-disk.md](cloud-disk.md)). Файл без ключа
`"coefficients"` локальные коэффициенты не меняет.

## Проверка

Автономный тест таблицы, миграции и Excel-раздела:

```bash
clang++ -std=c++17 -Icpp/utils tests/coefficients_test.cpp \
  build-cpp/cpp/utils/libworkorder_utils.a \
  -framework QtCore -framework QtSql -framework QtGui -framework AppKit
```
