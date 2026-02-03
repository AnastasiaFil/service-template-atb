#!/bin/bash

# Wait for Kafka Connect to be ready
echo "Waiting for Kafka Connect to start..."
while ! curl -s http://localhost:8083/ > /dev/null; do
    sleep 5
    echo "Still waiting for Kafka Connect..."
done

echo "Kafka Connect is ready!"

# Register Oracle Source Connector
echo "Registering Oracle Source Connector..."
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @kafka-connect/connectors/oracle-source-connector.json

echo ""
echo "Oracle Source Connector registered!"

# Wait a bit for data to flow
echo "Waiting for initial data to be captured..."
sleep 10

# Register PostgreSQL Sink Connector
echo "Registering PostgreSQL Sink Connector..."
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @kafka-connect/connectors/postgres-sink-connector.json

echo ""
echo "PostgreSQL Sink Connector registered!"

# Check connector status
echo ""
echo "Checking connector status..."
curl -s http://localhost:8083/connectors/oracle-source-connector/status | jq '.'
echo ""
curl -s http://localhost:8083/connectors/postgres-sink-connector/status | jq '.'

echo ""
echo "All connectors registered successfully!"
