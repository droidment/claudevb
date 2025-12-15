-- ================================================================
-- Tournament Scheduler - Complete Database Setup
-- ================================================================
--
-- INSTRUCTIONS:
-- 1. Go to https://ydxeavrjmaujmoysrhqx.supabase.co
-- 2. Navigate to SQL Editor (left sidebar)
-- 3. Click "New Query"
-- 4. Copy this ENTIRE file and paste it
-- 5. Click "Run" or press Cmd/Ctrl + Enter
--
-- This will create all tables, policies, indexes, and triggers
-- ================================================================

-- ================================================================
-- TABLES
-- ================================================================

-- 1. User Profiles
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'captain', -- captain, organizer, admin
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tournaments
CREATE TABLE IF NOT EXISTS tournaments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  sport_type TEXT DEFAULT 'volleyball', -- volleyball, pickleball
  format TEXT NOT NULL, -- round_robin, single_elimination, double_elimination, pool_play
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  registration_deadline TIMESTAMP WITH TIME ZONE,
  location TEXT,
  venue_details TEXT,
  max_teams INTEGER,
  min_team_size INTEGER DEFAULT 6,
  max_team_size INTEGER DEFAULT 12,
  entry_fee DECIMAL(10,2),
  status TEXT DEFAULT 'registration_open', -- registration_open, registration_closed, ongoing, completed, cancelled
  organizer_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Teams
CREATE TABLE IF NOT EXISTS teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  captain_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  logo_url TEXT,
  home_city TEXT,
  team_color TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(name, captain_id)
);

-- 4. Players (Roster)
CREATE TABLE IF NOT EXISTS players (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  jersey_number INTEGER,
  position TEXT, -- setter, outside_hitter, middle_blocker, libero, opposite, defensive_specialist
  height_inches INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Tournament Registrations
CREATE TABLE IF NOT EXISTS tournament_registrations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  payment_status TEXT DEFAULT 'pending', -- pending, paid, refunded
  payment_amount DECIMAL(10,2),
  status TEXT DEFAULT 'pending', -- pending, approved, rejected, withdrawn
  pool_assignment TEXT, -- for pool play format (A, B, C, etc.)
  seed_number INTEGER, -- for seeding teams
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(tournament_id, team_id)
);

-- 6. Matches
CREATE TABLE IF NOT EXISTS matches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
  team1_id UUID REFERENCES teams(id),
  team2_id UUID REFERENCES teams(id),
  scheduled_time TIMESTAMP WITH TIME ZONE,
  court_number INTEGER,
  venue TEXT,
  round TEXT, -- pool_round_1, quarterfinal, semifinal, final, 3rd_place, etc.
  match_number INTEGER,
  team1_score INTEGER,
  team2_score INTEGER,
  team1_sets_won INTEGER DEFAULT 0,
  team2_sets_won INTEGER DEFAULT 0,
  winner_id UUID REFERENCES teams(id),
  status TEXT DEFAULT 'scheduled', -- scheduled, in_progress, completed, cancelled
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Match Sets (for tracking individual set scores)
CREATE TABLE IF NOT EXISTS match_sets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
  set_number INTEGER NOT NULL,
  team1_score INTEGER NOT NULL,
  team2_score INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(match_id, set_number)
);

-- ================================================================
-- ENABLE ROW LEVEL SECURITY
-- ================================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_sets ENABLE ROW LEVEL SECURITY;

-- ================================================================
-- RLS POLICIES
-- ================================================================

-- User Profiles Policies
CREATE POLICY "Allow users to read all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow users to insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Allow users to update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Tournaments Policies
CREATE POLICY "Allow public read access to tournaments"
  ON tournaments FOR SELECT
  USING (true);

CREATE POLICY "Allow organizers to create tournaments"
  ON tournaments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('organizer', 'admin')
    )
  );

CREATE POLICY "Allow organizers to update own tournaments"
  ON tournaments FOR UPDATE
  TO authenticated
  USING (auth.uid() = organizer_id);

-- Teams Policies
CREATE POLICY "Allow public read access to teams"
  ON teams FOR SELECT
  USING (true);

