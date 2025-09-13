-- Database initialization script for PostgreSQL
-- This script creates the required databases for NetBox and Nautobot

-- Create NetBox database
CREATE DATABASE netbox OWNER netops;

-- Create Nautobot database  
CREATE DATABASE nautobot OWNER netops;

-- Grant all privileges to netops user
GRANT ALL PRIVILEGES ON DATABASE netbox TO netops;
GRANT ALL PRIVILEGES ON DATABASE nautobot TO netops;

-- Connect to NetBox database and create extensions
\c netbox;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Connect to Nautobot database and create extensions
\c nautobot;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
