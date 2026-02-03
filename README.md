# Service Template ATB

Spring Boot application with dual database support (PostgreSQL and Oracle).

## Быстрый старт

### Запуск приложения одной командой

```bash
make run
```

Эта команда автоматически:

- Проверит Docker и запустит его при необходимости
- Поднимет контейнеры PostgreSQL, Oracle, Kafka, Kafka Connect
- Настроит Oracle для Debezium CDC
- Зарегистрирует Debezium коннекторы
- Соберет приложение
- Запустит Spring Boot приложение
- Откроет Swagger UI в браузере

**Приложение будет доступно по адресу:** http://localhost:8080/swagger-ui/index.html

### Остановка приложения

Для остановки всех контейнеров:

```bash
make stop
```

## Требования

- **Java 17+** (будет установлена автоматически через Makefile на macOS/Linux)
- **Docker** (будет установлен автоматически через Makefile на macOS/Linux)
- **Make** (уже установлен на macOS/Linux)

## Features

- PostgreSQL database with Liquibase migrations
- Oracle database with SQL-based operations (no Liquibase)
- Automatic data initialization on startup
- REST API for managing users, grants, and roles
- Swagger UI для тестирования API
- **Debezium CDC для репликации данных из Oracle в PostgreSQL в реальном времени**
- **Kafka Connect и Kafka для надежной доставки данных**

## 📚 Документация по Kafka Connect

> **⚡ [KAFKA_CONNECT_OPTIONS.md](KAFKA_CONNECT_OPTIONS.md) - Сравнение вариантов репликации (JDBC vs Debezium CDC)**
> 
> **📖 [DEBEZIUM_CDC_GUIDE.md](DEBEZIUM_CDC_GUIDE.md) - Полное руководство по Debezium Oracle CDC**

### Варианты репликации Oracle → PostgreSQL

Проект поддерживает два варианта:

**Вариант 1: Debezium Oracle CDC (РЕКОМЕНДУЕТСЯ) ⭐**
- Читает Oracle redo logs через LogMiner
- Репликация в реальном времени (<1 сек задержка)
- Захватывает все операции: INSERT, UPDATE, DELETE
- Требует настройки Oracle (ARCHIVELOG, supplemental logging)

**Вариант 2: JDBC Source Connector (Простой)**
- Опрашивает таблицы Oracle каждые N секунд
- Проще в настройке, не требует изменений Oracle
- Подходит для dev/test окружения
- Может пропускать UPDATE/DELETE операции

См. [KAFKA_CONNECT_OPTIONS.md](KAFKA_CONNECT_OPTIONS.md) для детального сравнения.

### Архитектура Debezium CDC

```
┌─────────────────────┐
│   Oracle Database   │ (source: redo logs)
│  - ORACLE_USERS     │
│  - ORACLE_USERS_    │
│    ROLE             │
│  - ORACLE_USERS_    │
│    GRANT            │
└──────────┬──────────┘
           │ LogMiner читает redo logs
           ▼
┌─────────────────────┐
│  Kafka Connect      │
│  Debezium Oracle    │
│  Source Connector   │
└──────────┬──────────┘
           │ Change events
           ▼
┌─────────────────────┐
│   Apache Kafka      │
│  Topics:            │
│  - oracle_cdc...    │
│    ORACLE_USERS     │
│  - oracle_cdc...    │
│    ORACLE_USERS_    │
│    ROLE             │
│  - oracle_cdc...    │
│    ORACLE_USERS_    │
│    GRANT            │
└──────────┬──────────┘
           │ Stream processing
           ▼
┌─────────────────────┐
│  Kafka Connect      │
│  JDBC Sink          │
│  Connector          │
└──────────┬──────────┘
           │ Write to target
           ▼
┌─────────────────────┐
│ PostgreSQL Database │ (target)
│  - postgres_users_  │
│    from_debezium    │
└─────────────────────┘
```

**Ключевые особенности:**
- 🔄 **Change Data Capture (CDC)** - Debezium читает redo logs Oracle через LogMiner
- ⚡ **Реальное время** - задержка репликации <1 секунды
- 📊 **Все операции** - захватывает INSERT, UPDATE, DELETE
- 🔒 **Надежность** - гарантированная доставка через Kafka
- 📈 **Масштабируемость** - легко добавить новые таблицы или sink connectors

## Oracle API Endpoints

### Users

