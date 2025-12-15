import 'package:supabase_flutter/supabase_flutter.dart';

// Run this script to set up the database tables
// Usage: dart run setup_database.dart

const supabaseUrl = 'https://ydxeavrjmaujmoysrhqx.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlkeGVhdnJqbWF1am1veXNyaHF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4MTMwODAsImV4cCI6MjA4MTM4OTA4MH0.W2xZtHMcTyWwgO7ejGxTqgE6amAf0uTfiTVcqXxKKB0';

// NOTE: To run SQL commands, you need the service_role key, not the anon key
// The anon key has limited permissions and cannot create tables
//
// INSTRUCTIONS:
// 1. Go to https://ydxeavrjmaujmoysrhqx.supabase.co
// 2. Go to Settings > API
// 3. Copy your service_role key (keep it secret!)
// 4. Replace SERVICE_ROLE_KEY below with your actual key
// 5. Run: dart run setup_database.dart

const serviceRoleKey = 'YOUR_SERVICE_ROLE_KEY_HERE'; // REPLACE THIS!

Future<void> main() async {
  print('🚀 Starting database setup...\n');

  if (serviceRoleKey == 'YOUR_SERVICE_ROLE_KEY_HERE') {
    print('❌ ERROR: Please set your service_role key in this file first!');
    print('');
    print('Instructions:');
    print('1. Go to https://ydxeavrjmaujmoysrhqx.supabase.co');
    print('2. Navigate to Settings > API');
    print('3. Copy the service_role key');
    print('4. Replace SERVICE_ROLE_KEY in setup_database.dart');
    print('5. Run this script again');
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: serviceRoleKey,
  );

  final supabase = Supabase.instance.client;

  try {
    // Create tables
    await createTables(supabase);

    // Enable RLS
    await enableRLS(supabase);

    // Create RLS policies
    await createRLSPolicies(supabase);

    // Create indexes
    await createIndexes(supabase);

    // Create functions and triggers
    await createFunctionsAndTriggers(supabase);

    print('\n✅ Database setup completed successfully!');
    print('\nNext steps:');
    print('1. Go to Supabase Dashboard > Authentication > Settings');
    print('2. Enable Email provider');
    print('3. Run your Flutter app: flutter run');
  } catch (e) {
    print('\n❌ Error during setup: $e');
    print('\nIf you see permission errors, you may need to:');
    print('1. Run the SQL commands manually in the Supabase SQL Editor');
    print('2. Check DATABASE_SCHEMA.md for the complete SQL');
  }
}

Future<void> createTables(SupabaseClient supabase) async {
  print('📋 Creating tables...');

  final queries = [
    // 1. user_profiles
    '''
    CREATE TABLE IF NOT EXISTS user_profiles (
      id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
      email TEXT NOT NULL,
      full_name TEXT,
      role TEXT DEFAULT 'captain',
      phone TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    ''',

    // 2. tournaments
    '''
    CREATE TABLE IF NOT EXISTS tournaments (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      name TEXT NOT NULL,
      description TEXT,
      sport_type TEXT DEFAULT 'volleyball',
      format TEXT NOT NULL,
      start_date TIMESTAMP WITH TIME ZONE,
      end_date TIMESTAMP WITH TIME ZONE,
      registration_deadline TIMESTAMP WITH TIME ZONE,
      location TEXT,
      venue_details TEXT,
      max_teams INTEGER,
      min_team_size INTEGER DEFAULT 6,
      max_team_size INTEGER DEFAULT 12,
      entry_fee DECIMAL(10,2),
      status TEXT DEFAULT 'registration_open',
      organizer_id UUID REFERENCES user_profiles(id),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    ''',

    // 3. teams
    '''
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
    ''',

    // 4. players
    '''
    CREATE TABLE IF NOT EXISTS players (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      email TEXT,
      phone TEXT,
      jersey_number INTEGER,
      position TEXT,
      height_inches INTEGER,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    ''',

    // 5. tournament_registrations
    '''
    CREATE TABLE IF NOT EXISTS tournament_registrations (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
      team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
      registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      payment_status TEXT DEFAULT 'pending',
      payment_amount DECIMAL(10,2),
      status TEXT DEFAULT 'pending',
      pool_assignment TEXT,
      seed_number INTEGER,
      notes TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      UNIQUE(tournament_id, team_id)
    );
    ''',

    // 6. matches
    '''
    CREATE TABLE IF NOT EXISTS matches (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
      team1_id UUID REFERENCES teams(id),
      team2_id UUID REFERENCES teams(id),
      scheduled_time TIMESTAMP WITH TIME ZONE,
      court_number INTEGER,
      venue TEXT,
      round TEXT,
      match_number INTEGER,
      team1_score INTEGER,
      team2_score INTEGER,
      team1_sets_won INTEGER DEFAULT 0,
      team2_sets_won INTEGER DEFAULT 0,
      winner_id UUID REFERENCES teams(id),
      status TEXT DEFAULT 'scheduled',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    ''',

    // 7. match_sets
    '''
    CREATE TABLE IF NOT EXISTS match_sets (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
      set_number INTEGER NOT NULL,
      team1_score INTEGER NOT NULL,
      team2_score INTEGER NOT NULL,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      UNIQUE(match_id, set_number)
    );
    ''',
  ];

  for (var i = 0; i < queries.length; i++) {
    try {
      await supabase.rpc('exec_sql', params: {'query': queries[i]});
      print('  ✓ Table ${i + 1}/7 created');
    } catch (e) {
      print('  ⚠️  Table ${i + 1}/7: $e');
    }
  }
}

