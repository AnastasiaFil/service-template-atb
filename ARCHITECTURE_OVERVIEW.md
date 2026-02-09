# Архитектура репликации данных Oracle → PostgreSQL

## Описание

Эта система автоматически реплицирует данные из Oracle в PostgreSQL в реальном времени. Когда в Oracle добавляется,
изменяется или удаляется запись, эти изменения автоматически попадают в PostgreSQL через несколько секунд.

Используется технология Change Data Capture (CDC), которая отслеживает все изменения в исходной базе данных Oracle и
передает их через Kafka в целевую базу PostgreSQL с промежуточной обработкой и обогащением данных через ksqlDB.

## Архитектура

```
┌─────────────────────────────────────────────────────────┐
│              Oracle Database                            │
│  Таблицы:                                               │
│  - ORACLE_USERS         (пользователи)                  │
│  - ORACLE_USERS_ROLE    (роли пользователей)            │
│  - ORACLE_USERS_GRANT   (права доступа)                 │
└───────────────────────┬─────────────────────────────────┘
                        │
                        │ Debezium читает журнал изменений
                        │ Oracle (redo logs через LogMiner)
                        ▼
┌─────────────────────────────────────────────────────────┐
│     Kafka Connect + Debezium Oracle Connector           │
│     (устанавливается как сервис)                        │
│                                                         │
│  Что делает:                                            │
│  - Отслеживает все изменения в Oracle                   │
│  - Фиксирует INSERT, UPDATE, DELETE операции            │
│  - Отправляет изменения в Kafka                         │
└───────────────────────┬─────────────────────────────────┘
                        │
                        │ Поток событий изменений
                        ▼
┌─────────────────────────────────────────────────────────┐
│            Apache Kafka                                 │
│  Топики (очереди сообщений):                            │
│  - oracle_cdc.ORACLEUSER.ORACLE_USERS                   │
│  - oracle_cdc.ORACLEUSER.ORACLE_USERS_ROLE              │
│  - oracle_cdc.ORACLEUSER.ORACLE_USERS_GRANT             │
└───────────────────────┬─────────────────────────────────┘
                        │
                        │ Чтение потоков данных
                        ▼
┌─────────────────────────────────────────────────────────┐
│            ksqlDB Server                                │
│            (устанавливается как сервис)                 │
│                                                         │
│  Что делает:                                            │
│  - Читает данные из трех топиков Kafka                  │
│  - Объединяет (JOIN) данные:                            │
│    * пользователи + роли                                │
│    * пользователи + права доступа                       │
│  - Создает обогащенную (денормализованную) таблицу      │
│  - Записывает результат в новый топик Kafka             │
└───────────────────────┬─────────────────────────────────┘
                        │
                        │ Обогащенные данные
                        ▼
┌─────────────────────────────────────────────────────────┐
│               Kafka Topic                               │
│               postgres_users_enriched                   │
│                                                         │
│  Содержит готовые данные:                               │
│  (id, name, birth_date, gender, role, grant_field)      │
└───────────────────────┬─────────────────────────────────┘
                        │
                        │ Чтение обогащенных данных
                        ▼
┌─────────────────────────────────────────────────────────┐
│        Kafka Connect + JDBC Sink Connector              │
│        (тот же Kafka Connect - отдельный не нужен)      │
│                                                         │
│  Что делает:                                            │
│  - Читает обогащенные данные из Kafka                   │
│  - Преобразует форматы (переименовывает поля,           │
│    конвертирует даты)                                   │
│  - Записывает данные в PostgreSQL                       │
│  - Использует UPSERT (обновляет или добавляет)          │
└───────────────────────┬─────────────────────────────────┘
                        │
                        │ Запись в целевую БД
                        ▼
┌─────────────────────────────────────────────────────────┐
│              PostgreSQL Database                        │
│                                                         │
│  Таблица: postgres.postgres_users                       │
│  Содержит денормализованные данные:                     │
│  (id, name, birth_date, gender, role, grant_field)      │
└─────────────────────────────────────────────────────────┘
```

## Что нужно установить/настроить

### ✅ Уже есть в банке (использовать существующие)