- `GET /api/oracle-users` - Get all users
- `GET /api/oracle-users/{id}` - Get user by ID
- `POST /api/oracle-users` - Create new user (via SQL INSERT)
- `PUT /api/oracle-users/{id}` - Update user (via SQL UPDATE)
- `DELETE /api/oracle-users/{id}` - Delete user

### Grants

- `GET /api/oracle-users/grants` - Get all grants
- `GET /api/oracle-users/grants/{id}` - Get grant by ID
- `POST /api/oracle-users/grants` - Create new grant (via SQL INSERT)
- `PUT /api/oracle-users/grants/{id}` - Update grant (via SQL UPDATE)
- `DELETE /api/oracle-users/grants/{id}` - Delete grant

### Roles

- `GET /api/oracle-users/roles` - Get all roles
- `GET /api/oracle-users/roles/{id}` - Get role by ID
- `POST /api/oracle-users/roles` - Create new role (via SQL INSERT)
- `PUT /api/oracle-users/roles/{id}` - Update role (via SQL UPDATE)
- `DELETE /api/oracle-users/roles/{id}` - Delete role

## Тестирование API в Swagger

После запуска приложения откройте Swagger UI: http://localhost:8080/swagger-ui/index.html

### Что можно протестировать:

1. **PostgreSQL Users API** (`/api/postgres-users`)
    - Создание, чтение, обновление, удаление пользователей PostgreSQL

2. **Oracle Users API** (`/api/oracle-users`)
    - Получение списка пользователей Oracle
    - Создание, обновление, удаление пользователей через SQL

3. **Oracle Grants API** (`/api/oracle-users/grants`)
    - Управление правами доступа Oracle пользователей

4. **Oracle Roles API** (`/api/oracle-users/roles`)
    - Управление ролями Oracle пользователей

### Автоматическая инициализация данных

При запуске приложения Oracle база данных автоматически инициализируется тестовыми данными:

- 5 тестовых пользователей с разными датами и полом
- 5 грантов с различными правами доступа
- 5 ролей от базового пользователя до администратора

Скрипт инициализации: `src/main/resources/oracle-init.sql`

Вы можете сразу протестировать GET-запросы на этих данных!

## Доступные команды Makefile

### Основные команды

```bash
make run            # Запустить приложение с PostgreSQL + Oracle + Kafka + Kafka Connect и открыть Swagger
make stop           # Остановить все контейнеры
make help           # Показать все доступные команды
```

### Команды для разработки

```bash
make setup-oracle   # Запустить только инфраструктуру (PostgreSQL + Oracle + Kafka + Kafka Connect)
make build          # Собрать проект
make test           # Запустить тесты
make test-coverage  # Запустить тесты с отчетом о покрытии
make run-local      # Запустить только Spring Boot (инфраструктура должна быть уже запущена)
make clean          # Очистить артефакты сборки
make swagger        # Открыть Swagger UI в браузере
```

### Docker команды

```bash
make docker-up      # Поднять все контейнеры в Docker
make docker-down    # Остановить все контейнеры
make logs           # Показать логи контейнеров
```

### Kafka Connect команды

```bash
make kafka-connect-status   # Проверить статус Kafka Connect и всех коннекторов
make kafka-connect-pause    # Приостановить работу всех коннекторов
make kafka-connect-resume   # Возобновить работу всех коннекторов
make kafka-connect-restart  # Перезапустить Kafka Connect контейнер
```

## Ручной запуск (без Makefile)

Если вы хотите запустить приложение вручную:

### Шаг 1: Запустите всю инфраструктуру

```bash
COMPOSE_PROFILES=dev-oracle docker compose up -d postgres oracle zookeeper kafka kafka-connect
```

### Шаг 2: Дождитесь готовности всех сервисов (3-5 минут)

```bash
docker compose ps
```

Все сервисы должны быть в статусе `healthy`.

### Шаг 3: Запустите приложение

```bash
export ORACLE_DATASOURCE_URL=jdbc:oracle:thin:@localhost:1521/FREEPDB1
export ORACLE_DATASOURCE_USERNAME=oracleuser
export ORACLE_DATASOURCE_PASSWORD=oraclepass
./mvnw spring-boot:run
```

### Шаг 4: Откройте Swagger UI

http://localhost:8080/swagger-ui/index.html

## Configuration

Database connection parameters can be configured via environment variables:

### PostgreSQL

