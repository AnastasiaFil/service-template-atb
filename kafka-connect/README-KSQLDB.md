# Oracle CDC to PostgreSQL with ksqlDB Data Enrichment

## Обзор

Этот проект реализует CDC (Change Data Capture) из Oracle в PostgreSQL с обогащением данных через ksqlDB.

### Архитектура

```
Oracle Tables (3 tables)
    ↓
Debezium Oracle Source Connector (LogMiner)
    ↓
Kafka Topics (3 topics)
    ↓
ksqlDB (JOIN tables)
    ↓
Kafka Enriched Topic (1 topic)
    ↓
JDBC Sink Connector
    ↓
PostgreSQL (postgres.postgres_users)
```

### Маппинг полей

| PostgreSQL поле | Источник Oracle | Описание |
|----------------|-----------------|----------|
| `id` | auto-generated | SERIAL, генерируется в PostgreSQL |
| `name` | `oracle_users.name` | Имя пользователя |
| `birth_date` | `oracle_users.birth_date_ora` | Дата рождения |
| `gender` | `oracle_users.sex` | Пол |
| `role` | `oracle_users_role.name` | Название роли (через JOIN) |
| `grant_field` | `oracle_users_grant.name` | Название гранта (через JOIN) |

## Быстрый старт

### 1. Запустите инфраструктуру

```bash
docker compose --profile dev-oracle up -d
```

Будут запущены:
- PostgreSQL
- Oracle XE
- Zookeeper
- Kafka
- Kafka Connect
- ksqlDB Server
- ksqlDB CLI
- Schema Registry

### 2. Дождитесь готовности всех сервисов

```bash
docker compose ps
```

Все сервисы должны быть в статусе `healthy`.

### 3. Настройте Oracle для CDC

```bash
./kafka-connect/setup-oracle-for-debezium.sh
```

### 4. Зарегистрируйте Debezium source connector

```bash
./kafka-connect/register-debezium-connectors.sh
```

Это создаст Debezium Oracle Source Connector, который будет читать из трех таблиц:
- `oracle_users`
- `oracle_users_role`
- `oracle_users_grant`

### 5. Настройте ksqlDB streams и tables

```bash
./kafka-connect/setup-ksqldb-streams.sh
```

Этот скрипт:
- Создает STREAMs для трех топиков Kafka
- Создает TABLEs для `oracle_users_role` и `oracle_users_grant`
- Выполняет LEFT JOIN для создания обогащенного стрима `postgres_users_enriched`

### 6. Зарегистрируйте sink connector

```bash
./kafka-connect/register-enriched-sink-connector.sh
```

Это создаст JDBC Sink Connector для записи обогащенных данных в PostgreSQL.

### 7. Проверьте данные в PostgreSQL

```bash
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT * FROM postgres.postgres_users;"
```

## Мониторинг

### Проверка Kafka топиков

```bash
# Список топиков
docker exec -it service-template-atb-kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --list

# Чтение из обогащенного топика
docker exec -it service-template-atb-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic postgres_users_enriched \
  --from-beginning
```

### Проверка ksqlDB

```bash
# Подключение к ksqlDB CLI
docker exec -it service-template-atb-ksqldb-cli ksql http://ksqldb-server:8088

# В ksqlDB CLI:
SHOW STREAMS;
SHOW TABLES;
SHOW QUERIES;

# Просмотр данных из обогащенного стрима
SELECT * FROM postgres_users_enriched EMIT CHANGES;
```

### Проверка статуса коннекторов

```bash
# Список коннекторов
curl http://localhost:8083/connectors | jq

# Статус source connector
curl http://localhost:8083/connectors/debezium-oracle-source-connector/status | jq

# Статус sink connector
curl http://localhost:8083/connectors/postgres-enriched-sink-connector/status | jq
```

### Логи сервисов

```bash
# Kafka Connect
docker logs -f service-template-atb-kafka-connect

# ksqlDB Server
docker logs -f service-template-atb-ksqldb-server

# Kafka
docker logs -f service-template-atb-kafka
```

## Тестирование CDC

### Тест 1: INSERT в Oracle

```bash
docker exec -it service-template-atb-oracle sqlplus oracleuser/oraclepass@//localhost:1521/XEPDB1
```

```sql
INSERT INTO oracle_users (name, birth_date_ora, sex, role_id, grant_id) 
VALUES ('Test User', SYSDATE, 'M', 1, 1);
COMMIT;
```

Проверка в PostgreSQL (через несколько секунд):

```bash
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT * FROM postgres.postgres_users WHERE name = 'Test User';"
```

### Тест 2: UPDATE в Oracle

```sql
UPDATE oracle_users
SET name = 'Updated Test User'
WHERE name = 'Test User';
COMMIT;
```

### Тест 3: UPDATE роли в Oracle

```sql
-- Изменение названия роли
UPDATE oracle_users_role
SET name = 'SUPER_USER'
WHERE id = 1;
COMMIT;
```

После коммита изменения должны автоматически применитьс к всем пользователям с `role_id = 1`.

### Тест 4: DELETE в Oracle

```sql
DELETE FROM oracle_users
WHERE name = 'Updated Test User';
COMMIT;
```