1. **Oracle Database** - база данных источник
2. **Apache Kafka** - шина сообщений для передачи данных
3. **Zookeeper** - служба координации для Kafka (обычно идет вместе с Kafka)
4. **PostgreSQL Database** - целевая база данных

### 📦 Нужно установить как новые сервисы

| Сервис              | Образ Docker                            | Порт | Назначение                                            |
|---------------------|-----------------------------------------|------|-------------------------------------------------------|
| **kafka-connect**   | `confluentinc/cp-kafka-connect:7.5.0`   | 8083 | Коннекторы для чтения из Oracle и записи в PostgreSQL |
| **ksqldb-server**   | `confluentinc/ksqldb-server:0.29.0`     | 8088 | Обработка потоков и JOIN данных                       |
| **schema-registry** | `confluentinc/cp-schema-registry:7.5.0` | 8081 | Управление схемами данных (нужен для ksqlDB)          |

### ⚙️ Нужно только настроить (донастройка)

1. **Oracle Database**
    - Включить режим ARCHIVELOG
    - Включить supplemental logging
    - Создать пользователя для Debezium с правами на чтение логов
    - **Скрипт:** `kafka-connect/setup-oracle-for-debezium.sh`

2. **Kafka Connect**
    - Зарегистрировать Debezium Oracle Source Connector
    - Зарегистрировать JDBC Sink Connector
    - **Скрипты:**
        - `kafka-connect/register-debezium-connectors.sh`
        - `kafka-connect/register-enriched-sink-connector.sh`

3. **ksqlDB**
    - Создать streams и tables для обработки данных
    - Настроить JOIN операции
    - **Скрипт:** `kafka-connect/setup-ksqldb-streams.sh`

4. **PostgreSQL**
    - Создать схему и таблицу для целевых данных
    - Настроить права доступа для Kafka Connect
    - **SQL скрипт:** создается автоматически через Liquibase миграции

## Что происходит при изменении данных

### Пример: Добавление нового пользователя

```
1. Пользователь добавляется в Oracle:
   INSERT INTO ORACLE_USERS VALUES (100, 'Иван Иванов', '1990-01-01', 'M', 1, 2);

2. Debezium видит изменение в redo log (< 1 сек)

3. Событие отправляется в Kafka топик oracle_cdc.ORACLEUSER.ORACLE_USERS

4. ksqlDB читает событие и делает JOIN:
   - Берет role_id = 1 → ищет в ORACLE_USERS_ROLE → получает "Admin"
   - Берет grant_id = 2 → ищет в ORACLE_USERS_GRANT → получает "ReadWrite"

5. ksqlDB отправляет обогащенные данные в топик postgres_users_enriched:
   {id: 100, name: "Иван Иванов", birth_date: "1990-01-01", 
    gender: "M", role: "Admin", grant_field: "ReadWrite"}

6. JDBC Sink Connector читает из топика и записывает в PostgreSQL

7. В таблице postgres.postgres_users появляется новая запись (< 1 сек от начала)
```

## Мониторинг и управление

### Проверка статуса коннекторов

```bash
curl http://localhost:8083/connectors
curl http://localhost:8083/connectors/debezium-oracle-source-connector/status
curl http://localhost:8083/connectors/postgres-enriched-sink-connector/status
```

### Просмотр данных в Kafka

```bash
# Список топиков
docker exec -it kafka kafka-topics --bootstrap-server localhost:9092 --list

# Просмотр сообщений
docker exec -it kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic oracle_cdc.ORACLEUSER.ORACLE_USERS \
  --from-beginning
```

### Управление ksqlDB

```bash
# Подключиться к CLI
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088

# Команды внутри CLI:
SHOW STREAMS;     # Показать все потоки
SHOW TABLES;      # Показать все таблицы
SHOW QUERIES;     # Показать активные запросы
```

## Поддержка и документация

- **Полное руководство по Debezium CDC:** `DEBEZIUM_CDC_GUIDE.md`
- **Сравнение вариантов репликации:** `KAFKA_CONNECT_OPTIONS.md`
- **Конфигурация коннекторов:** `kafka-connect/connectors/`
- **Скрипты настройки:** `kafka-connect/*.sh`