CREATE POLICY "Allow captains to create teams"
  ON teams FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = captain_id);

CREATE POLICY "Allow captains to update own teams"
  ON teams FOR UPDATE
  TO authenticated
  USING (auth.uid() = captain_id);

CREATE POLICY "Allow captains to delete own teams"
  ON teams FOR DELETE
  TO authenticated
  USING (auth.uid() = captain_id);

-- Players Policies
CREATE POLICY "Allow public read access to players"
  ON players FOR SELECT
  USING (true);

CREATE POLICY "Allow captains to manage their roster"
  ON players FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM teams
      WHERE teams.id = players.team_id
      AND teams.captain_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM teams
      WHERE teams.id = players.team_id
      AND teams.captain_id = auth.uid()
    )
  );

-- Tournament Registrations Policies
CREATE POLICY "Allow public read access to registrations"
  ON tournament_registrations FOR SELECT
  USING (true);

CREATE POLICY "Allow captains to register teams"
  ON tournament_registrations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM teams
      WHERE teams.id = tournament_registrations.team_id
      AND teams.captain_id = auth.uid()
    )
  );

CREATE POLICY "Allow captains to update registrations"
  ON tournament_registrations FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM teams
      WHERE teams.id = tournament_registrations.team_id
      AND teams.captain_id = auth.uid()
    )
  );

CREATE POLICY "Allow organizers to manage registrations"
  ON tournament_registrations FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tournaments
      WHERE tournaments.id = tournament_registrations.tournament_id
      AND tournaments.organizer_id = auth.uid()
    )
  );

-- Matches Policies
CREATE POLICY "Allow public read access to matches"
  ON matches FOR SELECT
  USING (true);

CREATE POLICY "Allow organizers to manage matches"
  ON matches FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tournaments
      WHERE tournaments.id = matches.tournament_id
      AND tournaments.organizer_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tournaments
      WHERE tournaments.id = matches.tournament_id
      AND tournaments.organizer_id = auth.uid()
    )
  );

-- Match Sets Policies
CREATE POLICY "Allow public read access to match sets"
  ON match_sets FOR SELECT
  USING (true);

CREATE POLICY "Allow organizers to manage match sets"
  ON match_sets FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM matches
      JOIN tournaments ON tournaments.id = matches.tournament_id
      WHERE matches.id = match_sets.match_id
      AND tournaments.organizer_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM matches
      JOIN tournaments ON tournaments.id = matches.tournament_id
      WHERE matches.id = match_sets.match_id
      AND tournaments.organizer_id = auth.uid()
    )
  );

-- ================================================================
-- INDEXES
-- ================================================================

CREATE INDEX IF NOT EXISTS idx_teams_captain ON teams(captain_id);
CREATE INDEX IF NOT EXISTS idx_players_team ON players(team_id);
CREATE INDEX IF NOT EXISTS idx_tournament_registrations_tournament ON tournament_registrations(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_registrations_team ON tournament_registrations(team_id);
CREATE INDEX IF NOT EXISTS idx_matches_tournament ON matches(tournament_id);
CREATE INDEX IF NOT EXISTS idx_matches_teams ON matches(team1_id, team2_id);
CREATE INDEX IF NOT EXISTS idx_match_sets_match ON match_sets(match_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_organizer ON tournaments(organizer_id);
CREATE INDEX IF NOT EXISTS idx_tournaments_status ON tournaments(status);

-- ================================================================
-- FUNCTIONS AND TRIGGERS
-- ================================================================

-- Auto-create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tournaments_updated_at BEFORE UPDATE ON tournaments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON teams
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_players_updated_at BEFORE UPDATE ON players
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tournament_registrations_updated_at BEFORE UPDATE ON tournament_registrations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_matches_updated_at BEFORE UPDATE ON matches
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ================================================================
-- SETUP COMPLETE!
-- ================================================================
--
-- Next steps:
-- 1. Go to Authentication > Settings in your Supabase dashboard
-- 2. Enable the Email provider
-- 3. Run your Flutter app: flutter run
--
-- ================================================================
