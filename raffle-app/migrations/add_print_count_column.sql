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
        ADD COLUMN print_count INTEGER DEFAULT 0 NOT NULL;
        
        -- Add index for performance (optional but recommended)
        CREATE INDEX idx_tickets_print_count ON tickets(print_count);
        
        RAISE NOTICE 'Added print_count column to tickets table';
    ELSE
        RAISE NOTICE 'print_count column already exists';
    END IF;
END $$;
