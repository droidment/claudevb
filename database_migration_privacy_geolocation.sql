-- Database Migration: Add Privacy and Geo-Location Features
-- Run this SQL in Supabase SQL Editor

-- 1. Add new columns to tournaments table
ALTER TABLE tournaments
ADD COLUMN is_public BOOLEAN DEFAULT true,
ADD COLUMN invite_code TEXT UNIQUE,
ADD COLUMN latitude DOUBLE PRECISION,
ADD COLUMN longitude DOUBLE PRECISION;

-- 2. Create index on invite_code for fast lookups
CREATE INDEX idx_tournaments_invite_code ON tournaments(invite_code);

-- 3. Create index on is_public for filtering
CREATE INDEX idx_tournaments_is_public ON tournaments(is_public);

-- 4. Create a function to generate unique invite codes
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
  code TEXT;
  exists BOOLEAN;
BEGIN
  LOOP
    -- Generate a random 8-character code (uppercase letters and numbers)
    code := UPPER(substring(md5(random()::text) from 1 for 8));

    -- Check if code already exists
    SELECT EXISTS(SELECT 1 FROM tournaments WHERE invite_code = code) INTO exists;

    -- Exit loop if code is unique
    IF NOT exists THEN
      RETURN code;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 5. Create trigger to auto-generate invite code for private tournaments
CREATE OR REPLACE FUNCTION auto_generate_invite_code()
RETURNS TRIGGER AS $$
BEGIN
  -- Only generate invite code for private tournaments
  IF NEW.is_public = false AND NEW.invite_code IS NULL THEN
    NEW.invite_code := generate_invite_code();
  END IF;

  -- Clear invite code if tournament becomes public
  IF NEW.is_public = true THEN
    NEW.invite_code := NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_generate_invite_code
  BEFORE INSERT OR UPDATE ON tournaments
  FOR EACH ROW
  EXECUTE FUNCTION auto_generate_invite_code();

-- 6. Update RLS policies to allow access to private tournaments via invite code
-- Drop existing public read policy
DROP POLICY IF EXISTS "Allow public read access to tournaments" ON tournaments;

-- Create new policy that allows public tournaments OR tournaments with valid invite code
CREATE POLICY "Allow public and invited tournament access"
  ON tournaments FOR SELECT
  USING (
    is_public = true
    OR auth.uid() = organizer_id
  );

-- 7. Create a function to calculate distance between two points (Haversine formula)
-- Distance returned in kilometers
CREATE OR REPLACE FUNCTION calculate_distance(
  lat1 DOUBLE PRECISION,
  lon1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION,
  lon2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION AS $$
DECLARE
  R DOUBLE PRECISION := 6371; -- Earth's radius in kilometers
  dLat DOUBLE PRECISION;
  dLon DOUBLE PRECISION;
  a DOUBLE PRECISION;
  c DOUBLE PRECISION;
BEGIN
  -- Return NULL if any coordinate is NULL
  IF lat1 IS NULL OR lon1 IS NULL OR lat2 IS NULL OR lon2 IS NULL THEN
    RETURN NULL;
  END IF;

  dLat := radians(lat2 - lat1);
  dLon := radians(lon2 - lon1);

  a := sin(dLat/2) * sin(dLat/2) +
       cos(radians(lat1)) * cos(radians(lat2)) *
       sin(dLon/2) * sin(dLon/2);

  c := 2 * atan2(sqrt(a), sqrt(1-a));

  RETURN R * c; -- Distance in km
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 8. Add comment documentation
COMMENT ON COLUMN tournaments.is_public IS 'If true, tournament is public. If false, requires invite code.';
COMMENT ON COLUMN tournaments.invite_code IS 'Unique code for accessing private tournaments. Auto-generated.';
COMMENT ON COLUMN tournaments.latitude IS 'Tournament location latitude for geo-search';
COMMENT ON COLUMN tournaments.longitude IS 'Tournament location longitude for geo-search';

-- Migration complete!
-- Note: Existing tournaments will default to is_public=true
