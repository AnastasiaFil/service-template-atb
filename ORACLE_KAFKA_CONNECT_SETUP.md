# Требования к настройке Oracle Database для интеграции с Kafka Connect

## Назначение документа

Данный документ содержит перечень необходимых настроек Oracle Database для обеспечения передачи данных в Kafka Connect
через механизм Change Data Capture (CDC) с использованием Debezium Oracle Connector.

---

## 1. Включение режима ARCHIVELOG

**Назначение:** Режим ARCHIVELOG обеспечивает сохранение архивных журналов транзакций, которые необходимы для
отслеживания изменений данных в режиме реального времени.

**Действия:**

```sql
SHUTDOWN
IMMEDIATE;
STARTUP
MOUNT;
ALTER
DATABASE ARCHIVELOG;
ALTER
DATABASE OPEN;
```

**Проверка текущего статуса:**

```sql
SELECT LOG_MODE
FROM V$DATABASE;
```

Ожидаемый результат: `ARCHIVELOG`

---

## 2. Включение дополнительного логирования (Supplemental Logging)

**Назначение:** Supplemental Logging добавляет в журналы транзакций дополнительную информацию о изменениях данных (
включая значения первичных ключей и всех колонок), что необходимо для корректной репликации изменений.

**Действия:**

```sql
-- Минимальное дополнительное логирование (обязательно)
ALTER
DATABASE ADD SUPPLEMENTAL LOG DATA;

-- Логирование PRIMARY KEY (обязательно)
ALTER
DATABASE ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;

-- Логирование всех колонок (для таблиц без PK, если применимо)
ALTER
DATABASE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
```

**Проверка статуса:**

```sql
SELECT SUPPLEMENTAL_LOG_DATA_MIN,
       SUPPLEMENTAL_LOG_DATA_PK,
       SUPPLEMENTAL_LOG_DATA_ALL
FROM V$DATABASE;
```

---

## 3. Создание выделенного пользователя для Kafka Connect

**Назначение:** Создание отдельного пользователя с минимально необходимыми правами для работы Kafka Connect обеспечивает
безопасность и изоляцию доступа.

**Действия:**

```sql
-- Создание пользователя
CREATE
USER debezium_user IDENTIFIED BY <strong_password>;

-- Базовые привилегии
GRANT CREATE
SESSION TO debezium_user;

-- Для Multitenant архитектуры (CDB/PDB)
GRANT SET
CONTAINER TO debezium_user;
```

---

## 4. Выдача прав на системные представления

**Назначение:** Права на системные представления необходимы для мониторинга состояния базы данных и работы механизма
LogMiner.

**Действия:**

```sql
GRANT SELECT ON V_$DATABASE TO debezium_user;
GRANT SELECT ON V_$LOG TO debezium_user;
GRANT SELECT ON V_$LOG_HISTORY TO debezium_user;
GRANT SELECT ON V_$LOGMNR_LOGS TO debezium_user;
GRANT SELECT ON V_$LOGMNR_CONTENTS TO debezium_user;
GRANT SELECT ON V_$LOGMNR_PARAMETERS TO debezium_user;
GRANT SELECT ON V_$LOGFILE TO debezium_user;
GRANT SELECT ON V_$ARCHIVED_LOG TO debezium_user;
GRANT SELECT ON V_$ARCHIVE_DEST_STATUS TO debezium_user;
GRANT SELECT ON DBA_TABLESPACES TO debezium_user;
GRANT SELECT ON DBA_OBJECTS TO debezium_user;
GRANT SELECT ON DBA_USERS TO debezium_user;
```

---

## 5. Выдача прав на работу с LogMiner

**Назначение:** LogMiner — это встроенный механизм Oracle для анализа журналов транзакций и извлечения информации об
изменениях данных. Это ключевой компонент для реализации CDC.

**Действия:**

```sql
-- Права на выполнение процедур LogMiner
GRANT EXECUTE ON DBMS_LOGMNR TO debezium_user;
GRANT EXECUTE ON DBMS_LOGMNR_D TO debezium_user;

-- Для Oracle 12c и выше
GRANT LOGMINING TO debezium_user;

-- Системные привилегии для доступа к транзакциям
GRANT
SELECT ANY TRANSACTION TO debezium_user;
```

---

## 6. Выдача прав на целевые таблицы

**Назначение:** Права на чтение таблиц необходимы для создания начального snapshot и отслеживания изменений в целевых
таблицах.

**Действия:**

**Вариант A (рекомендуемый): Выдача прав на конкретные таблицы**

```sql
GRANT
SELECT
ON < schema_name >.<table_name_1> TO debezium_user;
GRANT
SELECT
ON < schema_name >.<table_name_2> TO debezium_user;
-- повторить для всех таблиц
```

**Вариант B: Выдача прав на все таблицы (если таблиц много)**

```sql
GRANT
SELECT ANY TABLE TO debezium_user;
```

---

## 7. Выдача прав для Flashback Query

**Назначение:** Flashback Query позволяет создавать консистентный snapshot данных на определенный момент времени, что
критично для начальной загрузки данных без блокировок.

**Действия:**

**Вариант A (рекомендуемый): Для конкретных таблиц**

