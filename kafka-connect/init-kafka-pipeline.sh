#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Инициализация Kafka Connect Pipeline${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Wait for Kafka Connect to be ready
echo -e "${YELLOW}Шаг 1: Ожидание готовности Kafka Connect...${NC}"
timeout=120
while [ $timeout -gt 0 ]; do
    if curl -s http://localhost:8083/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Kafka Connect готов!${NC}"
        break
    fi
    printf "."
    sleep 3
    timeout=$((timeout - 3))
done

if [ $timeout -le 0 ]; then
    echo -e "${RED}✗ Таймаут ожидания Kafka Connect${NC}"
    exit 1
fi

echo ""

# Wait for ksqlDB to be ready
echo -e "${YELLOW}Шаг 2: Ожидание готовности ksqlDB...${NC}"
timeout=120
while [ $timeout -gt 0 ]; do
    if curl -s http://localhost:8088/info > /dev/null 2>&1; then
        echo -e "${GREEN}✓ ksqlDB готов!${NC}"
        break
    fi
    printf "."
    sleep 3
    timeout=$((timeout - 3))
done

if [ $timeout -le 0 ]; then
    echo -e "${RED}✗ Таймаут ожидания ksqlDB${NC}"
    exit 1
fi

echo ""

# Delete existing connectors if they exist
echo -e "${YELLOW}Шаг 3: Удаление существующих коннекторов (если есть)...${NC}"
curl -s -X DELETE http://localhost:8083/connectors/oracle-source-connector 2>/dev/null || true
curl -s -X DELETE http://localhost:8083/connectors/oracle-source-users 2>/dev/null || true
curl -s -X DELETE http://localhost:8083/connectors/oracle-source-role 2>/dev/null || true
curl -s -X DELETE http://localhost:8083/connectors/oracle-source-grant 2>/dev/null || true
curl -s -X DELETE http://localhost:8083/connectors/postgres-sink-connector 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Готово${NC}"
echo ""

# Register Oracle Source Connectors
echo -e "${YELLOW}Шаг 4: Регистрация Oracle Source Connectors...${NC}"

echo -e "${YELLOW}  4.1: Oracle Users...${NC}"
response=$(curl -s -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @kafka-connect/connectors/oracle-source-users.json)

if echo "$response" | grep -q '"name"'; then
    echo -e "${GREEN}  ✓ Oracle Users Source зарегистрирован!${NC}"
else
    echo -e "${RED}  ✗ Ошибка регистрации Oracle Users Source${NC}"
    echo "$response"
    exit 1
fi

echo -e "${YELLOW}  4.2: Oracle Roles...${NC}"
response=$(curl -s -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @kafka-connect/connectors/oracle-source-role.json)

if echo "$response" | grep -q '"name"'; then
    echo -e "${GREEN}  ✓ Oracle Roles Source зарегистрирован!${NC}"
else
    echo -e "${RED}  ✗ Ошибка регистрации Oracle Roles Source${NC}"
    echo "$response"
    exit 1
fi

echo -e "${YELLOW}  4.3: Oracle Grants...${NC}"
response=$(curl -s -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @kafka-connect/connectors/oracle-source-grant.json)

if echo "$response" | grep -q '"name"'; then
    echo -e "${GREEN}  ✓ Oracle Grants Source зарегистрирован!${NC}"
else
    echo -e "${RED}  ✗ Ошибка регистрации Oracle Grants Source${NC}"
    echo "$response"
    exit 1
fi

echo ""

# Wait for initial data to be captured
echo -e "${YELLOW}Шаг 5: Ожидание захвата данных из Oracle (15 секунд)...${NC}"
sleep 15
echo -e "${GREEN}✓ Данные должны появиться в Kafka${NC}"
echo ""

# Create ksqlDB streams
echo -e "${YELLOW}Шаг 6: Создание ksqlDB streams для обогащения данных...${NC}"

# Drop existing streams if they exist
curl -s -X POST http://localhost:8088/ksql \
  -H "Content-Type: application/vnd.ksql.v1+json" \
  -d '{"ksql": "DROP STREAM IF EXISTS postgres_users_enriched DELETE TOPIC;", "streamsProperties": {}}' > /dev/null 2>&1 || true

