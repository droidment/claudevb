-- Migration: Add tournament_staff table for multi-admin and scorer roles
-- Run this in your Supabase SQL Editor

-- Create tournament_staff table for per-tournament role assignments
-- Allows multiple admins and scorers per tournament
CREATE TABLE IF NOT EXISTS tournament_staff (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'scorer')),
  assigned_by UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tournament_id, user_id)
);

-- Add comment for documentation
COMMENT ON TABLE tournament_staff IS 'Per-tournament staff assignments. Admin role has full tournament control (like organizer). Scorer role can only start matches and update scores.';
COMMENT ON COLUMN tournament_staff.role IS 'Staff role: admin (full control) or scorer (score entry only)';

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_tournament_staff_tournament_id ON tournament_staff(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_staff_user_id ON tournament_staff(user_id);

-- Enable Row Level Security
ALTER TABLE tournament_staff ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view staff assignments for tournaments they can see
CREATE POLICY "Allow viewing tournament staff"
  ON tournament_staff FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tournaments
      WHERE tournaments.id = tournament_staff.tournament_id
      AND (tournaments.is_public = true OR tournaments.organizer_id = auth.uid())
    )
    OR tournament_staff.user_id = auth.uid()
  );

-- Policy: Tournament organizer or admins can manage staff
CREATE POLICY "Allow organizers and admins to manage staff"
  ON tournament_staff FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tournaments
      WHERE tournaments.id = tournament_staff.tournament_id
      AND tournaments.organizer_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM tournament_staff ts
      WHERE ts.tournament_id = tournament_staff.tournament_id
      AND ts.user_id = auth.uid()
      AND ts.role = 'admin'
    )
  );

-- Policy: Tournament organizer or admins can update staff
CREATE POLICY "Allow organizers and admins to update staff"
  ON tournament_staff FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tournaments
      WHERE tournaments.id = tournament_staff.tournament_id
      AND tournaments.organizer_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM tournament_staff ts
      WHERE ts.tournament_id = tournament_staff.tournament_id
      AND ts.user_id = auth.uid()
      AND ts.role = 'admin'
    )
  );

-- Policy: Tournament organizer or admins can delete staff (but not themselves if admin)
CREATE POLICY "Allow organizers and admins to delete staff"
  ON tournament_staff FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tournaments
      WHERE tournaments.id = tournament_staff.tournament_id
      AND tournaments.organizer_id = auth.uid()
    )
    OR (
      EXISTS (
        SELECT 1 FROM tournament_staff ts
        WHERE ts.tournament_id = tournament_staff.tournament_id
        AND ts.user_id = auth.uid()
        AND ts.role = 'admin'
      )
      AND tournament_staff.user_id != auth.uid()
    )
  );

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_tournament_staff_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tournament_staff_updated_at
  BEFORE UPDATE ON tournament_staff
  FOR EACH ROW
  EXECUTE FUNCTION update_tournament_staff_updated_at();

-- Update matches RLS policy to allow scorers to update scores
-- First drop the existing policy if it exists
DROP POLICY IF EXISTS "Allow organizers to manage matches" ON matches;
DROP POLICY IF EXISTS "Allow staff to manage matches" ON matches;

-- Create new policy that includes both organizers and staff
CREATE POLICY "Allow staff to manage matches"
  ON matches FOR ALL
  TO authenticated
  USING (
    -- Tournament organizer
    EXISTS (
      SELECT 1 FROM tournaments
      WHERE tournaments.id = matches.tournament_id
      AND tournaments.organizer_id = auth.uid()
    )
    -- Or tournament admin
    OR EXISTS (
      SELECT 1 FROM tournament_staff ts
      WHERE ts.tournament_id = matches.tournament_id
      AND ts.user_id = auth.uid()
      AND ts.role = 'admin'
    )
    -- Or tournament scorer (for updates only - handled in app logic)
    OR EXISTS (
      SELECT 1 FROM tournament_staff ts
      WHERE ts.tournament_id = matches.tournament_id
      AND ts.user_id = auth.uid()
      AND ts.role = 'scorer'
    )
  );

-- Update match_sets RLS policy to allow scorers
DROP POLICY IF EXISTS "Allow organizers to manage match sets" ON match_sets;
DROP POLICY IF EXISTS "Allow staff to manage match sets" ON match_sets;

CREATE POLICY "Allow staff to manage match sets"
  ON match_sets FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM matches m
      JOIN tournaments t ON t.id = m.tournament_id
      WHERE m.id = match_sets.match_id
      AND (
        t.organizer_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM tournament_staff ts
          WHERE ts.tournament_id = t.id
          AND ts.user_id = auth.uid()
          AND ts.role IN ('admin', 'scorer')
        )
      )
    )
  );

-- Verify the table was created
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'tournament_staff'
ORDER BY ordinal_position;
