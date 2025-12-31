# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter application for managing volleyball and pickleball tournaments with Supabase backend. Supports multiple tournament formats, team management, player rosters, and role-based access (Team Captains and Tournament Organizers).

## Common Commands

### Development
```bash
cd tournament_app
flutter pub get                    # Install dependencies
flutter run -d chrome              # Run on Chrome (web)
flutter run                        # Run on default device
flutter devices                    # List available devices
flutter run -d <device_id>         # Run on specific device
```

### Build
```bash
flutter build apk --release        # Android APK
flutter build ios --release        # iOS
flutter build web --release        # Web
```

### Testing
```bash
flutter test                       # Run tests
flutter test --coverage            # Run with coverage
```

### Maintenance
```bash
flutter clean                      # Clean build artifacts
flutter pub upgrade                # Update dependencies
flutter --version                  # Check Flutter version
```

## Architecture

### Directory Structure
- `lib/config/` - Supabase credentials (hardcoded for development)
- `lib/core/` - Global Supabase client instance (`supabase_client.dart`)
- `lib/models/` - Data models with `fromJson`/`toJson` for Supabase integration
- `lib/services/` - Business logic layer (auth, teams, tournaments, matches)
- `lib/screens/` - UI components organized by feature (auth, teams, tournaments, matches)

### Data Flow Pattern
1. **UI (Screens)** → calls **Services** → uses **Supabase Client** → **PostgreSQL with RLS**
2. All Supabase operations return raw JSON, converted via model `fromJson` methods
3. Authentication via `supabase.auth`, data via `supabase.from('table')` queries

### Key Services
- **AuthService** (`lib/services/auth_service.dart`) - Handles signup/signin, user profiles
- **TeamService** (`lib/services/team_service.dart`) - Team CRUD, player management, CSV import, sport type filtering
- **TournamentService** (`lib/services/tournament_service.dart`) - Tournament CRUD, team registration, invite codes
- **MatchService** (`lib/services/match_service.dart`) - Match CRUD, set scores, winner calculation
- **RoundRobinGenerator** (`lib/services/round_robin_generator.dart`) - Round robin match generation algorithm
- **TournamentStaffService** (`lib/services/tournament_staff_service.dart`) - Staff role management (admins/scorers)

### Models Pattern
All models in `lib/models/` follow this pattern:
- UUID primary keys (`id`)
- Timestamp fields: `created_at`, `updated_at`
- Factory constructor `fromJson(Map<String, dynamic>)`
- Method `toJson()` for serialization
- Method `toInsertJson()` for database inserts (excludes id/timestamps)
- Enums with extensions for `displayName`, `dbValue`, and `fromString()`

### Database Schema (Supabase)
8 tables with Row Level Security (RLS):
1. `user_profiles` - User accounts with roles (captain, organizer, admin)
2. `tournaments` - Tournament details, formats, geo-location, privacy settings, scoring config
3. `teams` - Teams with sport_type, extended CSV import fields (captain info, payment, lunch counts)
4. `players` - Player rosters with volleyball positions
5. `tournament_registrations` - Team registrations with pool/seed assignments, lunch counts
6. `matches` - Match schedules and scores
7. `match_sets` - Individual set scores
8. `tournament_staff` - Per-tournament admin and scorer role assignments

**Important**: Database triggers auto-create user profiles on signup and auto-generate invite codes for private tournaments.

### Tournament Formats Supported
- `round_robin` - Every team plays every other team
- `single_elimination` - Knockout tournament
- `double_elimination` - Winners and losers brackets
- `pool_play` - Pool play with playoff advancement
- `pool_play_to_leagues` - Pool play followed by tiered leagues (Advanced/Intermediate/Recreational)

### Role-Based Access
- **Team Captain** (`isCaptain`): Manage teams, add players, register for tournaments
- **Tournament Organizer** (`isOrganizer`): Create tournaments, approve registrations, manage matches
- **Admin** (`isAdmin`): All permissions

#### Per-Tournament Staff Roles
Tournament organizers can assign additional staff via `tournament_staff` table:
- **Tournament Admin**: Full tournament control (like organizer) - can manage teams, generate schedules, update scores
- **Scorer**: Can only start matches and update scores - cannot modify tournament settings or teams

