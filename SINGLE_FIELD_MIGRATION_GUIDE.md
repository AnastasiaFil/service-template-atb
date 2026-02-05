# Руководство по маппингу полей role и grant_field

## Резюме

✅ **Проблема решена:** Поля `role` и `grant_field` в таблице `postgres.postgres_users` автоматически мапятся на значения из справочников Oracle:
- `postgres_users.role` ← `oracle_users_role.name` (через `oracle_users.role_id`)
- `postgres_users.grant_field` ← `oracle_users_grant.name` (через `oracle_users.grant_id`)

## Архитектура решения

```
Oracle DB (источник)
  ├── oracle_users (id, name, role_id, grant_id)
  ├── oracle_users_role (id, name)
  └── oracle_users_grant (id, name)
       ↓
Debezium CDC → Kafka Topics
  ├── oracle_cdc.ORACLEUSER.ORACLE_USERS
  ├── oracle_cdc.ORACLEUSER.ORACLE_USERS_ROLE
  └── oracle_cdc.ORACLEUSER.ORACLE_USERS_GRANT
       ↓
ksqlDB (обогащение через JOIN)
  ├── Streams: oracle_users_stream, oracle_users_role_stream, oracle_users_grant_stream
  ├── Tables: oracle_users_role_table, oracle_users_grant_table
  └── Enriched Stream: postgres_users_enriched (с полями role и grant_field)
       ↓
Kafka Connect (JDBC Sink с Avro)
       ↓
PostgreSQL (целевая БД)
  └── postgres.postgres_users (id, name, birth_date, gender, role, grant_field)
```

## Ключевые компоненты

### 1. Kafka топики для справочников
Созданы топики для таблиц-справочников (автоматически при запуске):
- `oracle_cdc.ORACLEUSER.ORACLE_USERS_ROLE`
- `oracle_cdc.ORACLEUSER.ORACLE_USERS_GRANT`

**Скрипт:** `kafka-connect/create-kafka-topics.sh`

### 2. ksqlDB обогащение
Создан enriched stream с JOIN для получения имен ролей и грантов:

```sql
CREATE STREAM postgres_users_enriched WITH (
  VALUE_FORMAT='AVRO'
) AS
SELECT
  u.payload->after->ID AS id,
  u.payload->after->NAME AS name,
  u.payload->after->BIRTH_DATE_ORA AS birth_date,
  u.payload->after->SEX AS gender,
  r.NAME AS role,           -- маппинг на oracle_users_role.name
  g.NAME AS grant_field     -- маппинг на oracle_users_grant.name
FROM oracle_users_stream u
LEFT JOIN oracle_users_role_table r ON u.payload->after->ROLE_ID = r.ID
LEFT JOIN oracle_users_grant_table g ON u.payload->after->GRANT_ID = g.ID
WHERE u.payload->after IS NOT NULL;
```

**Конфигурация:** `kafka-connect/ksqldb/create-enriched-stream.sql`

### 3. PostgreSQL Sink Connector с Avro
Коннектор читает обогащенный stream и записывает в PostgreSQL:

**Конфигурация:** `kafka-connect/connectors/postgres-enriched-sink-connector.json`

Ключевые параметры:
- `value.converter`: `io.confluent.connect.avro.AvroConverter` (для работы со схемой)
- `value.converter.schema.registry.url`: `http://schema-registry:8081`
- `insert.mode`: `upsert` (вставка и обновление)
- `pk.mode`: `record_value`, `pk.fields`: `id`

## Запуск системы

### Полный автоматический запуск
```bash
make run-ksqldb
```

Эта команда автоматически:
1. Запускает всю инфраструктуру (PostgreSQL, Oracle, Kafka, Schema Registry, Kafka Connect, ksqlDB)
2. Настраивает Oracle для Debezium CDC
3. Регистрирует Debezium source коннектор
4. Создает Kafka топики для справочников
5. Настраивает ksqlDB streams и tables
6. Регистрирует PostgreSQL sink коннектор
7. Запускает Spring Boot приложение

### Пошаговый запуск

1. **Запустить инфраструктуру:**
```bash
make setup-oracle
```

2. **Настроить Oracle и зарегистрировать Debezium:**
```bash
./kafka-connect/setup-oracle-for-debezium.sh
./kafka-connect/register-debezium-connectors.sh
```

3. **Создать топики и настроить ksqlDB:**
```bash
./kafka-connect/create-kafka-topics.sh
./kafka-connect/setup-ksqldb-streams.sh
```

