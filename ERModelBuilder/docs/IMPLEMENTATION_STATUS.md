# План разработки плагина ER Model Builder для PL/SQL Developer 15

## Статус выполнения

### Завершено (MVP Core)

#### Этап 1: Подготовка и структура проекта
- [x] Создана структура проекта
- [x] Определены константы и конфигурация (`uConstants.pas`)
- [x] Создан главный файл проекта (`ERModelBuilder.dpr`)

#### Этап 2: Модель данных
- [x] Класс `TColumn` - метаданные колонки
- [x] Класс `TForeignKey` - внешние ключи (поддержка составных ключей)
- [x] Класс `TCheckConstraint` - check ограничения
- [x] Класс `TTableObject` - таблица/представление/синоним
- [x] Класс `TERModel` - контейнер ER модели
- [x] Методы для работы со связанными таблицами (рекурсивно)
- [x] Авто-лейаут для начального размещения

#### Этап 3: Парсер SQL
- [x] Лексический анализатор SQL
- [x] Поддержка SELECT, INSERT, UPDATE, DELETE, MERGE
- [x] Извлечение имен таблиц из FROM и JOIN clauses
- [x] Обработка алиасов таблиц
- [x] Поддержка schema.table notation
- [x] Нормализация имен (удаление кавычек, uppercase)

#### Этап 4: Извлечение метаданных (интерфейс)
- [x] Класс `TMetadataExtractor` с методами:
  - [x] `ExtractWholeDatabase` - вся БД
  - [x] `ExtractSchema` - конкретная схема
  - [x] `ExtractTables` - выбранные таблицы
  - [x] `ExtractTablesWithRelations` - таблицы + связанные рекурсивно
- [x] Методы для разрешения синонимов
- [x] Запросы к ALL_TABLES, ALL_VIEWS, ALL_SYNONYMS
- [x] Запросы к ALL_TAB_COLUMNS
- [x] Запросы к ALL_CONSTRAINTS
- [x] Запросы к ALL_CONS_COLUMNS (планируется)
- [x] Запросы к ALL_TAB_COMMENTS, ALL_COL_COMMENTS

#### Этап 5: Сериализация
- [x] JSON сериализатор (`uJsonSerializer.pas`):
  - [x] Сериализация модели в JSON
  - [x] Сохранение в файл
  - [x] Загрузка из файла (заготовка)
  - [ ] Десериализация (требуется парсер JSON)
- [x] XML сериализатор (`uXmlSerializer.pas`):
  - [x] Сериализация модели в XML
  - [x] Сохранение в файл
  - [x] Загрузка из файла (заготовка)
  - [ ] Десериализация (требуется парсер XML)

#### Этап 6: Интеграция с PL/SQL Developer
- [x] Главный модуль плагина (`uPluginMain.pas`)
- [x] Реализация API функций:
  - [x] `pdev_init`
  - [x] `pdev_uninit`
  - [x] `pdev_getinfo`
  - [x] `pdev_execute`
- [x] Три режима работы через MenuItem:
  - [x] MODE_WHOLE_DB (0)
  - [x] MODE_SCHEMA (1)
  - [x] MODE_SELECTED_TABLES (2)
- [x] Обработка выделенного текста из редактора

#### Этап 7: OCI реализация
- [x] Класс `TOCILibrary` - загрузка и обертка OCI функций
- [x] Класс `TOCIQueryResult` - обработка результатов запросов
- [x] Класс `TOCIManager` - управление подключением и запросами:
  - [x] Инициализация OCI environment
  - [x] Подключение к базе данных
  - [x] Выполнение SQL запросов
  - [x] Обработка курсоров и результатов
  - [x] Очистка ресурсов
  - [x] Методы для получения таблиц, колонок, ограничений, FK

#### Этап 8: Интерактивная форма диаграммы
- [x] Форма `TERDiagramForm` (`uERDiagramForm.pas` + `uERDiagramForm.dfm`):
  - [x] Форма с TScrollBox/TPaintBox
  - [x] Отрисовка таблиц (заголовки, колонки, PK/FK маркеры)
  - [x] Отрисовка связей (линии между таблицами)
  - [x] Поддержка drag & drop
  - [x] Zoom in/out (колесо мыши + Ctrl, меню, toolbar)
  - [x] Панорамирование (Ctrl + перетаскивание)
  - [x] Контекстное меню
  - [x] Выделение таблиц
  - [x] Экспорт в PNG
  - [x] Toolbar с основными действиями
  - [x] Status bar с информацией о zoom и количестве таблиц

### В разработке (Requires Implementation)

#### Дополнительные возможности
- [ ] Диалог выбора схемы (для MODE_SCHEMA)
- [ ] Диалог подтверждения выбранных таблиц
- [ ] Прогресс-бар для больших моделей
- [ ] Логирование ошибок
- [ ] Десериализация JSON/XML
- [ ] Интеграция с OCI из PL/SQL Developer (использование ConnectionHandle)

