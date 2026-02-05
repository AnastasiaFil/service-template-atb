#!/bin/bash

# ===================================================================
# Register PostgreSQL enriched sink connector
# ===================================================================

set -e

KAFKA_CONNECT_URL="http://localhost:8083"
CONNECTOR_NAME="postgres-enriched-sink-connector"
CONNECTOR_CONFIG="kafka-connect/connectors/postgres-enriched-sink-connector.json"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "======================================================================"
echo "  Registering PostgreSQL Enriched Sink Connector"
echo "======================================================================"
echo ""

# Check if Kafka Connect is available
echo -e "${YELLOW}Checking Kafka Connect availability...${NC}"
if ! curl -s "${KAFKA_CONNECT_URL}/" >/dev/null 2>&1; then
    echo -e "${RED}✗ Kafka Connect is not available at ${KAFKA_CONNECT_URL}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Kafka Connect is available${NC}"
echo ""

# Delete existing connector if it exists
echo -e "${YELLOW}Checking for existing connector...${NC}"
if curl -s "${KAFKA_CONNECT_URL}/connectors" | grep -q "\"${CONNECTOR_NAME}\""; then
    echo -e "${YELLOW}Deleting existing connector: ${CONNECTOR_NAME}${NC}"
    curl -s -X DELETE "${KAFKA_CONNECT_URL}/connectors/${CONNECTOR_NAME}" >/dev/null
    sleep 2
    echo -e "${GREEN}✓ Existing connector deleted${NC}"
fi
echo ""

# Register new connector
echo -e "${YELLOW}Registering connector: ${CONNECTOR_NAME}${NC}"
response=$(curl -s -X POST "${KAFKA_CONNECT_URL}/connectors" \
    -H "Content-Type: application/json" \
    -d @"${CONNECTOR_CONFIG}")

if echo "$response" | grep -q "\"name\""; then
    echo -e "${GREEN}✓ Connector registered successfully${NC}"
    echo ""
    echo -e "${YELLOW}Connector configuration:${NC}"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
else
    echo -e "${RED}✗ Failed to register connector${NC}"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    exit 1
fi

echo ""
echo "======================================================================"
echo -e "${GREEN}✓ PostgreSQL Enriched Sink Connector registered!${NC}"
echo "======================================================================"
echo ""
echo "Check connector status:"
echo "  curl http://localhost:8083/connectors/${CONNECTOR_NAME}/status | jq ."
echo ""
