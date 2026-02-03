#!/bin/bash

# ===================================================================
# Setup Oracle Database for Debezium CDC
# ===================================================================
# This script configures Oracle to work with Debezium LogMiner connector

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ORACLE_CONTAINER="service-template-atb-oracle"
ORACLE_USER="oracleuser"
ORACLE_PASSWORD="oraclepass"
ORACLE_SYS_PASSWORD="OracleAdmin123"
ORACLE_PDB="XEPDB1"

echo "======================================================================"
echo "  Oracle Database Configuration for Debezium CDC"
echo "======================================================================"
echo ""

# Check if Oracle container is running
if ! docker ps | grep -q "$ORACLE_CONTAINER"; then
    echo -e "${RED}Error: Oracle container is not running${NC}"
    echo "Start it with: docker compose --profile dev-oracle up -d oracle"
    exit 1
fi

echo -e "${GREEN}✓ Oracle container is running${NC}"
echo ""

# Function to execute SQL as SYSDBA
execute_as_sysdba() {
    local sql_command=$1
    docker exec -i "$ORACLE_CONTAINER" sqlplus -s sys/"$ORACLE_SYS_PASSWORD"@"$ORACLE_PDB" AS SYSDBA <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET ECHO OFF
$sql_command
EXIT;
EOF
}

# Function to execute SQL as app user
execute_as_user() {
    local sql_command=$1
    docker exec -i "$ORACLE_CONTAINER" sqlplus -s "$ORACLE_USER"/"$ORACLE_PASSWORD"@"$ORACLE_PDB" <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET ECHO OFF
$sql_command
EXIT;
EOF
}

echo "======================================================================"
echo "  Step 1: Check Archive Log Mode"
echo "======================================================================"
echo ""

LOG_MODE=$(execute_as_sysdba "SELECT LOG_MODE FROM V\$DATABASE;")
echo "Current log mode: $LOG_MODE"

if [[ "$LOG_MODE" == *"ARCHIVELOG"* ]]; then
    echo -e "${GREEN}✓ Archive log mode is already enabled${NC}"
else
    echo -e "${YELLOW}⚠ Archive log mode is NOT enabled${NC}"
    echo "Debezium requires archive log mode to be enabled."
    echo ""
    echo "To enable it manually, run:"
    echo "  docker exec -it $ORACLE_CONTAINER sqlplus / as sysdba"
    echo "  SHUTDOWN IMMEDIATE;"
    echo "  STARTUP MOUNT;"
    echo "  ALTER DATABASE ARCHIVELOG;"
    echo "  ALTER DATABASE OPEN;"
fi
echo ""

echo "======================================================================"
echo "  Step 2: Enable Supplemental Logging"
echo "======================================================================"
echo ""

echo -e "${YELLOW}Enabling supplemental logging on database level...${NC}"

execute_as_sysdba "
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;
"

echo -e "${GREEN}✓ Database-level supplemental logging enabled${NC}"
echo ""

echo "======================================================================"
echo "  Step 3: Grant LogMiner Privileges"
echo "======================================================================"
echo ""

echo -e "${YELLOW}Granting LogMiner privileges to $ORACLE_USER...${NC}"

execute_as_sysdba "
GRANT CREATE SESSION TO $ORACLE_USER;
GRANT SET CONTAINER TO $ORACLE_USER;
GRANT SELECT ON V_\$DATABASE TO $ORACLE_USER;
GRANT FLASHBACK ANY TABLE TO $ORACLE_USER;
GRANT SELECT ANY TABLE TO $ORACLE_USER;
GRANT SELECT_CATALOG_ROLE TO $ORACLE_USER;
GRANT EXECUTE_CATALOG_ROLE TO $ORACLE_USER;
GRANT SELECT ANY TRANSACTION TO $ORACLE_USER;
GRANT LOGMINING TO $ORACLE_USER;
GRANT CREATE TABLE TO $ORACLE_USER;
GRANT LOCK ANY TABLE TO $ORACLE_USER;
GRANT CREATE SEQUENCE TO $ORACLE_USER;
GRANT EXECUTE ON DBMS_LOGMNR TO $ORACLE_USER;
GRANT EXECUTE ON DBMS_LOGMNR_D TO $ORACLE_USER;
GRANT SELECT ON V_\$LOG TO $ORACLE_USER;
GRANT SELECT ON V_\$LOG_HISTORY TO $ORACLE_USER;
GRANT SELECT ON V_\$LOGMNR_LOGS TO $ORACLE_USER;
GRANT SELECT ON V_\$LOGMNR_CONTENTS TO $ORACLE_USER;
GRANT SELECT ON V_\$LOGMNR_PARAMETERS TO $ORACLE_USER;
GRANT SELECT ON V_\$LOGFILE TO $ORACLE_USER;
GRANT SELECT ON V_\$ARCHIVED_LOG TO $ORACLE_USER;
GRANT SELECT ON V_\$ARCHIVE_DEST_STATUS TO $ORACLE_USER;
"

echo -e "${GREEN}✓ LogMiner privileges granted${NC}"
echo ""

echo "======================================================================"
echo "  Step 4: Enable Table-Level Supplemental Logging"
echo "======================================================================"
echo ""

echo -e "${YELLOW}Enabling supplemental logging on tables...${NC}"

execute_as_user "
ALTER TABLE ORACLE_USERS ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE ORACLE_USERS_ROLE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE ORACLE_USERS_GRANT ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
"

echo -e "${GREEN}✓ Table-level supplemental logging enabled${NC}"
echo ""

echo "======================================================================"
echo "  Step 5: Verify Configuration"
echo "======================================================================"
echo ""

echo "Supplemental logging status:"
execute_as_sysdba "
SELECT SUPPLEMENTAL_LOG_DATA_MIN, SUPPLEMENTAL_LOG_DATA_PK 
FROM V\$DATABASE;
"

echo ""
echo "Table supplemental logging:"
execute_as_user "
SELECT TABLE_NAME, LOG_GROUP_NAME, LOG_GROUP_TYPE 
FROM USER_LOG_GROUPS 
WHERE TABLE_NAME IN ('ORACLE_USERS', 'ORACLE_USERS_ROLE', 'ORACLE_USERS_GRANT');
"

echo ""
echo "======================================================================"
echo -e "${GREEN}✓ Oracle database is configured for Debezium CDC!${NC}"
echo "======================================================================"
echo ""
echo "Next steps:"
echo "  1. Register Debezium connector: ./kafka-connect/register-debezium-connectors.sh"
echo "  2. Monitor connector: curl http://localhost:8083/connectors/debezium-oracle-source-connector/status"
echo ""
