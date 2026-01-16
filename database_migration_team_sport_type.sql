-- Migration: Add sport_type column to teams table
-- Run this in your Supabase SQL Editor

-- Add sport_type column to teams table
-- Default to 'volleyball' for existing teams
ALTER TABLE teams
ADD COLUMN IF NOT EXISTS sport_type TEXT NOT NULL DEFAULT 'volleyball';

-- Add check constraint to ensure valid sport types
ALTER TABLE teams
ADD CONSTRAINT teams_sport_type_check
CHECK (sport_type IN ('volleyball', 'pickleball'));

-- Add comment for documentation
COMMENT ON COLUMN teams.sport_type IS 'Sport type for the team: volleyball or pickleball';

-- Create index for faster filtering by sport type
CREATE INDEX IF NOT EXISTS idx_teams_sport_type ON teams(sport_type);

-- Verify the column was added
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'teams' AND column_name = 'sport_type';
