#!/bin/bash

# Script to restart Kafka Connect connectors with updated configuration

KAFKA_CONNECT_URL="http://localhost:8083"

echo "==================================================="
echo "Restarting Kafka Connect Connectors"
echo "==================================================="

# Function to check if Kafka Connect is ready
check_connect_ready() {
    echo "Checking if Kafka Connect is ready..."
    while ! curl -s ${KAFKA_CONNECT_URL} > /dev/null; do
        echo "Waiting for Kafka Connect to be ready..."
        sleep 2
    done
    echo "✓ Kafka Connect is ready"
}

# Function to delete connector
delete_connector() {
    local connector_name=$1
    echo ""
    echo "Deleting connector: ${connector_name}"
    curl -X DELETE ${KAFKA_CONNECT_URL}/connectors/${connector_name} 2>/dev/null
    echo "✓ Connector ${connector_name} deleted (or didn't exist)"
}

# Function to create connector
create_connector() {
    local config_file=$1
    local connector_name=$(jq -r '.name' ${config_file})
    echo ""
    echo "Creating connector: ${connector_name}"
    response=$(curl -s -X POST ${KAFKA_CONNECT_URL}/connectors \
        -H "Content-Type: application/json" \
        -d @${config_file})
    
    if echo "$response" | jq -e '.error_code' > /dev/null 2>&1; then
        echo "✗ Error creating connector: ${connector_name}"
        echo "$response" | jq '.'
        return 1
    else
        echo "✓ Connector ${connector_name} created successfully"
        return 0
    fi
}

# Function to check connector status
check_status() {
    local connector_name=$1
    echo ""
    echo "Checking status of ${connector_name}:"
    curl -s ${KAFKA_CONNECT_URL}/connectors/${connector_name}/status | jq '.'
}

# Main execution
check_connect_ready

# Restart Oracle Source Connector
delete_connector "debezium-oracle-source-connector"
sleep 2
create_connector "connectors/debezium-oracle-source-connector.json"
sleep 2
check_status "debezium-oracle-source-connector"

# Restart Enriched Postgres Sink Connector
delete_connector "postgres-enriched-sink-connector"
sleep 2
create_connector "connectors/postgres-enriched-sink-connector.json"
sleep 2
check_status "postgres-enriched-sink-connector"

echo ""
echo "==================================================="
echo "✓ All connectors restarted successfully"
echo "==================================================="
echo ""
echo "Note: Make sure ksqlDB streams are created before using enriched sink:"
echo "  ./kafka-connect/setup-ksqldb-streams.sh"
echo ""
echo "To view all connectors:"
echo "  curl ${KAFKA_CONNECT_URL}/connectors"
echo ""
echo "To view connector status:"
echo "  curl ${KAFKA_CONNECT_URL}/connectors/<connector-name>/status"
echo ""
