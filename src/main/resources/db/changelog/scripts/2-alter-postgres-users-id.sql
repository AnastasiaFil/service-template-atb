-- Truncate postgres_users table and change id column from SERIAL to BIGINT
-- This allows the id to come from Oracle instead of auto-generation

-- Step 1: Clear all data from the table
TRUNCATE TABLE postgres.postgres_users;

-- Step 2: Drop existing primary key constraint
ALTER TABLE postgres.postgres_users DROP CONSTRAINT IF EXISTS postgres_users_pkey;

-- Step 3: Drop the old id column
ALTER TABLE postgres.postgres_users DROP COLUMN IF EXISTS id;

-- Step 4: Add new id column as BIGINT (not SERIAL)
ALTER TABLE postgres.postgres_users ADD COLUMN id BIGINT;

-- Step 5: Add primary key constraint on the new id column
ALTER TABLE postgres.postgres_users ADD PRIMARY KEY (id);

-- Step 6: Drop the sequence if it exists (created by old SERIAL)
DROP SEQUENCE IF EXISTS postgres.postgres_users_id_seq;

-- Add comment to reflect the change
COMMENT ON COLUMN postgres.postgres_users.id IS 'User ID from Oracle (oracle_users.id) - no auto-generation';
