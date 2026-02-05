-- Create table postgres_users with mapped fields from Oracle
-- Mapping:
-- - id: from oracle_users.id (replicated via CDC, NOT auto-generated)
-- - name: from oracle_users.name
-- - birth_date: from oracle_users.birth_date_ora
-- - gender: from oracle_users.sex
-- - role: from oracle_users_role.name (via JOIN in ksqlDB, currently NULL)
-- - grant_field: from oracle_users_grant.name (via JOIN in ksqlDB, currently NULL)

CREATE TABLE IF NOT EXISTS postgres.postgres_users (
    id BIGINT PRIMARY KEY,
    name VARCHAR(255),
    birth_date DATE,
    gender VARCHAR(10),
    role VARCHAR(255),
    grant_field VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_postgres_users_name ON postgres.postgres_users(name);
CREATE INDEX IF NOT EXISTS idx_postgres_users_role ON postgres.postgres_users(role);
CREATE INDEX IF NOT EXISTS idx_postgres_users_gender ON postgres.postgres_users(gender);

-- Add comment to table
COMMENT ON TABLE postgres.postgres_users IS 'Users data from Oracle CDC (replicated in real-time)';
COMMENT ON COLUMN postgres.postgres_users.id IS 'User ID from Oracle (replicated via CDC)';
COMMENT ON COLUMN postgres.postgres_users.name IS 'User name from oracle_users.name';
COMMENT ON COLUMN postgres.postgres_users.birth_date IS 'Birth date from oracle_users.birth_date_ora';
COMMENT ON COLUMN postgres.postgres_users.gender IS 'Gender from oracle_users.sex';
COMMENT ON COLUMN postgres.postgres_users.role IS 'Role name (for future ksqlDB enrichment)';
COMMENT ON COLUMN postgres.postgres_users.grant_field IS 'Grant name (for future ksqlDB enrichment)';