**Примечание:** DELETE не будет отражаться в PostgreSQL, так как используется `insert.mode=insert` в sink connector. Для поддержки DELETE нужно изменить на `upsert` mode и настроить tombstone events.

## ksqlDB Запросы

### Создание стримов и таблиц

Файл: `kafka-connect/ksqldb/create-enriched-stream.sql`

Основные компоненты:

1. **Стримы** - для чтения из Kafka топиков
   - `oracle_users_stream`
   - `oracle_users_role_stream`
   - `oracle_users_grant_stream`

2. **Таблицы** - для JOIN операций (keyed by ID)
   - `oracle_users_role_table`
   - `oracle_users_grant_table`

3. **Обогащенный стрим** - результат JOIN
   - `postgres_users_enriched`

### Пример JOIN запроса

```sql
CREATE STREAM postgres_users_enriched AS
SELECT
  u.NAME AS name,
  u.BIRTH_DATE_ORA AS birth_date,
  u.SEX AS gender,
  r.NAME AS role,
  g.NAME AS grant_field
FROM oracle_users_stream u
LEFT JOIN oracle_users_role_table r ON u.ROLE_ID = r.ID
LEFT JOIN oracle_users_grant_table g ON u.GRANT_ID = g.ID
EMIT CHANGES;
```

## Структура файлов

```
kafka-connect/
├── connectors/
│   ├── debezium-oracle-source-connector.json    # Source connector для Oracle
│   └── postgres-enriched-sink-connector.json    # Sink connector для PostgreSQL
├── ksqldb/
│   └── create-enriched-stream.sql               # ksqlDB запросы для JOIN
├── setup-oracle-for-debezium.sh                 # Настройка Oracle для CDC
├── register-debezium-connectors.sh              # Регистрация source connector
├── setup-ksqldb-streams.sh                      # Настройка ksqlDB streams
├── register-enriched-sink-connector.sh          # Регистрация sink connector
└── README-KSQLDB.md                             # Эта инструкция
```

## Troubleshooting

### Проблема: ksqlDB не может прочитать топики

**Решение:**
1. Проверьте, что Debezium connector создал топики:
```bash
docker exec -it service-template-atb-kafka kafka-topics --list --bootstrap-server localhost:9092 | grep oracle_cdc
```

2. Проверьте формат данных в топиках:
```bash
docker exec -it service-template-atb-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic oracle_cdc.oracle_cdc.ORACLEUSER.ORACLE_USERS \
  --from-beginning \
  --max-messages 1
```

### Проблема: JOIN не возвращает данные

**Причина:** Таблицы в ksqlDB должны быть заполнены до того, как придут данные в стрим.

**Решение:**
1. Убедитесь, что в Oracle есть данные в таблицах `oracle_users_role` и `oracle_users_grant`
2. Пересоздайте стримы после заполнения справочников
3. Используйте `snapshot.mode=initial` в source connector

### Проблема: Дата birth_date не конвертируется правильно

**Решение:**
Проверьте трансформацию в sink connector:

```json
"transforms": "convertEpochToDate",
"transforms.convertEpochToDate.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value",
"transforms.convertEpochToDate.field": "birth_date",
"transforms.convertEpochToDate.target.type": "Date"
```

### Проблема: Нет данных в PostgreSQL

**Проверка:**

1. Статус sink connector:
```bash
curl http://localhost:8083/connectors/postgres-enriched-sink-connector/status | jq
```

2. Данные в обогащенном топике:
```bash
docker exec -it service-template-atb-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic postgres_users_enriched \
  --from-beginning
```

3. Логи Kafka Connect:
```bash
docker logs service-template-atb-kafka-connect | grep -i error
```

## Остановка и очистка

### Остановка всех сервисов

```bash
docker compose --profile dev-oracle down
```

### Полная очистка (включая данные)

```bash
docker compose --profile dev-oracle down -v
```

Это удалит все volumes с данными PostgreSQL, Oracle и Kafka.

## Преимущества решения с ksqlDB

1. **Без изменений в Oracle** - не требуется создавать VIEW или триггеры
2. **Декларативный подход** - JOIN выражается в SQL-like синтаксисе
3. **Масштабируемость** - ksqlDB автоматически масштабируется с Kafka
4. **Реактивность** - изменения в справочниках (role, grant) автоматически применяются
5. **Мониторинг** - встроенные метрики и возможность отладки через ksqlDB CLI

## Альтернативные решения

Если ksqlDB не подходит, рассмотрите:

1. **Kafka Streams приложение** - больше контроля, требует код на Java/Kotlin
2. **Spring Boot Kafka Listener** - проще интеграция, но нужен сервис для JOIN
3. **PostgreSQL triggers** - JOIN после INSERT в PostgreSQL
4. **Oracle VIEW** - требует изменения в Oracle (не рекомендуется)

## Полезные ссылки

- [ksqlDB Documentation](https://docs.ksqldb.io/)
- [ksqlDB Joins](https://docs.ksqldb.io/en/latest/developer-guide/joins/)
- [Debezium Oracle Connector](https://debezium.io/documentation/reference/stable/connectors/oracle.html)
- [Confluent JDBC Sink Connector](https://docs.confluent.io/kafka-connect-jdbc/current/sink-connector/index.html)