Check `TournamentPermissions` class for permission logic:
- `canManageTournament`: Owner or admin role
- `canManageScores`: Owner, admin, or scorer role

### Authentication Flow
1. Entry point: `AuthWrapper` in `main.dart` listens to `supabase.auth.onAuthStateChange`
2. If session exists → `HomeScreen`, else → `LoginScreen`
3. Signup/signin via `AuthService` methods
4. Database trigger auto-creates `user_profiles` record on signup
5. Role stored in `user_profiles.role` field

### Supabase Integration
- Client initialized in `main.dart` with URL/anon key from `supabase_config.dart`
- Global client: `supabase` from `lib/core/supabase_client.dart`
- Query pattern: `await supabase.from('table').select().eq('column', value)`
- Always handle errors in services by rethrowing exceptions; UI handles via try/catch

### CSV Import Feature
`TeamService.importTeams()` supports importing teams from CSV with these fields:
- Team name, captain contact info, player count, payment status, lunch counts
- Uses `CsvTeamImport.fromCsvRow()` to parse CSV format
- Expected columns documented in `lib/models/team.dart:224`

### Geo-Location Features
- Tournaments have optional `latitude`/`longitude` fields
- Client-side distance calculation via `Tournament.distanceFrom(lat, lon)` (Haversine formula)
- Database function `calculate_distance()` available for server-side filtering

### Privacy & Invite System
- Tournaments can be public (`is_public: true`) or private (`is_public: false`)
- Private tournaments auto-generate unique `invite_code` (8-char alphanumeric)
- Access via `TournamentService.getTournamentByInviteCode(code)`
- RLS policy allows viewing public tournaments OR tournaments you organize

## Round Robin Tournament System (NEW)

### Overview
Complete round robin match generation and management system for tournaments. Supports round_robin, pool_play, and pool_play_to_leagues formats.

### New Files Created
- `lib/models/match.dart` - Match model with status, scores, sets won, winner tracking
- `lib/models/match_set.dart` - Individual set scores with volleyball validation
- `lib/services/match_service.dart` - Match/set CRUD, winner calculation
- `lib/services/round_robin_generator.dart` - Circle method algorithm for match generation
- `lib/screens/matches/matches_screen.dart` - Tournament schedule viewer
- `lib/screens/matches/match_detail_screen.dart` - Score entry with sets

### Round Robin Algorithm (Circle Method)
Located in `RoundRobinGenerator.generateMatches()`:
- Generates n*(n-1)/2 matches for n teams
- Handles odd number of teams with BYE
- Auto-schedules matches across multiple courts
- Tracks court availability to minimize wait times

### Match Generation Flow
1. Tournament Detail Screen → "Generate Schedule" button (for organizers)
2. Configuration dialog: start time, match duration, number of courts
3. `RoundRobinGenerator.generateMatches()` creates match data
4. `MatchService.createMatches()` batch inserts to database
5. Navigate to MatchesScreen to view schedule

### Score Entry Flow
1. MatchesScreen shows all matches grouped by round
2. Tap match → MatchDetailScreen
3. Add sets with team scores
4. Auto-calculates sets won and match winner
5. Auto-completes match when best-of-N threshold reached

### Key Methods
- `RoundRobinGenerator.generateMatches()` - Generate all round robin pairings
- `RoundRobinGenerator.calculateTotalMatches(n)` - Returns n*(n-1)/2
- `MatchService.calculateMatchWinner(matchId)` - Recalculates winner from sets
- `MatchService.hasTournamentMatches(tournamentId)` - Check if matches exist

### Testing the Round Robin Feature
1. Run app: `cd tournament_app && flutter run -d chrome`
2. Login: raj@gmail.com / raj123
3. Create or open a tournament (Round Robin, Pool Play, or Pool Play to Leagues)
4. Add at least 3-4 teams
5. Click "Generate Schedule" button
6. Configure: start time, match duration (30-120 min), courts (1-8)
7. View generated matches in schedule screen
8. Tap any match to add set scores

### Current Status
- ✅ Match/MatchSet models complete
- ✅ MatchService complete
- ✅ RoundRobinGenerator complete (circle method algorithm)
- ✅ Generate Schedule dialog with configuration
- ✅ MatchesScreen with round grouping and filters
- ✅ MatchDetailScreen with set-by-set scoring
- ✅ Auto-calculation of winners
- ⚠️ Needs testing with live Supabase (was getting connection timeout)