- `POSTGRES_DATASOURCE_URL` (default: `jdbc:postgresql://localhost:5433/mydatabase`)
- `POSTGRES_DATASOURCE_USERNAME` (default: `myuser`)
- `POSTGRES_DATASOURCE_PASSWORD` (default: `secret`)

### Oracle

- `ORACLE_DATASOURCE_URL` (default: `jdbc:oracle:thin:@localhost:1521/FREEPDB1`)
- `ORACLE_DATASOURCE_USERNAME` (default: `oracleuser`)
- `ORACLE_DATASOURCE_PASSWORD` (default: `oraclepass`)

## Troubleshooting

### Oracle долго стартует

Oracle контейнер может запускаться до 2-3 минут при первом запуске. Это нормально.

### Порт 8080 уже занят

Остановите другие приложения на порту 8080 или измените порт в `application.yaml`.

### Docker не запускается автоматически

Запустите Docker Desktop вручную и повторите команду `make run`.

---

## Краткая шпаргалка

### Основные команды

```bash
# Запустить все (включая Kafka Connect) и открыть Swagger
make run

# Остановить все
make stop

# Посмотреть логи
make logs

# Запустить тесты
make test

# Проверить статус Kafka Connect
make kafka-connect-status

# Приостановить Kafka Connect
make kafka-connect-pause

# Возобновить Kafka Connect
make kafka-connect-resume
```

### Debezium Oracle CDC (рекомендуется для production)

```bash
# 1. Запустить инфраструктуру
docker compose --profile dev-oracle up -d

# 2. Настроить Oracle для CDC
./kafka-connect/setup-oracle-for-debezium.sh

# 3. Зарегистрировать Debezium коннекторы
./kafka-connect/register-debezium-connectors.sh

# 4. Проверить статус
curl http://localhost:8083/connectors/debezium-oracle-source-connector/status | jq

# 5. Тестировать репликацию
docker exec -it service-template-atb-oracle sqlplus oracleuser/oraclepass@//localhost:1521/FREEPDB1
# INSERT INTO oracle_users VALUES (100, 'Test CDC', SYSDATE, 'M', 1, 1); COMMIT;

docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT * FROM postgres.postgres_users_from_debezium WHERE id = 100;"
```

### JDBC Source Connector (простой вариант для dev/test)

```bash
# 1. Запустить инфраструктуру
docker compose --profile dev-oracle up -d

# 2. Зарегистрировать JDBC коннекторы
./kafka-connect/register-connectors.sh
```

**Swagger UI:** http://localhost:8080/swagger-ui/index.html
**Kafka Connect REST API:** http://localhost:8083

---

## Kafka Connect - Синхронизация данных из Oracle в PostgreSQL

Проект включает настроенный Kafka Connect для автоматической синхронизации данных из Oracle в PostgreSQL.

> **📖 [KAFKA_CONNECT_GUIDE.md](KAFKA_CONNECT_GUIDE.md) - Подробное руководство по Kafka Connect**

### Быстрое управление Kafka Connect

После запуска `make run` все компоненты Kafka Connect будут автоматически запущены. Используйте следующие команды для
управления:

```bash
# Проверить статус Kafka Connect и всех коннекторов
make kafka-connect-status

# Приостановить синхронизацию данных (остановить все коннекторы)
make kafka-connect-pause

# Возобновить синхронизацию данных (запустить все коннекторы)
make kafka-connect-resume

# Перезапустить Kafka Connect (если возникли проблемы)
make kafka-connect-restart
```

### Архитектура потока данных

```
Oracle DB (oracle_users, oracle_users_role, oracle_users_grant)
    ↓
Debezium Oracle Source Connector → Kafka Topics
    ↓
JDBC Sink Connector → PostgreSQL (postgres_users_from_debezium)
```

### Маппинг полей

Данные из Oracle трансформируются следующим образом:

| Oracle Source                 | PostgreSQL Target            | Преобразование      |
|-------------------------------|------------------------------|---------------------|
| `oracle_users.name`           | `postgres_users.name`        | Прямое копирование  |
| `oracle_users.birth_date_ora` | `postgres_users.birth_date`  | Переименование поля |
| `oracle_users.sex`            | `postgres_users.gender`      | Переименование поля |
| `oracle_users_role.name`      | `postgres_users.role`        | JOIN по `role_id`   |
| `oracle_users_grant.name`     | `postgres_users.grant_field` | JOIN по `grant_id`  |

