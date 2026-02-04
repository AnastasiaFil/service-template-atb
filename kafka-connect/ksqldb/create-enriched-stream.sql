-- ksqlDB Script to JOIN Oracle tables data from Kafka topics
-- This script creates streams and tables from Debezium CDC topics
-- and performs JOIN to enrich oracle_users with role and grant names

-- Set auto.offset.reset to earliest to read from beginning
SET 'auto.offset.reset' = 'earliest';

-- =====================================================================
-- Step 1: Create STREAMs from Debezium CDC topics
-- NOTE: Debezium sends messages with 'payload' wrapper
-- =====================================================================

-- Stream for oracle_users (main table) - reading full Debezium envelope
CREATE STREAM IF NOT EXISTS oracle_users_stream (
  payload STRUCT<
    before STRUCT<ID DOUBLE, NAME VARCHAR, BIRTH_DATE_ORA BIGINT, SEX VARCHAR, ROLE_ID DOUBLE, GRANT_ID DOUBLE>,
    after STRUCT<ID DOUBLE, NAME VARCHAR, BIRTH_DATE_ORA BIGINT, SEX VARCHAR, ROLE_ID DOUBLE, GRANT_ID DOUBLE>,
    op VARCHAR
  >
) WITH (
  KAFKA_TOPIC='oracle_cdc.ORACLEUSER.ORACLE_USERS',
  VALUE_FORMAT='JSON'
);

-- Stream for oracle_users_role - reading full Debezium envelope
CREATE STREAM IF NOT EXISTS oracle_users_role_stream (
  payload STRUCT<
    before STRUCT<ID DOUBLE, NAME VARCHAR, `DESCRIBE` VARCHAR>,
    after STRUCT<ID DOUBLE, NAME VARCHAR, `DESCRIBE` VARCHAR>,
    op VARCHAR
  >
) WITH (
  KAFKA_TOPIC='oracle_cdc.ORACLEUSER.ORACLE_USERS_ROLE',
  VALUE_FORMAT='JSON'
);

-- Stream for oracle_users_grant - reading full Debezium envelope
CREATE STREAM IF NOT EXISTS oracle_users_grant_stream (
  payload STRUCT<
    before STRUCT<ID DOUBLE, NAME VARCHAR, `DESCRIBE` VARCHAR>,
    after STRUCT<ID DOUBLE, NAME VARCHAR, `DESCRIBE` VARCHAR>,
    op VARCHAR
  >
) WITH (
  KAFKA_TOPIC='oracle_cdc.ORACLEUSER.ORACLE_USERS_GRANT',
  VALUE_FORMAT='JSON'
);

-- =====================================================================
-- Step 2: Create TABLEs from streams (for JOIN operations)
-- =====================================================================

-- Flattened stream for roles to create table
CREATE STREAM IF NOT EXISTS oracle_users_role_flat 
WITH (KAFKA_TOPIC='oracle_users_role_flat', VALUE_FORMAT='JSON') AS
SELECT
  payload->after->ID AS ID,
  payload->after->NAME AS NAME,
  payload->after->`DESCRIBE` AS DESCRIBE_TEXT
FROM oracle_users_role_stream
WHERE payload->after IS NOT NULL
EMIT CHANGES;

-- Flattened stream for grants to create table
CREATE STREAM IF NOT EXISTS oracle_users_grant_flat 
WITH (KAFKA_TOPIC='oracle_users_grant_flat', VALUE_FORMAT='JSON') AS
SELECT
  payload->after->ID AS ID,
  payload->after->NAME AS NAME,
  payload->after->`DESCRIBE` AS DESCRIBE_TEXT
FROM oracle_users_grant_stream
WHERE payload->after IS NOT NULL
EMIT CHANGES;

-- Table for roles (keyed by ID)
CREATE TABLE IF NOT EXISTS oracle_users_role_table AS
SELECT
  ID,
  LATEST_BY_OFFSET(NAME) AS NAME,
  LATEST_BY_OFFSET(DESCRIBE_TEXT) AS DESCRIBE_TEXT
FROM oracle_users_role_flat
GROUP BY ID
EMIT CHANGES;

-- Table for grants (keyed by ID)
CREATE TABLE IF NOT EXISTS oracle_users_grant_table AS
SELECT
  ID,
  LATEST_BY_OFFSET(NAME) AS NAME,
  LATEST_BY_OFFSET(DESCRIBE_TEXT) AS DESCRIBE_TEXT
FROM oracle_users_grant_flat
GROUP BY ID
EMIT CHANGES;

-- =====================================================================
-- Step 3: Create enriched stream with JOINs
-- =====================================================================

-- Join oracle_users with role and grant tables to create enriched data
CREATE STREAM IF NOT EXISTS postgres_users_enriched WITH (
  KAFKA_TOPIC='postgres_users_enriched',
  VALUE_FORMAT='JSON',
  PARTITIONS=1
) AS
SELECT
  u.payload->after->ID AS id,
  u.payload->after->NAME AS name,
  u.payload->after->BIRTH_DATE_ORA AS birth_date,
  u.payload->after->SEX AS gender,
  u.payload->after->ROLE_ID AS role_id,
  u.payload->after->GRANT_ID AS grant_id,
  r.NAME AS role,
  g.NAME AS grant_field
FROM oracle_users_stream u
LEFT JOIN oracle_users_role_table r ON u.payload->after->ROLE_ID = r.ID
LEFT JOIN oracle_users_grant_table g ON u.payload->after->GRANT_ID = g.ID
WHERE u.payload->after IS NOT NULL
EMIT CHANGES;

-- =====================================================================
-- Notes:
-- =====================================================================
-- 1. BIRTH_DATE_ORA from Oracle is in epoch milliseconds format
--    It will be converted to DATE in PostgreSQL by the sink connector
-- 2. The enriched stream 'postgres_users_enriched' will be consumed
--    by JDBC Sink Connector to write to postgres.postgres_users table
-- 3. The 'id' field in PostgreSQL comes from Oracle (oracle_users.ID)
--    and is included in this stream
-- 4. LEFT JOIN is used to handle cases where role_id or grant_id might be NULL
-- 5. WHERE payload->after IS NOT NULL filters out DELETE events
