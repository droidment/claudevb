# Tournament Scheduler Database Schema

## Suggested Tables for Supabase

### 1. user_profiles
```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'captain', -- captain, organizer, admin
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. tournaments
```sql
CREATE TABLE tournaments (
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
```

### 3. teams
```sql
CREATE TABLE teams (
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
```

### 4. players (roster)
```sql
CREATE TABLE players (
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
```

### 5. tournament_registrations
```sql
CREATE TABLE tournament_registrations (
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
```

### 6. matches
```sql
CREATE TABLE matches (
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
```

### 7. match_sets (for tracking individual set scores)
```sql
CREATE TABLE match_sets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
  set_number INTEGER NOT NULL,
  team1_score INTEGER NOT NULL,
  team2_score INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(match_id, set_number)
);
```

## Row Level Security (RLS) Policies

### Enable RLS
```sql
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_sets ENABLE ROW LEVEL SECURITY;
```

### User Profiles Policies
```sql
-- Users can read all profiles
CREATE POLICY "Allow users to read all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (true);

-- Users can insert their own profile
CREATE POLICY "Allow users to insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Allow users to update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);
```

### Tournaments Policies
```sql
-- Anyone can view tournaments
CREATE POLICY "Allow public read access to tournaments"
  ON tournaments FOR SELECT
  USING (true);

-- Organizers can create tournaments
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

-- Organizers can update their own tournaments
CREATE POLICY "Allow organizers to update own tournaments"
  ON tournaments FOR UPDATE
  TO authenticated
  USING (auth.uid() = organizer_id);
```

### Teams Policies
```sql
-- Anyone can view teams
CREATE POLICY "Allow public read access to teams"
  ON teams FOR SELECT
  USING (true);

-- Captains can create teams
CREATE POLICY "Allow captains to create teams"
  ON teams FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = captain_id);

-- Captains can update their own teams
CREATE POLICY "Allow captains to update own teams"
  ON teams FOR UPDATE
  TO authenticated
  USING (auth.uid() = captain_id);

-- Captains can delete their own teams
CREATE POLICY "Allow captains to delete own teams"
  ON teams FOR DELETE
  TO authenticated
  USING (auth.uid() = captain_id);
```

### Players Policies
```sql
-- Anyone can view players
CREATE POLICY "Allow public read access to players"
  ON players FOR SELECT
  USING (true);

-- Team captains can manage their team's roster
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
```

### Tournament Registrations Policies
```sql
-- Anyone can view registrations
CREATE POLICY "Allow public read access to registrations"
  ON tournament_registrations FOR SELECT
  USING (true);

-- Team captains can register their teams
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

-- Team captains can update their registrations
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

-- Tournament organizers can approve/manage registrations
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
```

### Matches Policies
```sql
-- Anyone can view matches
CREATE POLICY "Allow public read access to matches"
  ON matches FOR SELECT
  USING (true);

-- Organizers can manage matches for their tournaments
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
```

### Match Sets Policies
```sql
-- Anyone can view match sets
CREATE POLICY "Allow public read access to match sets"
  ON match_sets FOR SELECT
  USING (true);

-- Organizers can manage sets for their tournament matches
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
```

## Indexes (Recommended for Performance)
```sql
CREATE INDEX idx_teams_captain ON teams(captain_id);
CREATE INDEX idx_players_team ON players(team_id);
CREATE INDEX idx_tournament_registrations_tournament ON tournament_registrations(tournament_id);
CREATE INDEX idx_tournament_registrations_team ON tournament_registrations(team_id);
CREATE INDEX idx_matches_tournament ON matches(tournament_id);
CREATE INDEX idx_matches_teams ON matches(team1_id, team2_id);
CREATE INDEX idx_match_sets_match ON match_sets(match_id);
CREATE INDEX idx_tournaments_organizer ON tournaments(organizer_id);
CREATE INDEX idx_tournaments_status ON tournaments(status);
```

## Functions and Triggers

### Auto-create user profile on signup
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Update updated_at timestamp
```sql
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
```

## Next Steps

1. Go to your Supabase Dashboard: https://ydxeavrjmaujmoysrhqx.supabase.co
2. Navigate to the SQL Editor
3. Copy and run all SQL commands from this file in order:
   - Create tables (sections 1-7)
   - Enable RLS (section: Enable RLS)
   - Create RLS policies (all policy sections)
   - Create indexes
   - Create functions and triggers
4. Enable Email authentication in Supabase Auth settings

## Tournament Formats Supported

### 1. Round Robin
- Every team plays every other team once
- Winner determined by win/loss record
- Good for: Smaller tournaments (4-8 teams)

### 2. Single Elimination
- Lose once and you're out
- Fast tournament format
- Good for: Large tournaments, time constraints

### 3. Double Elimination
- Teams get a second chance (winners/losers bracket)
- More games per team
- Good for: Competitive tournaments

### 4. Pool Play
- Teams divided into pools
- Round robin within pools
- Top teams advance to playoffs
- Good for: Large tournaments (12+ teams)
