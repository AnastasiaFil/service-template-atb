# Kafka Connect - Краткое руководство

## Быстрый старт

### Запуск

```bash
make run
```

Эта команда запустит всё окружение, включая:

- PostgreSQL
- Oracle
- Kafka
- Kafka Connect
- ksqlDB
- Spring Boot приложение

### Управление Kafka Connect

| Команда                      | Описание                                                |
|------------------------------|---------------------------------------------------------|
| `make kafka-connect-status`  | Показать статус Kafka Connect и всех коннекторов        |
| `make kafka-connect-pause`   | Приостановить синхронизацию (остановить все коннекторы) |
| `make kafka-connect-resume`  | Возобновить синхронизацию (запустить все коннекторы)    |
| `make kafka-connect-restart` | Перезапустить Kafka Connect контейнер                   |

## Примеры использования

### Проверка статуса коннекторов

```bash
make kafka-connect-status
```

Вывод покажет:

- Статус Kafka Connect
- Список всех зарегистрированных коннекторов
- Детальный статус каждого коннектора (RUNNING, PAUSED, FAILED)

### Приостановка синхронизации

Если вам нужно временно остановить синхронизацию данных из Oracle в PostgreSQL:

```bash
make kafka-connect-pause
```

Это остановит все коннекторы, но не удалит их конфигурацию.

### Возобновление синхронизации

Для возобновления работы коннекторов:

```bash
make kafka-connect-resume
```

Все коннекторы продолжат синхронизацию с того места, где остановились.

### Перезапуск Kafka Connect

Если возникли проблемы с Kafka Connect:

```bash
make kafka-connect-restart
```

Это перезапустит контейнер Kafka Connect и автоматически дождётся его готовности.

## Архитектура

```
Oracle DB
    ↓ (Debezium Oracle Source Connector)
Kafka Topics
    ↓ (ksqlDB Stream Processing)
PostgreSQL
    ↓ (JDBC Sink Connector)
PostgreSQL
```

### Коннекторы

1. **oracle-source-connector** - Читает изменения из Oracle DB (CDC)
2. **postgres-sink-connector** - Записывает данные в PostgreSQL

### Топики Kafka

- `oracle.ORACLEUSER.ORACLE_USERS` - Пользователи Oracle
- `oracle.ORACLEUSER.ORACLE_USERS_ROLE` - Роли пользователей
- `oracle.ORACLEUSER.ORACLE_USERS_GRANT` - Гранты пользователей
- `postgres_users_enriched` - Обогащённые данные для PostgreSQL (после JOIN в ksqlDB)

## Мониторинг

### Проверка топиков Kafka

```bash
docker exec -it service-template-atb-kafka kafka-topics --bootstrap-server localhost:9092 --list
```

### Чтение сообщений из топика

```bash
# Топик с пользователями Oracle
docker exec -it service-template-atb-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic oracle.ORACLEUSER.ORACLE_USERS \
  --from-beginning
```

### Проверка данных в PostgreSQL

```bash
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT * FROM postgres.postgres_users;"
```

## Тестирование синхронизации

### 1. Добавьте данные в Oracle

```bash
docker exec -it service-template-atb-oracle sqlplus oracleuser/oraclepass@//localhost:1521/FREEPDB1
```

```sql
INSERT INTO oracle_users (name, birth_date_ora, sex, role_id, grant_id)
VALUES ('Test User', TO_DATE('2000-01-01', 'YYYY-MM-DD'), 'M', 1, 1);
COMMIT;
```

### 2. Проверьте данные в PostgreSQL

```bash
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT * FROM postgres.postgres_users WHERE name = 'Test User';"
```

Данные должны появиться в течение нескольких секунд.

## Troubleshooting

### Коннектор в статусе FAILED

Проверьте логи ошибок:

```bash
curl http://localhost:8083/connectors/oracle-source-connector/status | jq '.tasks[0].trace'
```

### Данные не синхронизируются

1. Проверьте статус коннекторов:
   ```bash
   make kafka-connect-status
   ```

2. Проверьте логи Kafka Connect:
   ```bash
   docker logs service-template-atb-kafka-connect -f
   ```

3. Убедитесь, что ksqlDB streams созданы:
   ```bash
   docker exec -it service-template-atb-ksqldb-cli ksql http://ksqldb-server:8088
   ```
   ```sql
   SHOW STREAMS;
   ```

### Kafka Connect не запускается

Перезапустите контейнер:

```bash
make kafka-connect-restart
```

Если проблема сохраняется, проверьте логи:

```bash
docker logs service-template-atb-kafka-connect
```

## REST API Endpoints

Kafka Connect предоставляет REST API на порту 8083:

| Endpoint                                         | Метод  | Описание                   |
|--------------------------------------------------|--------|----------------------------|
| `http://localhost:8083/`                         | GET    | Информация о Kafka Connect |
| `http://localhost:8083/connectors`               | GET    | Список коннекторов         |
| `http://localhost:8083/connectors/{name}/status` | GET    | Статус коннектора          |
| `http://localhost:8083/connectors/{name}/pause`  | PUT    | Приостановить коннектор    |
| `http://localhost:8083/connectors/{name}/resume` | PUT    | Возобновить коннектор      |
| `http://localhost:8083/connectors/{name}`        | DELETE | Удалить коннектор          |

### Примеры использования REST API

```bash
# Список коннекторов
curl http://localhost:8083/connectors

# Статус коннектора
curl http://localhost:8083/connectors/oracle-source-connector/status | jq

# Приостановить коннектор
curl -X PUT http://localhost:8083/connectors/oracle-source-connector/pause

# Возобновить коннектор
curl -X PUT http://localhost:8083/connectors/oracle-source-connector/resume
```

## Полезные ссылки

- **Kafka Connect REST API:** http://localhost:8083
- **ksqlDB Server:** http://localhost:8088
- **Конфигурация коннекторов:** `kafka-connect/connectors/`
- **ksqlDB скрипты:** `kafka-connect/ksql-setup.sql`
- **Debezium Oracle Connector Docs:** https://debezium.io/documentation/reference/stable/connectors/oracle.html
- **Confluent JDBC Sink Connector Docs:
  ** https://docs.confluent.io/kafka-connectors/jdbc/current/sink-connector/index.html
