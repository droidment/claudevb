# Tournament Scheduler - AI Coding Guidelines

## Architecture Overview
This is a Flutter application for managing volleyball and pickleball tournaments using Supabase as the backend. The app follows a role-based system with Team Captains and Tournament Organizers.

**Key Components:**
- **Models** (`lib/models/`): Data classes with `fromJson`/`toJson` for Supabase integration (e.g., `UserProfile`, `Tournament`)
- **Services** (`lib/services/`): Business logic, e.g., `AuthService` handles authentication and user profile management
- **Screens** (`lib/screens/`): UI components with role-based navigation
- **Core** (`lib/core/`): Global Supabase client instance
- **Config** (`lib/config/`): Supabase credentials (hardcoded for development)

**Data Flow:** Flutter app ↔ Supabase PostgreSQL with RLS policies. Authentication via Supabase Auth, data via Supabase client queries.

## Critical Workflows
- **Database Setup**: Execute SQL from `DATABASE_SCHEMA.md` in Supabase SQL Editor, or use `setup_database.js` (requires service key) or `setup_database.dart`
- **Build & Run**: `flutter pub get` then `flutter run -d chrome` (web) or `flutter run` (emulator)
- **Authentication**: Use `AuthService` for signup/signin; profiles auto-created in `user_profiles` table
- **Role-Based Logic**: Check `UserProfile.isCaptain`, `isOrganizer` for UI/permissions

## Project-Specific Patterns
- **Supabase Queries**: Use `supabase.from('table').select().eq('column', value)`; handle responses with `fromJson`
- **Auth State**: Listen to `supabase.auth.onAuthStateChange` stream for login/logout
- **Models**: Include `created_at`/`updated_at` timestamps; use UUID primary keys
- **Error Handling**: Rethrow exceptions from services; UI handles via try/catch
- **Navigation**: Role-based routes; use `AuthWrapper` for initial screen based on auth state

## Integration Points
- **Supabase**: All backend operations; configure URL/anon key in `supabase_config.dart`
- **External Dependencies**: Only `supabase_flutter: ^2.8.0`; no other major packages
- **Database Schema**: 7 tables with RLS; tournaments support 4 formats (round robin, single/double elimination, pool play)

Reference: [README.md](README.md) for setup; [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) for schema details.</content>
<parameter name="filePath">c:\Users\Raj\Projects\ClaudeVBTournament\tournament_app\.github\copilot-instructions.md