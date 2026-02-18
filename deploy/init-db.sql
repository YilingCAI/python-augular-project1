-- ==============================================================================
-- PostgreSQL Initialization Script
-- ==============================================================================
-- This script runs on first container startup
-- Typically used for creating extensions, schemas, etc.
-- ==============================================================================

-- Enable useful extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create separate schema for application (optional, for better organization)
CREATE SCHEMA IF NOT EXISTS myapp;

-- Grant permissions
GRANT USAGE ON SCHEMA myapp TO postgres;
GRANT CREATE ON SCHEMA myapp TO postgres;

-- Log initialization complete
\echo 'PostgreSQL initialization complete'