### Запуск Kafka Connect

1. **Запустите все сервисы с профилем dev-oracle:**

```bash
docker compose --profile dev-oracle up -d
```

Это запустит:

- PostgreSQL
- Oracle
- Zookeeper
- Kafka
- Kafka Connect
- Application

2. **Дождитесь готовности всех сервисов (3-5 минут)**

Проверить статус можно командой:

```bash
docker compose ps
```

Все сервисы должны быть в статусе `healthy`.

3. **Настройте Oracle для Debezium CDC:**

```bash
./kafka-connect/setup-oracle-for-debezium.sh
```

4. **Зарегистрируйте Debezium коннекторы:**

```bash
./kafka-connect/register-debezium-connectors.sh
```

5. **Проверьте статус коннекторов:**

```bash
# Список всех коннекторов
curl http://localhost:8083/connectors

# Статус Debezium Oracle Source Connector
curl http://localhost:8083/connectors/debezium-oracle-source-connector/status

# Статус PostgreSQL Sink Connector
curl http://localhost:8083/connectors/debezium-postgres-sink-connector/status
```

### Мониторинг потока данных

**Проверка топиков Kafka:**

```bash
docker exec -it service-template-atb-kafka kafka-topics --bootstrap-server localhost:9092 --list
```

**Чтение сообщений из топика:**

```bash
# Топик с пользователями Oracle (Debezium CDC)
docker exec -it service-template-atb-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic oracle_cdc.oracle_cdc.ORACLEUSER.ORACLE_USERS \
  --from-beginning
```

**Проверка данных в PostgreSQL:**

```bash
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase -c "SELECT * FROM postgres.postgres_users_from_debezium;"
```

### Тестирование синхронизации

1. **Добавьте нового пользователя в Oracle:**

```bash
docker exec -it service-template-atb-oracle sqlplus oracleuser/oraclepass@//localhost:1521/FREEPDB1

INSERT INTO oracle_users (name, birth_date_ora, sex, role_id, grant_id) 
VALUES ('Test User', TO_DATE('2000-01-01', 'YYYY-MM-DD'), 'M', 1, 1);
COMMIT;
```

2. **Проверьте, что данные появились в PostgreSQL:**

```bash
docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase \
  -c "SELECT * FROM postgres.postgres_users_from_debezium WHERE id = 100;"
```

Данные должны синхронизироваться автоматически в течение нескольких секунд.

### Управление коннекторами

**С помощью Makefile (рекомендуется):**

```bash
# Проверить статус всех коннекторов
make kafka-connect-status

# Приостановить работу всех коннекторов
make kafka-connect-pause

# Возобновить работу всех коннекторов
make kafka-connect-resume

# Перезапустить Kafka Connect
make kafka-connect-restart
```

**Вручную через REST API:**

**Остановить коннектор:**

```bash
curl -X PUT http://localhost:8083/connectors/debezium-oracle-source-connector/pause
```

**Запустить коннектор:**

```bash
curl -X PUT http://localhost:8083/connectors/debezium-oracle-source-connector/resume
```

**Удалить коннектор:**

```bash
curl -X DELETE http://localhost:8083/connectors/debezium-oracle-source-connector
```

**Обновить конфигурацию:**

```bash
curl -X PUT http://localhost:8083/connectors/debezium-oracle-source-connector/config \
  -H "Content-Type: application/json" \
  -d @kafka-connect/connectors/debezium-oracle-source-connector.json
```

### Полезные ссылки

- **Kafka Connect REST API:** http://localhost:8083
- **Конфигурация коннекторов:** `kafka-connect/connectors/`
- **Скрипты настройки:** `kafka-connect/setup-oracle-for-debezium.sh`, `kafka-connect/register-debezium-connectors.sh`

### Troubleshooting

**Коннектор в статусе FAILED:**

```bash
curl http://localhost:8083/connectors/debezium-oracle-source-connector/status | jq '.tasks[0].trace'
```

**Данные не попадают в PostgreSQL:**

- Убедитесь, что Oracle настроен для CDC (ARCHIVELOG, supplemental logging)
- Проверьте топик `oracle_cdc.oracle_cdc.ORACLEUSER.ORACLE_USERS` на наличие сообщений
- Проверьте логи PostgreSQL Sink Connector
- Используйте `make kafka-connect-status` для проверки статуса коннекторов