### Future Enhancements
- Pool-aware generation (generate round robin within each pool separately)
- Bracket visualization for elimination formats
- Standings/leaderboard calculation
- Export schedule to PDF/CSV

## Database Setup

Before running the app, execute SQL migrations in Supabase SQL Editor:

1. Run all SQL from `tournament_app/DATABASE_SCHEMA.md` (creates tables, RLS, triggers)
2. Run `database_migration_privacy_geolocation.sql` (adds privacy/geo features)
3. Run `database_migration_team_extended_fields.sql` (adds CSV import fields to teams)
4. Run `database_migration_tournament_staff.sql` (adds tournament staff table for multi-admin)
5. Run `database_migration_tournament_staff_fix.sql` (fixes RLS infinite recursion)
6. Run `database_migration_team_sport_type.sql` (adds sport_type to teams)
7. Enable Email provider in Supabase Dashboard → Authentication → Settings

Alternative: Use `setup_database.js` (requires Node.js and Supabase service key).

**Note**: If Supabase shows connection timeout, check if the project is paused in the Supabase dashboard (free tier pauses after 7 days of inactivity).

## Project-Specific Notes

### Supabase Credentials
Located in `tournament_app/lib/config/supabase_config.dart` - hardcoded for development. For production, use environment variables.

### Dependencies
Core: `supabase_flutter: ^2.8.0`
Additional: `geolocator`, `geocoding`, `file_picker` (for CSV import)

### Error Handling Pattern
Services throw exceptions, screens catch and display to user:
```dart
try {
  await service.doSomething();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

### State Management
Currently using vanilla Flutter state management (StatefulWidget, setState). No external state management library.

### Navigation
Route-based navigation with named routes in `main.dart`. Auth state determines initial route via `AuthWrapper`.

## Tournament Staff System

### Overview
Allows tournament organizers to assign additional admins and scorers per tournament.

### Key Files
- `lib/models/tournament_staff.dart` - TournamentStaff model with StaffRole enum
- `lib/services/tournament_staff_service.dart` - CRUD operations for staff assignments
- `lib/screens/tournaments/manage_staff_screen.dart` - UI for managing staff

### Database Migration
Run `database_migration_tournament_staff.sql` to create the `tournament_staff` table with RLS policies.

If you encounter "infinite recursion detected in policy" error, run `database_migration_tournament_staff_fix.sql` to fix RLS policies (simplifies to organizer-only management).

### Permission Hierarchy
1. **Owner** (tournament.organizer_id): Full control, can add/remove staff
2. **Admin** (tournament_staff.role = 'admin'): Full tournament control except staff management
3. **Scorer** (tournament_staff.role = 'scorer'): Can only update match scores

## Team Sport Type Filtering

### Overview
Teams have a `sport_type` field ('volleyball' or 'pickleball'). When adding teams to a tournament, only teams matching the tournament's sport type are shown.

### Database Migration
Run `database_migration_team_sport_type.sql` to add the `sport_type` column to the teams table.

### Implementation
- `Team.sportType` field with default 'volleyball'
- `TeamService.createTeam()` accepts `sportType` parameter
- `TournamentService.getAvailableTeams()` filters by sport type
- `AddTeamsScreen` displays sport type filter info in header

## Scoring Configuration

### Overview
Phase-based scoring configuration for tournaments. Different scoring rules can be set for pool play, quarter-finals, semi-finals, and finals.

### Key Files
- `lib/models/scoring_config.dart` - TournamentScoringConfig and PhaseScoringConfig models
- `lib/screens/tournaments/scoring_config_screen.dart` - UI for configuring scoring rules

### Phase Types
- Pool Play
- Quarter Finals
- Semi Finals
- Finals

### Configurable Options (per phase)
- Sets to win (best of 1, 3, or 5)
- Points to win per set
- Win by 2 requirement
- Point cap (optional)
- Tiebreaker set rules

## Important Copilot Instructions

From `tournament_app/.github/copilot-instructions.md`:
- All backend operations use Supabase client
- Models include `created_at`/`updated_at` timestamps with UUID primary keys
- Services rethrow exceptions; UI handles via try/catch
- Role-based logic checks `UserProfile` role properties
- Use `AuthService` for all authentication operations
