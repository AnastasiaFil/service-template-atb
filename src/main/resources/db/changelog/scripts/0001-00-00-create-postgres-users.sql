-- Create table postgres_users with mapped fields from Oracle
-- Mapping:
-- - id: auto-generated in PostgreSQL (SERIAL, not from Oracle)
-- - name: from oracle_users.name
-- - birth_date: from oracle_users.birth_date_ora
-- - gender: from oracle_users.sex
-- - role: from oracle_users_role.name (via JOIN in ksqlDB)
-- - grant_field: from oracle_users_grant.name (via JOIN in ksqlDB)

CREATE TABLE IF NOT EXISTS postgres.postgres_users (
    id SERIAL PRIMARY KEY,
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
COMMENT ON TABLE postgres.postgres_users IS 'Users data from Oracle CDC with enriched role and grant names';
COMMENT ON COLUMN postgres.postgres_users.id IS 'Auto-generated PostgreSQL ID (not from Oracle)';
COMMENT ON COLUMN postgres.postgres_users.name IS 'User name from oracle_users.name';
COMMENT ON COLUMN postgres.postgres_users.birth_date IS 'Birth date from oracle_users.birth_date_ora';
COMMENT ON COLUMN postgres.postgres_users.gender IS 'Gender from oracle_users.sex';
COMMENT ON COLUMN postgres.postgres_users.role IS 'Role name from oracle_users_role.name (joined via ksqlDB)';
COMMENT ON COLUMN postgres.postgres_users.grant_field IS 'Grant name from oracle_users_grant.name (joined via ksqlDB)';
