# Debezium Oracle CDC Connector - Руководство

## Обзор

Этот проект использует **Debezium Oracle CDC Connector** для репликации данных из Oracle Database XE в PostgreSQL в реальном времени
через Kafka.

## Используемые версии

- **Oracle Database**: Oracle XE (gvenzl/oracle-xe:latest-faststart)
- **Debezium Oracle Connector**: 2.7.3.Final
- **Kafka**: 7.5.0 (Confluent Platform)
- **JDBC Driver**: ojdbc8 21.9.0.0

### Преимущества gvenzl/oracle-xe:latest-faststart

- Быстрый запуск (~30 секунд вместо 2-3 минут)
- Не требует аутентификации в Oracle Container Registry
- Меньше требований к ресурсам
- Идеально подходит для разработки и тестирования
- Полностью совместим с Debezium CDC

### Архитектура

```
Oracle (redo logs) 
    ↓
Debezium Oracle Source Connector (LogMiner)
    ↓
Kafka Topics
    ↓
JDBC Sink Connector
    ↓
PostgreSQL
```

## Быстрый старт

### 1. Запустите инфраструктуру

```bash
docker compose --profile dev-oracle up -d
```

Это запустит:

- PostgreSQL
- Oracle
- Zookeeper
- Kafka
- Kafka Connect (с Debezium плагином)

### 2. Дождитесь готовности Oracle (2-3 минуты)

```bash
docker compose ps
```

Все сервисы должны быть в статусе `healthy`.

### 3. Настройте Oracle для CDC

```bash
./kafka-connect/setup-oracle-for-debezium.sh
```

Этот скрипт:

- Включает supplemental logging
- Выдает необходимые права для LogMiner
- Настраивает таблицы для CDC

### 4. Зарегистрируйте Debezium коннекторы

```bash
./kafka-connect/register-debezium-connectors.sh
```

Это создаст:

- Debezium Oracle Source Connector (читает redo logs)
- JDBC Sink Connector (пишет в PostgreSQL)

### 5. Проверьте статус

```bash
curl http://localhost:8083/connectors/debezium-oracle-source-connector/status | jq
```

## Мониторинг и отладка

### Проверка Kafka топиков

```bash
# Список всех топиков
docker exec -it service-template-atb-kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --list

# Чтение сообщений из топика Oracle Users
docker exec -it service-template-atb-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic oracle_cdc.oracle_cdc.ORACLEUSER.ORACLE_USERS \
  --from-beginning
```

### Проверка данных в PostgreSQL

```bash
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT * FROM postgres.postgres_users_from_debezium LIMIT 10;"
```

### Логи Kafka Connect

```bash
docker logs -f service-template-atb-kafka-connect
```

### Статус коннекторов

```bash
# Список всех коннекторов
curl http://localhost:8083/connectors | jq

# Статус Oracle Source
curl http://localhost:8083/connectors/debezium-oracle-source-connector/status | jq

# Статус PostgreSQL Sink
curl http://localhost:8083/connectors/debezium-postgres-sink-connector/status | jq
```

## Тестирование CDC

### Тест 1: INSERT

```sql
-- В Oracle
docker exec -it service-template-atb-oracle sqlplus oracleuser/oraclepass@//localhost:1521/XEPDB1

INSERT INTO oracle_users (id, name, birth_date_ora, sex, role_id, grant_id) 
VALUES (100, 'CDC Test User', SYSDATE, 'M', 1, 1);
COMMIT;
```

```bash
# Проверка в PostgreSQL (через несколько секунд)
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT * FROM postgres.postgres_users_from_debezium WHERE id = 100;"
```

### Тест 2: UPDATE

```sql
-- В Oracle
UPDATE oracle_users
SET name = 'CDC Updated User'
WHERE id = 100;
COMMIT;
```

```bash
# Проверка в PostgreSQL
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT * FROM postgres.postgres_users_from_debezium WHERE id = 100;"
```

### Тест 3: DELETE

```sql
-- В Oracle
DELETE
FROM oracle_users
WHERE id = 100;
COMMIT;
```

```bash
# Проверка в PostgreSQL
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT * FROM postgres.postgres_users_from_debezium WHERE id = 100;"
```

## Управление коннекторами

### Остановить коннектор

```bash
curl -X PUT http://localhost:8083/connectors/debezium-oracle-source-connector/pause
```

### Запустить коннектор

```bash
curl -X PUT http://localhost:8083/connectors/debezium-oracle-source-connector/resume
```

### Перезапустить коннектор

```bash
curl -X POST http://localhost:8083/connectors/debezium-oracle-source-connector/restart
```

### Удалить коннектор

```bash
curl -X DELETE http://localhost:8083/connectors/debezium-oracle-source-connector
```

## Настройки Debezium

### Конфигурация Oracle Source Connector

Файл: `kafka-connect/connectors/debezium-oracle-source-connector.json`

Ключевые параметры:

```json
{
  "connector.class": "io.debezium.connector.oracle.OracleConnector",
  "database.connection.adapter": "logminer",
  "snapshot.mode": "initial",
  "log.mining.strategy": "online_catalog",
  "table.include.list": "ORACLEUSER.ORACLE_USERS,..."
}
```

### Конфигурация PostgreSQL Sink Connector

Файл: `kafka-connect/connectors/debezium-postgres-sink-connector.json`

```json
{
  "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
  "insert.mode": "upsert",
  "pk.mode": "record_key"
}
```

## Требования Oracle для Debezium

### 1. Archive Log Mode

Debezium требует, чтобы Oracle работал в режиме ARCHIVELOG.

Проверка:

```sql
SELECT LOG_MODE
FROM V$DATABASE;
```

Включение (требует рестарт БД):

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

### 2. Supplemental Logging

Должно быть включено на уровне БД и таблиц:

```sql
-- Database level
ALTER
DATABASE ADD SUPPLEMENTAL LOG DATA;
ALTER
DATABASE ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;

-- Table level
ALTER TABLE oracle_users
    ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
```

### 3. LogMiner Privileges

Пользователь должен иметь права на LogMiner:

```sql
GRANT LOGMINING TO oracleuser;
GRANT EXECUTE ON DBMS_LOGMNR TO oracleuser;
GRANT SELECT ON V_$LOGMNR_CONTENTS TO oracleuser;
-- ... и другие (см. setup-oracle-for-debezium.sh)
```

## Топология Kafka топиков

Debezium создает следующие топики:

| Топик                                                 | Описание                                   |
|-------------------------------------------------------|--------------------------------------------|
| `oracle_cdc.oracle_cdc.ORACLEUSER.ORACLE_USERS`       | CDC события для таблицы ORACLE_USERS       |
| `oracle_cdc.oracle_cdc.ORACLEUSER.ORACLE_USERS_ROLE`  | CDC события для таблицы ORACLE_USERS_ROLE  |
| `oracle_cdc.oracle_cdc.ORACLEUSER.ORACLE_USERS_GRANT` | CDC события для таблицы ORACLE_USERS_GRANT |
| `schema-changes.oracle`                               | История изменений схемы БД                 |

## Troubleshooting

### Проблема: Connector в статусе FAILED

**Решение:**

```bash
# Проверить детали ошибки
curl http://localhost:8083/connectors/debezium-oracle-source-connector/status | jq '.tasks[0].trace'

# Проверить логи
docker logs service-template-atb-kafka-connect | grep -i error
```

### Проблема: Oracle не в режиме ARCHIVELOG

**Ошибка:**

```
ORA-00257: archiver error. Connect internal only, until freed.
```

**Решение:**

Включите ARCHIVELOG mode (см. выше).

### Проблема: Supplemental logging не включен

**Ошибка:**

```
Supplemental logging not properly configured
```

**Решение:**

```bash
./kafka-connect/setup-oracle-for-debezium.sh
```

### Проблема: Не хватает прав LogMiner

**Ошибка:**

```
ORA-00942: table or view does not exist
```

**Решение:**

Запустите скрипт настройки Oracle:

```bash
./kafka-connect/setup-oracle-for-debezium.sh
```

## Производительность

### LogMiner настройки

В `debezium-oracle-source-connector.json`:

```json
{
  "log.mining.batch.size.default": "1000",
  "log.mining.sleep.time.default.ms": "1000",
  "log.mining.sleep.time.min.ms": "1000",
  "log.mining.sleep.time.max.ms": "3000"
}
```

- `batch.size`: размер пакета для чтения из redo logs
- `sleep.time`: интервал между проверками новых изменений

### Мониторинг задержки

```bash
# Проверить offset lag
docker exec -it service-template-atb-kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --describe \
  --group connect-debezium-postgres-sink-connector
```

## Сравнение с JDBC Source Connector

| Характеристика     | JDBC Source                   | Debezium CDC                     |
|--------------------|-------------------------------|----------------------------------|
| Метод чтения       | Polling таблиц                | Чтение redo logs                 |
| Задержка           | 5+ секунд                     | <1 секунда                       |
| Нагрузка на БД     | Высокая (SELECT каждые N сек) | Низкая (только redo logs)        |
| Захват DELETE      | Нет                           | Да                               |
| Захват UPDATE      | Частично                      | Полностью                        |
| Начальная загрузка | По ID                         | Snapshot + CDC                   |
| Требования к БД    | Нет                           | ARCHIVELOG, Supplemental logging |

## Альтернативные варианты

### Вариант 1: Debezium + ksqlDB (для JOIN)

Если нужно объединять данные из нескольких таблиц Oracle в одну таблицу PostgreSQL, можно использовать ksqlDB:

```
Oracle → Debezium → Kafka → ksqlDB (JOIN) → Kafka → JDBC Sink → PostgreSQL
```

Этот вариант полезен для денормализации данных.

### Вариант 2: Debezium + Kafka Streams

Для более сложной обработки данных можно использовать Kafka Streams вместо ksqlDB.

### Вариант 3: Только JDBC Source (без CDC)

Если CDC не требуется (нет строгих требований к задержке), можно оставить JDBC Source Connector. Он проще в настройке,
но менее надежен.

## Полезные ссылки

- [Debezium Oracle Connector Documentation](https://debezium.io/documentation/reference/stable/connectors/oracle.html)
- [Kafka Connect JDBC Sink](https://docs.confluent.io/kafka-connect-jdbc/current/sink-connector/index.html)
- [Oracle LogMiner Guide](https://docs.oracle.com/en/database/oracle/oracle-database/19/sutil/oracle-logminer-utility.html)

## Краткая шпаргалка

```bash
# Полный запуск с Debezium
docker compose --profile dev-oracle up -d
./kafka-connect/setup-oracle-for-debezium.sh
./kafka-connect/register-debezium-connectors.sh

# Проверка статуса
curl http://localhost:8083/connectors | jq

# Чтение из Kafka
docker exec -it service-template-atb-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic oracle_cdc.oracle_cdc.ORACLEUSER.ORACLE_USERS \
  --from-beginning

# Проверка в PostgreSQL
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT COUNT(*) FROM postgres.postgres_users_from_debezium;"

# Остановка
docker compose --profile dev-oracle down
```
