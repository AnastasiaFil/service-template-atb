-- ===================================================================
-- Oracle Configuration for Debezium CDC (LogMiner)
-- ===================================================================
-- This script configures Oracle database to work with Debezium Oracle CDC Connector
-- Run this script as SYSDBA user

-- Connect as SYSDBA
CONNECT sys/OracleAdmin123@//localhost:1521/XEPDB1 AS SYSDBA;

-- ===================================================================
-- Step 1: Enable Archive Log Mode and Supplemental Logging
-- ===================================================================
-- Check if archive log mode is enabled
SELECT LOG_MODE FROM V$DATABASE;

-- Enable ARCHIVELOG mode (required for LogMiner)
-- NOTE: This requires database restart and should be done carefully
-- SHUTDOWN IMMEDIATE;
-- STARTUP MOUNT;
-- ALTER DATABASE ARCHIVELOG;
-- ALTER DATABASE OPEN;

-- Enable minimal supplemental logging (required for Debezium)
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;

-- Enable supplemental logging for PRIMARY KEY columns
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;

-- ===================================================================
-- Step 2: Grant Required Privileges to Oracle User
-- ===================================================================
-- Grant necessary privileges for LogMiner operations
GRANT CREATE SESSION TO oracleuser;
GRANT SET CONTAINER TO oracleuser;
GRANT SELECT ON V_$DATABASE TO oracleuser;
GRANT FLASHBACK ANY TABLE TO oracleuser;
GRANT SELECT ANY TABLE TO oracleuser;
GRANT SELECT_CATALOG_ROLE TO oracleuser;
GRANT EXECUTE_CATALOG_ROLE TO oracleuser;
GRANT SELECT ANY TRANSACTION TO oracleuser;
GRANT LOGMINING TO oracleuser;

-- Additional permissions for LogMiner
GRANT CREATE TABLE TO oracleuser;
GRANT LOCK ANY TABLE TO oracleuser;
GRANT CREATE SEQUENCE TO oracleuser;

GRANT EXECUTE ON DBMS_LOGMNR TO oracleuser;
GRANT EXECUTE ON DBMS_LOGMNR_D TO oracleuser;
GRANT SELECT ON V_$LOG TO oracleuser;
GRANT SELECT ON V_$LOG_HISTORY TO oracleuser;
GRANT SELECT ON V_$LOGMNR_LOGS TO oracleuser;
GRANT SELECT ON V_$LOGMNR_CONTENTS TO oracleuser;
GRANT SELECT ON V_$LOGMNR_PARAMETERS TO oracleuser;
GRANT SELECT ON V_$LOGFILE TO oracleuser;
GRANT SELECT ON V_$ARCHIVED_LOG TO oracleuser;
GRANT SELECT ON V_$ARCHIVE_DEST_STATUS TO oracleuser;

-- ===================================================================
-- Step 3: Enable Supplemental Logging on Tables
-- ===================================================================
-- Connect as application user
CONNECT oracleuser/oraclepass@//localhost:1521/XEPDB1;

-- Enable supplemental logging for each table
ALTER TABLE ORACLE_USERS ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE ORACLE_USERS_ROLE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER TABLE ORACLE_USERS_GRANT ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

-- ===================================================================
-- Step 4: Verify Configuration
-- ===================================================================
-- Check supplemental logging status
SELECT SUPPLEMENTAL_LOG_DATA_MIN, SUPPLEMENTAL_LOG_DATA_PK 
FROM V$DATABASE;

-- Check table-level supplemental logging
SELECT TABLE_NAME, LOG_GROUP_NAME, LOG_GROUP_TYPE 
FROM USER_LOG_GROUPS 
WHERE TABLE_NAME IN ('ORACLE_USERS', 'ORACLE_USERS_ROLE', 'ORACLE_USERS_GRANT');

-- ===================================================================
-- IMPORTANT NOTES:
-- ===================================================================
-- 1. Archive log mode is CRITICAL for Debezium to work
-- 2. If you're using Oracle Free/XE in Docker, archive log mode might already be enabled
-- 3. Supplemental logging adds small overhead but is required for CDC
-- 4. LogMiner will read redo logs in real-time to capture changes
-- ===================================================================

EXIT;
