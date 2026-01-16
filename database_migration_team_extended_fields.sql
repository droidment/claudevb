-- Migration: Add extended fields to teams table for CSV import data
-- Run this in your Supabase SQL Editor

-- Add new columns to teams table for additional registration information
ALTER TABLE teams 
ADD COLUMN IF NOT EXISTS captain_name TEXT,
ADD COLUMN IF NOT EXISTS captain_email TEXT,
ADD COLUMN IF NOT EXISTS captain_phone TEXT,
ADD COLUMN IF NOT EXISTS contact_person_2 TEXT,
ADD COLUMN IF NOT EXISTS contact_phone_2 TEXT,
ADD COLUMN IF NOT EXISTS player_count INTEGER,
ADD COLUMN IF NOT EXISTS special_requests TEXT,
ADD COLUMN IF NOT EXISTS signed_by TEXT,
ADD COLUMN IF NOT EXISTS registration_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS registration_paid BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS payment_amount DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS payment_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS lunch_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS category TEXT;

-- Add comment to explain the fields
COMMENT ON COLUMN teams.captain_name IS 'Name of the team captain (from CSV import)';
COMMENT ON COLUMN teams.captain_email IS 'Email of the team captain';
COMMENT ON COLUMN teams.captain_phone IS 'Phone number of the team captain';
COMMENT ON COLUMN teams.contact_person_2 IS 'Secondary contact person name';
COMMENT ON COLUMN teams.contact_phone_2 IS 'Secondary contact person phone';
COMMENT ON COLUMN teams.player_count IS 'Number of players registered';
COMMENT ON COLUMN teams.special_requests IS 'Any special requests from the team';
COMMENT ON COLUMN teams.signed_by IS 'Person who signed the registration';
COMMENT ON COLUMN teams.registration_date IS 'When the team registered (from CSV timestamp)';
COMMENT ON COLUMN teams.registration_paid IS 'Whether registration fee has been paid';
COMMENT ON COLUMN teams.payment_amount IS 'Amount paid for registration';
COMMENT ON COLUMN teams.payment_date IS 'When payment was received';
COMMENT ON COLUMN teams.lunch_count IS 'Number of lunches ordered';
COMMENT ON COLUMN teams.notes IS 'Additional notes about the team';
COMMENT ON COLUMN teams.category IS 'Tournament category (Men''s Volleyball, Throwball, etc.)';

-- Verify the columns were added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'teams' 
ORDER BY ordinal_position;
