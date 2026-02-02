-- Oracle database initialization script
-- This script creates tables and inserts initial data for Oracle users, grants, and roles

-- Create tables if they don't exist
CREATE TABLE IF NOT EXISTS oracle_users_grant (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(255),
    describe VARCHAR2(1000)
);

CREATE TABLE IF NOT EXISTS oracle_users_role (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(255),
    describe VARCHAR2(1000)
);

CREATE TABLE IF NOT EXISTS oracle_users (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(255),
    birth_date_ora DATE,
    sex VARCHAR2(10),
    role_id NUMBER,
    grant_id NUMBER,
    CONSTRAINT fk_role FOREIGN KEY (role_id) REFERENCES oracle_users_role(id),
    CONSTRAINT fk_grant FOREIGN KEY (grant_id) REFERENCES oracle_users_grant(id)
);

-- Clear existing data (for reinitialization)
DELETE FROM oracle_users;
DELETE FROM oracle_users_grant;
DELETE FROM oracle_users_role;

-- Insert grants first
INSERT INTO oracle_users_grant (name, describe) VALUES ('READ_ACCESS', 'Permission to read data from database tables');
INSERT INTO oracle_users_grant (name, describe) VALUES ('WRITE_ACCESS', 'Permission to insert and update data in database tables');
INSERT INTO oracle_users_grant (name, describe) VALUES ('DELETE_ACCESS', 'Permission to delete data from database tables');
INSERT INTO oracle_users_grant (name, describe) VALUES ('EXECUTE_ACCESS', 'Permission to execute stored procedures and functions');
INSERT INTO oracle_users_grant (name, describe) VALUES ('ADMIN_ACCESS', 'Full administrative access to the database');

-- Insert roles
INSERT INTO oracle_users_role (name, describe) VALUES ('USER', 'Basic user role with read-only access');
INSERT INTO oracle_users_role (name, describe) VALUES ('DEVELOPER', 'Developer role with read and write access');
INSERT INTO oracle_users_role (name, describe) VALUES ('ANALYST', 'Analyst role with read and execute access');
INSERT INTO oracle_users_role (name, describe) VALUES ('MANAGER', 'Manager role with extended permissions');
INSERT INTO oracle_users_role (name, describe) VALUES ('ADMINISTRATOR', 'Administrator role with full access');

-- Insert 5 users with role and grant references
INSERT INTO oracle_users (name, birth_date_ora, sex, role_id, grant_id) VALUES ('Ivan Petrov', TO_DATE('1990-05-15', 'YYYY-MM-DD'), 'M', 1, 1);
INSERT INTO oracle_users (name, birth_date_ora, sex, role_id, grant_id) VALUES ('Maria Sidorova', TO_DATE('1985-08-22', 'YYYY-MM-DD'), 'F', 2, 2);
INSERT INTO oracle_users (name, birth_date_ora, sex, role_id, grant_id) VALUES ('Alexey Ivanov', TO_DATE('1992-12-10', 'YYYY-MM-DD'), 'M', 3, 3);
INSERT INTO oracle_users (name, birth_date_ora, sex, role_id, grant_id) VALUES ('Elena Volkova', TO_DATE('1988-03-30', 'YYYY-MM-DD'), 'F', 4, 4);
INSERT INTO oracle_users (name, birth_date_ora, sex, role_id, grant_id) VALUES ('Dmitry Sokolov', TO_DATE('1995-07-18', 'YYYY-MM-DD'), 'M', 5, 5);

COMMIT;
