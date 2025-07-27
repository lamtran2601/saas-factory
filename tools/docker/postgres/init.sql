-- Initialize PostgreSQL database for SaaS Factory
-- This script runs when the PostgreSQL container starts for the first time

-- Create additional databases for testing
CREATE DATABASE saas_factory_test;

-- Create a user for the application (optional, can use postgres user)
-- CREATE USER saas_factory WITH PASSWORD 'saas_factory_password';
-- GRANT ALL PRIVILEGES ON DATABASE saas_factory_dev TO saas_factory;
-- GRANT ALL PRIVILEGES ON DATABASE saas_factory_test TO saas_factory;

-- Enable UUID extension
\c saas_factory_dev;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\c saas_factory_test;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
