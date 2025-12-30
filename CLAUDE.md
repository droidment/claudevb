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
- `lib/services/` - Business logic layer (auth, teams, tournaments)
- `lib/screens/` - UI components organized by feature (auth, teams, tournaments)

### Data Flow Pattern
1. **UI (Screens)** → calls **Services** → uses **Supabase Client** → **PostgreSQL with RLS**
2. All Supabase operations return raw JSON, converted via model `fromJson` methods
3. Authentication via `supabase.auth`, data via `supabase.from('table')` queries

### Key Services
- **AuthService** (`lib/services/auth_service.dart`) - Handles signup/signin, user profiles
- **TeamService** (`lib/services/team_service.dart`) - Team CRUD, player management, CSV import
- **TournamentService** (`lib/services/tournament_service.dart`) - Tournament CRUD, team registration, invite codes

### Models Pattern
All models in `lib/models/` follow this pattern:
- UUID primary keys (`id`)
- Timestamp fields: `created_at`, `updated_at`
- Factory constructor `fromJson(Map<String, dynamic>)`
- Method `toJson()` for serialization
- Method `toInsertJson()` for database inserts (excludes id/timestamps)
- Enums with extensions for `displayName`, `dbValue`, and `fromString()`

### Database Schema (Supabase)
7 tables with Row Level Security (RLS):
1. `user_profiles` - User accounts with roles (captain, organizer, admin)
2. `tournaments` - Tournament details, formats, geo-location, privacy settings
3. `teams` - Teams with extended CSV import fields (captain info, payment, lunch counts)
4. `players` - Player rosters with volleyball positions
5. `tournament_registrations` - Team registrations with pool/seed assignments
6. `matches` - Match schedules and scores
7. `match_sets` - Individual set scores

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

Check `UserProfile.isCaptain`, `isOrganizer`, `isAdmin` for permission logic.

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

## Database Setup

Before running the app, execute SQL migrations in Supabase SQL Editor:

1. Run all SQL from `tournament_app/DATABASE_SCHEMA.md` (creates tables, RLS, triggers)
2. Run `database_migration_privacy_geolocation.sql` (adds privacy/geo features)
3. Run `database_migration_team_extended_fields.sql` (adds CSV import fields to teams)
4. Enable Email provider in Supabase Dashboard → Authentication → Settings

Alternative: Use `setup_database.js` (requires Node.js and Supabase service key).

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

## Important Copilot Instructions

From `tournament_app/.github/copilot-instructions.md`:
- All backend operations use Supabase client
- Models include `created_at`/`updated_at` timestamps with UUID primary keys
- Services rethrow exceptions; UI handles via try/catch
- Role-based logic checks `UserProfile` role properties
- Use `AuthService` for all authentication operations
