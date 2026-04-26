-- Initialize database schema for Music Stream Order & Delivery System
-- This is optional - will be auto-run when the container starts

-- Create extension for UUID support (if needed)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Example: Create a test tenant for development
-- You can add initial schema here if needed

-- For now, the application will handle schema creation
SELECT 'Database initialized successfully' AS status;
