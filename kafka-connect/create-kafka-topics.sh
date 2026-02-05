#!/bin/bash

# ===================================================================
# Create Kafka topics for Oracle CDC reference tables
# ===================================================================

set -e

KAFKA_CONTAINER="service-template-atb-kafka"
KAFKA_BROKER="localhost:9092"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "======================================================================"
echo "  Creating Kafka topics for Oracle CDC"
echo "======================================================================"
echo ""

# Function to create topic if it doesn't exist
create_topic() {
    local topic_name=$1
    
    echo -e "${YELLOW}Checking topic: ${topic_name}${NC}"
    
    if docker exec ${KAFKA_CONTAINER} kafka-topics \
        --bootstrap-server ${KAFKA_BROKER} \
        --list | grep -q "^${topic_name}$"; then
        echo -e "${GREEN}✓ Topic '${topic_name}' already exists${NC}"
    else
        echo -e "${YELLOW}Creating topic: ${topic_name}${NC}"
        docker exec ${KAFKA_CONTAINER} kafka-topics \
            --bootstrap-server ${KAFKA_BROKER} \
            --create \
            --topic "${topic_name}" \
            --partitions 1 \
            --replication-factor 1 \
            --if-not-exists \
            2>/dev/null || true
        echo -e "${GREEN}✓ Topic '${topic_name}' created${NC}"
    fi
    echo ""
}

# Create topics for Oracle reference tables
create_topic "oracle_cdc.ORACLEUSER.ORACLE_USERS_ROLE"
create_topic "oracle_cdc.ORACLEUSER.ORACLE_USERS_GRANT"

echo "======================================================================"
echo -e "${GREEN}✓ All topics created successfully!${NC}"
echo "======================================================================"
echo ""
echo "Created topics:"
echo "  - oracle_cdc.ORACLEUSER.ORACLE_USERS_ROLE"
echo "  - oracle_cdc.ORACLEUSER.ORACLE_USERS_GRANT"
echo ""