### Будущие версии (Post-MVP)

- [ ] Экспорт в PDF
- [ ] Экспорт в Visio VSDX
- [ ] Экспорт в PNG/SVG
- [ ] Генерация DDL из модели
- [ ] Сравнение двух моделей
- [ ] Печать
- [ ] Настройки стилей отображения
- [ ] Поиск по модели
- [ ] Группировка таблиц по схемам

## Структура файлов

```
ERModelBuilder/
├── src/
│   ├── ERModelBuilder.dpr      # Главный файл проекта (DLL entry point)
│   ├── uConstants.pas          # Константы и конфигурация
│   ├── uDataModel.pas          # Классы модели данных
│   ├── uMetadataExtractor.pas  # Извлечение метаданных Oracle
│   ├── uSQLParser.pas          # Парсер SQL текста
│   ├── uJsonSerializer.pas     # JSON сериализация
│   ├── uXmlSerializer.pas      # XML сериализация
│   ├── uPluginMain.pas         # Интеграция с PL/SQL Developer API
│   └── uERDiagramForm.pas      # (TODO) Форма диаграммы
├── docs/
│   └── README.md               # Документация
└── project.json                # Конфигурация проекта
```

## Технические детали

### Oracle Query Templates

```sql
-- Таблицы, представления, синонимы
SELECT OWNER, TABLE_NAME, 'TABLE' as OBJECT_TYPE 
FROM ALL_TABLES WHERE OWNER = :schema
UNION ALL
SELECT OWNER, VIEW_NAME, 'VIEW' as OBJECT_TYPE 
FROM ALL_VIEWS WHERE OWNER = :schema
UNION ALL
SELECT TABLE_OWNER, TABLE_NAME, 'SYNONYM' as OBJECT_TYPE 
FROM ALL_SYNONYMS WHERE OWNER = :schema

-- Колонки
SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, 
       DATA_SCALE, NULLABLE, DATA_DEFAULT, COLUMN_ID
FROM ALL_TAB_COLUMNS
WHERE OWNER = :owner AND TABLE_NAME = :table_name
ORDER BY COLUMN_ID

-- Ограничения
SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE, SEARCH_CONDITION, STATUS
FROM ALL_CONSTRAINTS
WHERE OWNER = :owner AND TABLE_NAME = :table_name

-- Внешние ключи
SELECT FC.CONSTRAINT_NAME, FC.TABLE_NAME as FK_TABLE,
       PC.TABLE_NAME as PK_TABLE, FC.R_OWNER, 
       FC.DELETE_RULE, FC.UPDATE_RULE
FROM ALL_CONSTRAINTS FC
JOIN ALL_CONSTRAINTS PC ON FC.R_CONSTRAINT_NAME = PC.CONSTRAINT_NAME
AND FC.R_OWNER = PC.OWNER
WHERE FC.CONSTRAINT_TYPE = 'R'

-- Колонки ограничений
SELECT CONSTRAINT_NAME, COLUMN_NAME, POSITION
FROM ALL_CONS_COLUMNS
WHERE OWNER = :owner AND TABLE_NAME = :table_name
ORDER BY CONSTRAINT_NAME, POSITION

-- Комментарии
SELECT COMMENTS FROM ALL_TAB_COMMENTS
WHERE OWNER = :owner AND TABLE_NAME = :table_name

SELECT COLUMN_NAME, COMMENTS FROM ALL_COL_COMMENTS
WHERE OWNER = :owner AND TABLE_NAME = :table_name
```

### PL/SQL Developer Plugin API

Плагин экспортирует 4 функции:

```pascal
function pdev_init: Integer; stdcall;
procedure pdev_uninit; stdcall;
function pdev_getinfo: PPDevPluginInfo; stdcall;
procedure pdev_execute(Params: PPDevExecuteParams); stdcall;
```

Параметры выполнения включают:
- `MenuItem` - индекс выбранного пункта меню (0, 1, 2)
- `ConnectionHandle` - OCI подключение к БД
- `DatabaseName` - имя базы данных
- `CurrentSchema` - текущая схема
- `SelectedText` - выделенный текст в редакторе

## Следующие шаги

1. **Протестировать** на реальной БД Oracle
2. **Скомпилировать DLL** и установить в PL/SQL Developer
3. **Реализовать десериализацию** JSON/XML для загрузки моделей
4. **Добавить диалоги** выбора схемы и подтверждения таблиц
5. **Улучшить алгоритм layout** для минимизации пересечений связей

## Замечания

- Десериализация JSON/XML требует парсера (можно использовать SuperObject или встроенный XML parser Delphi)
- Для OCI можно использовать компонентную обертку или прямой API вызов
- Интерактивная диаграмма - наиболее сложная часть, требует работы с GDI+/Direct2D
- Форма диаграммы реализована с базовой функциональностью отрисовки и взаимодействия
