-- Migration: Add print_count column to tickets table
-- This tracks how many times each ticket has been printed

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tickets' 
        AND column_name = 'print_count'
    ) THEN
        ALTER TABLE tickets 
        ADD COLUMN print_count INTEGER DEFAULT 0;
        
        -- Ensure all existing rows have the default value
        UPDATE tickets SET print_count = 0 WHERE print_count IS NULL;
        
        -- Make column NOT NULL after setting values
        ALTER TABLE tickets ALTER COLUMN print_count SET NOT NULL;
        
        RAISE NOTICE 'Added print_count column to tickets table';
    ELSE
        RAISE NOTICE 'print_count column already exists';
    END IF;
END $$;
