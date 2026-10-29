-- Photography Portfolio Database Schema
-- Run this in pgAdmin4 Query Tool

-- 1. Create the Gallery Table
CREATE TABLE IF NOT EXISTS gallery_items (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    theme VARCHAR(100) DEFAULT 'Uncategorized',
    aspect_ratio VARCHAR(50) DEFAULT 'aspect-portrait',
    image_path TEXT NOT NULL, -- Path to the file in /assets/gallery/
    
    -- Technical Specifications (JSONB allows for flexible metadata)
    shot_specs JSONB DEFAULT '{
        "camera": "-",
        "location": "-",
        "aperture": "-",
        "shutter": "-",
        "iso": "-",
        "date": "-"
    }',
    
    -- Status and Auditing
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- For easy sorting/ordering
    display_order INTEGER DEFAULT 0
);

-- 2. Create an Audit Log Table (Optional but recommended for high-end systems)
CREATE TABLE IF NOT EXISTS activity_log (
    log_id SERIAL PRIMARY KEY,
    action_type VARCHAR(50), -- 'UPLOAD', 'DELETE', 'UPDATE'
    item_id INTEGER REFERENCES gallery_items(id),
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);

-- 3. Create a helper function for Soft Deleting
CREATE OR REPLACE FUNCTION soft_delete_item(target_id INTEGER) 
RETURNS VOID AS $$
BEGIN
    UPDATE gallery_items 
    SET is_active = FALSE, 
        deleted_at = CURRENT_TIMESTAMP 
    WHERE id = target_id;
    
    INSERT INTO activity_log (action_type, item_id, details)
    VALUES ('DELETE', target_id, 'Item moved to archive');
END;
$$ LANGUAGE plpgsql;

-- Initial Comment
COMMENT ON TABLE gallery_items IS 'Stores metadata and paths for all portfolio photographs';
