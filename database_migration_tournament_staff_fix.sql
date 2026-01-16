-- Fix: Remove infinite recursion in tournament_staff RLS policies
-- Run this in your Supabase SQL Editor AFTER the initial migration
-- Or run this as a standalone fix if you already ran the initial migration

-- Drop the problematic policies
DROP POLICY IF EXISTS "Allow organizers and admins to manage staff" ON tournament_staff;
DROP POLICY IF EXISTS "Allow organizers and admins to update staff" ON tournament_staff;
DROP POLICY IF EXISTS "Allow organizers and admins to delete staff" ON tournament_staff;

-- Simplified policies: Only tournament organizer can manage staff
-- This avoids the infinite recursion issue and is a cleaner security model

-- Policy: Only tournament organizer can INSERT staff
CREATE POLICY "Allow organizers to insert staff"
  ON tournament_staff FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tournaments
      WHERE tournaments.id = tournament_staff.tournament_id
      AND tournaments.organizer_id = auth.uid()
    )
  );

-- Policy: Only tournament organizer can UPDATE staff
CREATE POLICY "Allow organizers to update staff"
  ON tournament_staff FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tournaments
      WHERE tournaments.id = tournament_staff.tournament_id
      AND tournaments.organizer_id = auth.uid()
    )
  );

-- Policy: Only tournament organizer can DELETE staff
CREATE POLICY "Allow organizers to delete staff"
  ON tournament_staff FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tournaments
      WHERE tournaments.id = tournament_staff.tournament_id
      AND tournaments.organizer_id = auth.uid()
    )
  );

-- Verify policies are correctly set up
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'tournament_staff';
