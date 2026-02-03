#!/bin/bash

# ===================================================================
# Register Debezium Oracle CDC Connector and JDBC Sink Connector
# ===================================================================

set -e

KAFKA_CONNECT_URL="http://localhost:8083"
CONNECTORS_DIR="kafka-connect/connectors"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "======================================================================"
echo "  Debezium Oracle CDC Connector Setup"
echo "======================================================================"
echo ""

# Function to wait for Kafka Connect
wait_for_kafka_connect() {
    echo -e "${YELLOW}Waiting for Kafka Connect to be ready...${NC}"
    local retries=0
    local max_retries=60
    
    while ! curl -s "${KAFKA_CONNECT_URL}" > /dev/null; do
        retries=$((retries + 1))
        if [ $retries -ge $max_retries ]; then
            echo -e "${RED}Error: Kafka Connect did not become ready in time${NC}"
            exit 1
        fi
        echo "Still waiting... (attempt $retries/$max_retries)"
        sleep 5
    done
    
    echo -e "${GREEN}✓ Kafka Connect is ready!${NC}"
    echo ""
}

# Function to delete connector if exists
delete_connector_if_exists() {
    local connector_name=$1
    echo -e "${YELLOW}Checking if connector '${connector_name}' exists...${NC}"
    
    if curl -s "${KAFKA_CONNECT_URL}/connectors/${connector_name}" > /dev/null 2>&1; then
        echo -e "${YELLOW}Deleting existing connector '${connector_name}'...${NC}"
        curl -X DELETE "${KAFKA_CONNECT_URL}/connectors/${connector_name}"
        echo ""
        sleep 2
        echo -e "${GREEN}✓ Deleted existing connector${NC}"
    else
        echo -e "${GREEN}✓ No existing connector found${NC}"
    fi
    echo ""
}

# Function to register connector
register_connector() {
    local config_file=$1
    local connector_name=$(jq -r '.name' "$config_file")
    
    echo "----------------------------------------------------------------------"
    echo -e "${YELLOW}Registering connector: ${connector_name}${NC}"
    echo "----------------------------------------------------------------------"
    
    delete_connector_if_exists "$connector_name"
    
    echo -e "${YELLOW}Posting connector configuration...${NC}"
    
    response=$(curl -s -X POST "${KAFKA_CONNECT_URL}/connectors" \
      -H "Content-Type: application/json" \
      -d @"$config_file")
    
    if echo "$response" | jq -e '.name' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Connector '${connector_name}' registered successfully!${NC}"
    else
        echo -e "${RED}✗ Failed to register connector '${connector_name}'${NC}"
        echo "Response: $response"
        return 1
    fi
    
    echo ""
}

# Function to check connector status
check_connector_status() {
    local connector_name=$1
    echo -e "${YELLOW}Status of '${connector_name}':${NC}"
    curl -s "${KAFKA_CONNECT_URL}/connectors/${connector_name}/status" | jq '.'
    echo ""
}

# Main execution
main() {
    wait_for_kafka_connect
    
    echo "======================================================================"
    echo "  Step 1: Register Debezium Oracle Source Connector"
    echo "======================================================================"
    echo ""
    
    register_connector "${CONNECTORS_DIR}/debezium-oracle-source-connector.json"
    
    echo "----------------------------------------------------------------------"
    echo -e "${YELLOW}Waiting 10 seconds for initial snapshot to complete...${NC}"
    echo "----------------------------------------------------------------------"
    sleep 10
    echo ""
    
    echo "======================================================================"
    echo "  Step 2: Register PostgreSQL Sink Connector"
    echo "======================================================================"
    echo ""
    
    register_connector "${CONNECTORS_DIR}/debezium-postgres-sink-connector.json"
    
    echo "======================================================================"
    echo "  Connector Status Summary"
    echo "======================================================================"
    echo ""
    
    check_connector_status "debezium-oracle-source-connector"
    check_connector_status "debezium-postgres-sink-connector"
    
    echo "======================================================================"
    echo -e "${GREEN}✓ All connectors registered successfully!${NC}"
    echo "======================================================================"
    echo ""
    echo "Next steps:"
    echo "  1. Check Kafka topics: docker exec -it service-template-atb-kafka kafka-topics --list --bootstrap-server localhost:9092"
    echo "  2. Monitor connector logs: docker logs -f service-template-atb-kafka-connect"
    echo "  3. View data in PostgreSQL: docker exec -it service-template-atb-postgres psql -U myuser -d mydatabase"
    echo ""
}

main "$@"
