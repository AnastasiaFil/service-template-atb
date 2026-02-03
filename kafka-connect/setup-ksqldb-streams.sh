#!/bin/bash

# ===================================================================
# Setup ksqlDB streams and tables for joining Oracle CDC data
# ===================================================================

set -e

KSQLDB_SERVER="http://localhost:8088"
KSQLDB_SCRIPT="kafka-connect/ksqldb/create-enriched-stream.sql"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "======================================================================"
echo "  ksqlDB Stream Setup for Oracle CDC Data Enrichment"
echo "======================================================================"
echo ""

# Function to wait for ksqlDB
wait_for_ksqldb() {
    echo -e "${YELLOW}Waiting for ksqlDB server to be ready...${NC}"
    local retries=0
    local max_retries=60
    
    while ! curl -s "${KSQLDB_SERVER}/info" > /dev/null; do
        retries=$((retries + 1))
        if [ $retries -ge $max_retries ]; then
            echo -e "${RED}Error: ksqlDB server did not become ready in time${NC}"
            exit 1
        fi
        echo "Still waiting... (attempt $retries/$max_retries)"
        sleep 5
    done
    
    echo -e "${GREEN}✓ ksqlDB server is ready!${NC}"
    echo ""
}

# Function to execute ksqlDB statement
execute_ksql() {
    local statement=$1
    echo -e "${YELLOW}Executing: ${statement:0:50}...${NC}"
    
    response=$(curl -s -X POST "${KSQLDB_SERVER}/ksql" \
      -H "Content-Type: application/vnd.ksql.v1+json" \
      -d "{\"ksql\": \"${statement}\", \"streamsProperties\": {}}")
    
    if echo "$response" | grep -q "error"; then
        echo -e "${RED}✗ Error executing statement${NC}"
        echo "$response" | jq '.'
        return 1
    else
        echo -e "${GREEN}✓ Statement executed successfully${NC}"
    fi
    echo ""
}

# Function to execute ksqlDB script
execute_ksql_script() {
    local script_file=$1
    echo -e "${YELLOW}Executing ksqlDB script: ${script_file}${NC}"
    echo ""
    
    # Read the script and split by semicolons
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*-- ]]; then
            continue
        fi
        
        # Accumulate lines until we hit a semicolon
        statement="${statement}${line} "
        
        if [[ "$line" =~ \;[[:space:]]*$ ]]; then
            # Remove semicolon and whitespace
            statement=$(echo "$statement" | sed 's/;[[:space:]]*$//')
            
            # Execute the accumulated statement
            if [[ ! -z "$statement" ]]; then
                execute_ksql "$statement" || true
            fi
            
            statement=""
        fi
    done < "$script_file"
    
    echo -e "${GREEN}✓ Script execution completed${NC}"
    echo ""
}

# Main execution
main() {
    wait_for_ksqldb
    
    echo "======================================================================"
    echo "  Step 1: Create Streams and Tables"
    echo "======================================================================"
    echo ""
    
    execute_ksql_script "$KSQLDB_SCRIPT"
    
    echo "======================================================================"
    echo "  Step 2: Verify Created Streams and Tables"
    echo "======================================================================"
    echo ""
    
    echo -e "${YELLOW}List of streams:${NC}"
    curl -s -X POST "${KSQLDB_SERVER}/ksql" \
      -H "Content-Type: application/vnd.ksql.v1+json" \
      -d '{"ksql": "SHOW STREAMS;"}' | jq '.'
    
    echo ""
    echo -e "${YELLOW}List of tables:${NC}"
    curl -s -X POST "${KSQLDB_SERVER}/ksql" \
      -H "Content-Type: application/vnd.ksql.v1+json" \
      -d '{"ksql": "SHOW TABLES;"}' | jq '.'
    
    echo ""
    echo -e "${YELLOW}List of queries:${NC}"
    curl -s -X POST "${KSQLDB_SERVER}/ksql" \
      -H "Content-Type: application/vnd.ksql.v1+json" \
      -d '{"ksql": "SHOW QUERIES;"}' | jq '.'
    
    echo ""
    echo "======================================================================"
    echo -e "${GREEN}✓ ksqlDB streams and tables created successfully!${NC}"
    echo "======================================================================"
    echo ""
    echo "Next steps:"
    echo "  1. Verify enriched topic: docker exec -it service-template-atb-kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic postgres_users_enriched --from-beginning"
    echo "  2. Register sink connector: ./kafka-connect/register-enriched-sink-connector.sh"
    echo "  3. Query ksqlDB interactively: docker exec -it service-template-atb-ksqldb-cli ksql http://ksqldb-server:8088"
    echo ""
}

main "$@"
