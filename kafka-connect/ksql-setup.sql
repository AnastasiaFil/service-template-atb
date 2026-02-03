-- Create streams from Kafka topics for Oracle tables
CREATE STREAM oracle_users_stream (
    ID BIGINT,
    NAME VARCHAR,
    BIRTH_DATE_ORA BIGINT,
    SEX VARCHAR,
    ROLE_ID BIGINT,
    GRANT_ID BIGINT
) WITH (
    KAFKA_TOPIC='oracle.ORACLE_USERS',
    VALUE_FORMAT='JSON'
);

CREATE STREAM oracle_users_role_stream (
    ID BIGINT,
    NAME VARCHAR,
    DESCRIBE VARCHAR
) WITH (
    KAFKA_TOPIC='oracle.ORACLE_USERS_ROLE',
    VALUE_FORMAT='JSON'
);

CREATE STREAM oracle_users_grant_stream (
    ID BIGINT,
    NAME VARCHAR,
    DESCRIBE VARCHAR
) WITH (
    KAFKA_TOPIC='oracle.ORACLE_USERS_GRANT',
    VALUE_FORMAT='JSON'
);

-- Create tables from streams for lookups
CREATE TABLE oracle_users_role_table AS
    SELECT ID, LATEST_BY_OFFSET(NAME) AS role_name
    FROM oracle_users_role_stream
    GROUP BY ID
    EMIT CHANGES;

CREATE TABLE oracle_users_grant_table AS
    SELECT ID, LATEST_BY_OFFSET(NAME) AS grant_name
    FROM oracle_users_grant_stream
    GROUP BY ID
    EMIT CHANGES;

-- Create enriched stream with JOINs
CREATE STREAM postgres_users_enriched WITH (
    KAFKA_TOPIC='postgres_users_enriched',
    VALUE_FORMAT='JSON'
) AS
    SELECT
        u.ID AS id,
        u.NAME AS name,
        CAST(u.BIRTH_DATE_ORA AS VARCHAR) AS birth_date,
        u.SEX AS gender,
        r.role_name AS role,
        g.grant_name AS grant_field
    FROM oracle_users_stream u
    LEFT JOIN oracle_users_role_table r ON u.ROLE_ID = r.ID
    LEFT JOIN oracle_users_grant_table g ON u.GRANT_ID = g.ID
    EMIT CHANGES;