curl -s -X POST http://localhost:8088/ksql \
  -H "Content-Type: application/vnd.ksql.v1+json" \
  -d '{"ksql": "DROP TABLE IF EXISTS oracle_users_grant_table DELETE TOPIC;", "streamsProperties": {}}' > /dev/null 2>&1 || true

curl -s -X POST http://localhost:8088/ksql \
  -H "Content-Type: application/vnd.ksql.v1+json" \
  -d '{"ksql": "DROP TABLE IF EXISTS oracle_users_role_table DELETE TOPIC;", "streamsProperties": {}}' > /dev/null 2>&1 || true

curl -s -X POST http://localhost:8088/ksql \
  -H "Content-Type: application/vnd.ksql.v1+json" \
  -d '{"ksql": "DROP STREAM IF EXISTS oracle_users_grant_stream DELETE TOPIC;", "streamsProperties": {}}' > /dev/null 2>&1 || true

curl -s -X POST http://localhost:8088/ksql \
  -H "Content-Type: application/vnd.ksql.v1+json" \
  -d '{"ksql": "DROP STREAM IF EXISTS oracle_users_role_stream DELETE TOPIC;", "streamsProperties": {}}' > /dev/null 2>&1 || true

curl -s -X POST http://localhost:8088/ksql \
  -H "Content-Type: application/vnd.ksql.v1+json" \
  -d '{"ksql": "DROP STREAM IF EXISTS oracle_users_stream DELETE TOPIC;", "streamsProperties": {}}' > /dev/null 2>&1 || true

sleep 5

# Execute ksqlDB setup script line by line
while IFS= read -r line; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*-- ]]; then
        continue
    fi
    
    # Accumulate SQL statement until we hit a semicolon
    statement="$statement $line"
    
    if [[ "$line" =~ \;[[:space:]]*$ ]]; then
        # Execute the complete statement
        curl -s -X POST http://localhost:8088/ksql \
          -H "Content-Type: application/vnd.ksql.v1+json" \
          -d "{\"ksql\": \"$statement\", \"streamsProperties\": {}}" > /dev/null
        statement=""
    fi
done < kafka-connect/ksql-setup.sql

echo -e "${GREEN}✓ ksqlDB streams созданы!${NC}"
echo ""

# Wait for ksqlDB to process data
echo -e "${YELLOW}Шаг 7: Ожидание обработки данных в ksqlDB (20 секунд)...${NC}"
sleep 20
echo -e "${GREEN}✓ Данные обработаны${NC}"
echo ""

# Register PostgreSQL Sink Connector
echo -e "${YELLOW}Шаг 8: Регистрация PostgreSQL Sink Connector...${NC}"
response=$(curl -s -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @kafka-connect/connectors/postgres-sink-connector.json)

if echo "$response" | grep -q '"name"'; then
    echo -e "${GREEN}✓ PostgreSQL Sink Connector зарегистрирован!${NC}"
else
    echo -e "${RED}✗ Ошибка регистрации PostgreSQL Sink Connector${NC}"
    echo "$response"
    exit 1
fi

echo ""

# Check connector status
echo -e "${YELLOW}Шаг 9: Проверка статуса коннекторов...${NC}"
echo ""
echo -e "${GREEN}Oracle Source Connectors:${NC}"
curl -s http://localhost:8083/connectors/oracle-source-users/status | jq '.connector.state, .tasks[0].state' 2>/dev/null || echo "Проверьте вручную"
curl -s http://localhost:8083/connectors/oracle-source-role/status | jq '.connector.state, .tasks[0].state' 2>/dev/null || echo "Проверьте вручную"
curl -s http://localhost:8083/connectors/oracle-source-grant/status | jq '.connector.state, .tasks[0].state' 2>/dev/null || echo "Проверьте вручную"
echo ""
echo -e "${GREEN}PostgreSQL Sink Connector:${NC}"
curl -s http://localhost:8083/connectors/postgres-sink-connector/status | jq '.connector.state, .tasks[0].state' 2>/dev/null || echo "Проверьте вручную"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Инициализация завершена успешно!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Данные из Oracle будут автоматически синхронизироваться в PostgreSQL${NC}"
echo -e "${YELLOW}с правильным маппингом role и grant_field на имена из справочников.${NC}"
echo ""
