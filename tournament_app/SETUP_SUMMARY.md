# Volleyball Tournament App - Setup Summary

## What's Been Built

### 1. **Database Schema** (`DATABASE_SCHEMA.md`)
Complete PostgreSQL schema with:
- **7 Tables**: user_profiles, tournaments, teams, players, tournament_registrations, matches, match_sets
- **Row Level Security (RLS)**: Secure policies for captains, organizers, and public access
- **Triggers**: Auto-create user profiles on signup, auto-update timestamps
- **Indexes**: Optimized for performance
- **Tournament Formats**: Round Robin, Single Elimination, Double Elimination, Pool Play

### 2. **Model Classes** (`lib/models/`)
- `user_profile.dart` - User accounts with roles (captain, organizer, admin)
- `team.dart` - Team information with captain ownership
- `player.dart` - Player roster with volleyball positions
- `tournament.dart` - Tournament with multiple format support
- `tournament_registration.dart` - Team registration for tournaments

### 3. **Services** (`lib/services/`)
- `auth_service.dart` - Complete authentication service
  - Sign up with role selection
  - Sign in / Sign out
  - Password reset
  - User profile management

### 4. **Configuration**
- Supabase integrated and configured
- Project structure organized with folders:
  - `config/` - Configuration files
  - `core/` - Core utilities
  - `models/` - Data models
  - `services/` - Business logic
  - `screens/` - UI screens (ready for implementation)
  - `widgets/` - Reusable widgets (ready for implementation)

## Key Features Designed

### For Team Captains:
✅ Sign up and login
✅ Create and manage teams
✅ Add/edit player roster (with volleyball positions)
✅ Register teams for tournaments
✅ View tournament schedules and brackets

### For Tournament Organizers:
✅ Create tournaments with multiple formats
✅ Set registration deadlines, fees, team size limits
✅ Approve/reject team registrations
✅ Manage tournament brackets and schedules
✅ Update match scores

### Tournament Formats Supported:
1. **Round Robin** - Every team plays each other
2. **Single Elimination** - Knockout tournament
3. **Double Elimination** - Winners and losers brackets
4. **Pool Play** - Pools with playoff advancement

## Next Steps to Complete the App

### 1. Set Up Database (REQUIRED FIRST)
Go to https://ydxeavrjmaujmoysrhqx.supabase.co and run all SQL from `DATABASE_SCHEMA.md`

### 2. Build UI Screens (Remaining Work)
- [ ] Login/Signup screens
- [ ] Home dashboard (role-based)
- [ ] Team creation and management
- [ ] Player roster management
- [ ] Tournament creation (organizers)
- [ ] Tournament list and details
- [ ] Team registration flow
- [ ] Match schedules and brackets
- [ ] Live score updates

### 3. Additional Services Needed
- [ ] Team service (CRUD operations)
- [ ] Tournament service (CRUD operations)
- [ ] Player service (roster management)
- [ ] Match service (bracket generation, scoring)
- [ ] Registration service

### 4. Advanced Features (Future)
- [ ] Real-time score updates
- [ ] Push notifications
- [ ] Tournament brackets visualization
- [ ] Team statistics and rankings
- [ ] Add Pickleball support

## How to Run

```bash
cd tournament_app

# Install dependencies (already done)
flutter pub get

# Run the app
flutter run

# For web
flutter run -d chrome

# For mobile (ensure emulator/device is connected)
flutter run
```

## Current File Structure

```
tournament_app/
├── lib/
│   ├── config/
│   │   └── supabase_config.dart       # Supabase credentials
│   ├── core/
│   │   └── supabase_client.dart       # Global Supabase client
│   ├── models/
│   │   ├── user_profile.dart          # User model
│   │   ├── team.dart                  # Team model
│   │   ├── player.dart                # Player/roster model
│   │   ├── tournament.dart            # Tournament model
│   │   └── tournament_registration.dart
│   ├── services/
│   │   └── auth_service.dart          # Authentication service
│   ├── screens/                       # (Empty - ready for UI)
│   ├── widgets/                       # (Empty - ready for widgets)
│   └── main.dart                      # App entry point
├── DATABASE_SCHEMA.md                 # Complete database setup
└── pubspec.yaml                       # Dependencies (Supabase added)
```

## Important Notes

1. **Security**: API keys are in config files. For production, consider environment variables.
2. **Database**: Must set up Supabase database before the app will work properly.
3. **Authentication**: Email verification is recommended for production.
4. **Pickleball**: Schema is ready - just change sport_type when creating tournaments.

## Support Resources

- Supabase Dashboard: https://ydxeavrjmaujmoysrhqx.supabase.co
- Flutter Supabase Docs: https://supabase.com/docs/guides/getting-started/tutorials/with-flutter
- Flutter Documentation: https://docs.flutter.dev/