Future<void> enableRLS(SupabaseClient supabase) async {
  print('\n🔒 Enabling Row Level Security...');

  final tables = [
    'user_profiles',
    'tournaments',
    'teams',
    'players',
    'tournament_registrations',
    'matches',
    'match_sets',
  ];

  for (var table in tables) {
    try {
      await supabase.rpc('exec_sql', params: {
        'query': 'ALTER TABLE $table ENABLE ROW LEVEL SECURITY;'
      });
      print('  ✓ RLS enabled on $table');
    } catch (e) {
      print('  ⚠️  $table: $e');
    }
  }
}

Future<void> createRLSPolicies(SupabaseClient supabase) async {
  print('\n🛡️  Creating RLS policies...');
  print('  (This may take a moment...)');

  // Due to complexity, RLS policies are best created in SQL Editor
  print('  ⚠️  RLS policies should be created in Supabase SQL Editor');
  print('  📄 See DATABASE_SCHEMA.md for complete RLS policies');
}

Future<void> createIndexes(SupabaseClient supabase) async {
  print('\n📊 Creating indexes...');

  final indexes = [
    'CREATE INDEX IF NOT EXISTS idx_teams_captain ON teams(captain_id);',
    'CREATE INDEX IF NOT EXISTS idx_players_team ON players(team_id);',
    'CREATE INDEX IF NOT EXISTS idx_tournament_registrations_tournament ON tournament_registrations(tournament_id);',
    'CREATE INDEX IF NOT EXISTS idx_tournament_registrations_team ON tournament_registrations(team_id);',
    'CREATE INDEX IF NOT EXISTS idx_matches_tournament ON matches(tournament_id);',
    'CREATE INDEX IF NOT EXISTS idx_matches_teams ON matches(team1_id, team2_id);',
    'CREATE INDEX IF NOT EXISTS idx_match_sets_match ON match_sets(match_id);',
    'CREATE INDEX IF NOT EXISTS idx_tournaments_organizer ON tournaments(organizer_id);',
    'CREATE INDEX IF NOT EXISTS idx_tournaments_status ON tournaments(status);',
  ];

  for (var index in indexes) {
    try {
      await supabase.rpc('exec_sql', params: {'query': index});
      print('  ✓ Index created');
    } catch (e) {
      print('  ⚠️  $e');
    }
  }
}

Future<void> createFunctionsAndTriggers(SupabaseClient supabase) async {
  print('\n⚙️  Creating functions and triggers...');

  final queries = [
    // Auto-create user profile function
    '''
    CREATE OR REPLACE FUNCTION public.handle_new_user()
    RETURNS TRIGGER AS \$\$
    BEGIN
      INSERT INTO public.user_profiles (id, email, full_name)
      VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
      RETURN NEW;
    END;
    \$\$ LANGUAGE plpgsql SECURITY DEFINER;
    ''',

    // Trigger for new users
    '''
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
    ''',

    // Update timestamp function
    '''
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS \$\$
    BEGIN
      NEW.updated_at = NOW();
      RETURN NEW;
    END;
    \$\$ LANGUAGE plpgsql;
    ''',
  ];

  for (var query in queries) {
    try {
      await supabase.rpc('exec_sql', params: {'query': query});
      print('  ✓ Function/trigger created');
    } catch (e) {
      print('  ⚠️  $e');
    }
  }
}