4. **Зарегистрировать sink коннектор:**
```bash
./kafka-connect/register-enriched-sink-connector.sh
```

## Проверка работы

### 1. Проверить статус коннекторов
```bash
make kafka-connect-status
```

### 2. Проверить ksqlDB streams
```bash
make ksqldb-status
```

### 3. Проверить данные в PostgreSQL
```bash
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT id, name, role, grant_field FROM postgres.postgres_users ORDER BY id;"
```

Ожидаемый результат:
```
 id |      name      |     role      |  grant_field
----+----------------+---------------+----------------
  1 | Ivan Petrov    | USER          | READ_ACCESS
  2 | Maria Sidorova | DEVELOPER     | WRITE_ACCESS
  3 | Alexey Ivanov  | ANALYST       | DELETE_ACCESS
  4 | Elena Volkova  | MANAGER       | EXECUTE_ACCESS
  5 | Dmitry Sokolov | ADMINISTRATOR | ADMIN_ACCESS
```

### 4. Проверить автоматическое обновление

Измените данные в Oracle:
```bash
docker exec service-template-atb-oracle bash -c "
sqlplus -S oracleuser/oraclepass@//localhost:1521/XEPDB1 <<EOF
UPDATE oracleuser.oracle_users SET role_id = 3, grant_id = 4 WHERE id = 1;
COMMIT;
EXIT;
EOF
"
```

Подождите 5-10 секунд и проверьте PostgreSQL:
```bash
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT id, name, role, grant_field FROM postgres.postgres_users WHERE id = 1;"
```

Результат должен показать обновленные значения:
```
 id |    name     |  role   |  grant_field
----+-------------+---------+----------------
  1 | Ivan Petrov | ANALYST | EXECUTE_ACCESS
```

## Важные файлы

| Файл | Назначение |
|------|-----------|
| `kafka-connect/create-kafka-topics.sh` | Создание топиков для справочников |
| `kafka-connect/ksqldb/create-enriched-stream.sql` | SQL для создания enriched stream |
| `kafka-connect/setup-ksqldb-streams.sh` | Скрипт настройки ksqlDB |
| `kafka-connect/connectors/postgres-enriched-sink-connector.json` | Конфигурация sink коннектора |
| `kafka-connect/register-enriched-sink-connector.sh` | Скрипт регистрации sink коннектора |

## Требования

- **Schema Registry** - обязательно для работы с Avro форматом
- **ksqlDB Server** - для обогащения данных через JOIN
- **Kafka Connect** - с плагинами:
  - Debezium Oracle Connector
  - Confluent JDBC Sink Connector
  - Confluent Avro Converter

## Troubleshooting

### Проблема: Поля role и grant_field пустые

**Решение:**
1. Проверьте, что топики созданы:
```bash
docker exec service-template-atb-kafka kafka-topics --bootstrap-server localhost:9092 --list | grep oracle_cdc
```

2. Проверьте ksqlDB streams:
```bash
make ksqldb-status
```

3. Проверьте статус sink коннектора:
```bash
curl -s http://localhost:8083/connectors/postgres-enriched-sink-connector/status | jq .
```

### Проблема: Connector в статусе FAILED

**Причины:**
- Отсутствует Schema Registry
- Неправильный формат данных (не Avro)
- Ошибка подключения к PostgreSQL

**Решение:**
Проверьте логи:
```bash
docker logs service-template-atb-kafka-connect --tail 100
```

### Проблема: Данные не обновляются

**Решение:**
1. Триггерните UPDATE в Oracle для создания CDC события
2. Проверьте, что Debezium source коннектор работает:
```bash
curl -s http://localhost:8083/connectors/debezium-oracle-source-connector/status | jq .
```

## Преимущества решения

✅ **Полностью автоматическое** - изменения в Oracle автоматически попадают в PostgreSQL
✅ **Real-time** - минимальная задержка (секунды)
✅ **Масштабируемое** - использует Kafka для буферизации
✅ **Отказоустойчивое** - Kafka Connect автоматически восстанавливается после сбоев
✅ **Только через коннекторы** - без триггеров, view или дополнительных таблиц в PostgreSQL
✅ **Типизированные данные** - использование Avro обеспечивает контроль схемы

## Ограничения

- Требуется Schema Registry (уже есть в вашей инфраструктуре)
- Начальная загрузка данных требует триггера UPDATE в Oracle (snapshot.mode=schema_only)
- Для работы ksqlDB JOIN требуются данные в справочных таблицах (role, grant)
