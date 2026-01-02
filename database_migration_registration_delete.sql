-- Migration: Add DELETE policy for tournament_registrations
-- Run this in Supabase SQL Editor

-- Allow tournament organizers to delete registrations (remove teams)
CREATE POLICY "Allow organizers to delete registrations"
  ON tournament_registrations FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tournaments
      WHERE tournaments.id = tournament_registrations.tournament_id
      AND tournaments.organizer_id = auth.uid()
    )
  );

-- Allow team captains to withdraw their own teams
CREATE POLICY "Allow captains to delete their registrations"
  ON tournament_registrations FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM teams
      WHERE teams.id = tournament_registrations.team_id
      AND teams.captain_id = auth.uid()
    )
  );

-- Allow tournament staff (admins) to delete registrations
CREATE POLICY "Allow tournament admins to delete registrations"
  ON tournament_registrations FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tournament_staff
      WHERE tournament_staff.tournament_id = tournament_registrations.tournament_id
      AND tournament_staff.user_id = auth.uid()
      AND tournament_staff.role = 'admin'
    )
  );