```sql
GRANT
FLASHBACK
ON <schema_name>.<table_name_1> TO debezium_user;
GRANT FLASHBACK
ON <schema_name>.<table_name_2> TO debezium_user;
-- повторить для всех таблиц
```

**Вариант B: Для всех таблиц**

```sql
GRANT
FLASHBACK
ANY TABLE TO debezium_user;
```

---

## 8. Настройка для Multitenant архитектуры (CDB/PDB)

**Назначение:** Для Oracle 12c+ с Pluggable Database требуется дополнительная настройка прав на уровне контейнеров.

**Действия (если используется PDB):**

```sql
-- Переключение на PDB
ALTER
SESSION SET CONTAINER = <PDB_NAME>;

-- Создание Common User (имя должно начинаться с C##)
CREATE
USER C#
#debezium_user
IDENTIFIED
BY
<
strong_password
>
CONTAINER
=
ALL;

-- Базовые привилегии
GRANT
CREATE
SESSION TO C#
#debezium_user
CONTAINER
=
ALL;
GRANT
SET
CONTAINER TO C#
#debezium_user
CONTAINER
=
ALL;

-- Повторить все гранты из пунктов 4-7 для C##debezium_user
```

---

## 9. Проверка итоговой конфигурации

**Назначение:** Финальная проверка всех выполненных настроек.

**Проверочные команды:**

```sql
-- Проверка ARCHIVELOG
SELECT LOG_MODE
FROM V$DATABASE;
-- Ожидаемый результат: ARCHIVELOG

-- Проверка Supplemental Logging
SELECT SUPPLEMENTAL_LOG_DATA_MIN,
       SUPPLEMENTAL_LOG_DATA_PK,
       SUPPLEMENTAL_LOG_DATA_ALL
FROM V$DATABASE;
-- Ожидаемый результат: MIN=YES, PK=YES, ALL=YES (опционально)

-- Проверка прав пользователя
SELECT *
FROM DBA_SYS_PRIVS
WHERE GRANTEE = 'DEBEZIUM_USER';
SELECT *
FROM DBA_TAB_PRIVS
WHERE GRANTEE = 'DEBEZIUM_USER';

-- Проверка доступности LogMiner
SELECT *
FROM V$LOGMNR_CONTENTS
WHERE ROWNUM = 1;
```

---

## Сводная таблица обязательных и рекомендуемых настроек

| №  | Настройка                              | Статус           | Критичность                                     |
|----|----------------------------------------|------------------|-------------------------------------------------|
| 1  | Режим ARCHIVELOG                       | **ОБЯЗАТЕЛЬНО**  | Критично: без этого CDC не работает             |
| 2  | Supplemental Logging (MIN + PK)        | **ОБЯЗАТЕЛЬНО**  | Критично: необходимо для отслеживания изменений |
| 3  | Supplemental Logging (ALL)             | Рекомендуется    | Требуется для таблиц без PK                     |
| 4  | Создание выделенного пользователя      | **ОБЯЗАТЕЛЬНО**  | Критично: для безопасности и изоляции           |
| 5  | Права на системные представления (V$*) | **ОБЯЗАТЕЛЬНО**  | Критично: для работы LogMiner                   |
| 6  | Права на DBMS_LOGMNR                   | **ОБЯЗАТЕЛЬНО**  | Критично: для работы LogMiner                   |
| 7  | Права LOGMINING (Oracle 12c+)          | **ОБЯЗАТЕЛЬНО**  | Критично для Oracle 12c+                        |
| 8  | Права SELECT на целевые таблицы        | **ОБЯЗАТЕЛЬНО**  | Критично: для чтения данных                     |
| 9  | Права FLASHBACK                        | **ОБЯЗАТЕЛЬНО**  | Критично: для консистентного snapshot           |
| 10 | Настройка для Multitenant (CDB/PDB)    | По необходимости | Обязательно только для Multitenant архитектуры  |
| 11 | Размер Redo Log >= 500MB               | Рекомендуется    | Повышает производительность                     |
| 12 | Минимум 3 Redo Log группы              | Рекомендуется    | Предотвращает блокировки                        |

---

## Рекомендации

### Производительность:

- **Размер Redo Log файлов:** Рекомендуется минимум 500MB для каждой группы Redo Log, чтобы избежать частых переключений
  и повысить производительность
- **Количество Redo Log групп:** Минимум 3 группы, оптимально 4-5 для высоконагруженных систем
- **Мониторинг:** Настроить мониторинг размера архивных логов и своевременную очистку старых архивов

### Безопасность:

- Использовать сложный пароль для пользователя `debezium_user`
- Выдавать права только на конкретные таблицы (избегать SELECT ANY TABLE, если возможно)
- Регулярно проверять и аудировать выданные права

### Эксплуатация:

- Запланировать технологическое окно для включения ARCHIVELOG (требуется перезапуск БД)
- Убедиться в наличии достаточного дискового пространства для архивных логов (минимум 20-30% от размера БД)
- Настроить автоматическую очистку старых архивных логов через RMAN

### Для Multitenant архитектуры:

- При использовании PDB создавать Common User (C##) с правами CONTAINER=ALL
- Убедиться, что все настройки применены на уровне нужного контейнера (PDB)

