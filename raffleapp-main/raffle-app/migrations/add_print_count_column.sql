-- Migration: Add print_count column to tickets table
-- This tracks how many times each ticket has been printed

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tickets' 
        AND column_name = 'print_count'
    ) THEN
        -- Add column with default value (automatically applied to existing rows)
        ALTER TABLE tickets 
        ADD COLUMN print_count INTEGER DEFAULT 0 NOT NULL;
        
        RAISE NOTICE 'Added print_count column to tickets table';
    ELSE
        RAISE NOTICE 'print_count column already exists';
    END IF;
END $$;
