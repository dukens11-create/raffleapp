-- Migration: Add raffle_id column to tickets table if it doesn't exist
-- This fixes the error: column "raffle_id" of relation "tickets" does not exist

DO $$ 
BEGIN
    -- Check if raffle_id column exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'tickets' 
        AND column_name = 'raffle_id'
    ) THEN
        -- Add raffle_id column
        ALTER TABLE tickets 
        ADD COLUMN raffle_id INTEGER;
        
        RAISE NOTICE 'Added raffle_id column to tickets table';
    ELSE
        RAISE NOTICE 'Column raffle_id already exists in tickets table';
    END IF;
    
    -- Set default value for existing rows (if any) that have NULL raffle_id
    UPDATE tickets SET raffle_id = 1 WHERE raffle_id IS NULL;
    
    -- Make column NOT NULL after setting values (if not already)
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'tickets' 
        AND column_name = 'raffle_id'
        AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE tickets ALTER COLUMN raffle_id SET NOT NULL;
        RAISE NOTICE 'Set raffle_id column to NOT NULL';
    END IF;
    
    -- Add foreign key constraint if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_tickets_raffle' 
        AND table_name = 'tickets'
    ) THEN
        ALTER TABLE tickets 
        ADD CONSTRAINT fk_tickets_raffle 
        FOREIGN KEY (raffle_id) 
        REFERENCES raffles(id) 
        ON DELETE CASCADE;
        
        RAISE NOTICE 'Added foreign key constraint fk_tickets_raffle';
    ELSE
        RAISE NOTICE 'Foreign key constraint fk_tickets_raffle already exists';
    END IF;
    
    -- Create index for better query performance if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE indexname = 'idx_tickets_raffle_id'
    ) THEN
        CREATE INDEX idx_tickets_raffle_id ON tickets(raffle_id);
        RAISE NOTICE 'Created index idx_tickets_raffle_id';
    ELSE
        RAISE NOTICE 'Index idx_tickets_raffle_id already exists';
    END IF;
    
    RAISE NOTICE 'Successfully completed raffle_id migration for tickets table';
END $$;
