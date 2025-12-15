# Tournament Scheduler - Volleyball & Pickleball

A Flutter application for managing volleyball and pickleball tournaments with support for multiple tournament formats, team management, and player rosters.

## Features

### Completed
- ✅ **User Authentication**
  - Email/password signup and login
  - Role-based registration (Team Captain or Tournament Organizer)
  - Password reset functionality
  - Auto-create user profiles on signup

- ✅ **Role-Based Navigation**
  - Captains can access team management
  - Organizers can create and manage tournaments
  - Dynamic bottom navigation based on user role

- ✅ **Database Schema**
  - Complete PostgreSQL schema with 7 tables
  - Row Level Security (RLS) policies
  - Support for 4 tournament formats
  - Volleyball-specific player positions
  - Match and set tracking

### In Development
- 🚧 Team Management (for Captains)
- 🚧 Player Roster Management
- 🚧 Tournament Creation (for Organizers)
- 🚧 Tournament Registration
- 🚧 Match Scheduling & Brackets
- 🚧 Live Score Updates

## Tournament Formats Supported

1. **Round Robin** - Every team plays every other team once
2. **Single Elimination** - Knockout tournament
3. **Double Elimination** - Winners and losers brackets
4. **Pool Play** - Pools with playoff advancement

## Prerequisites

- Flutter SDK (3.35.4 or higher)
- Dart 3.9.2 or higher
- Supabase account

## Setup Instructions

### 1. Install Dependencies

```bash
cd tournament_app
flutter pub get
```

### 2. Configure Supabase Database

**IMPORTANT:** You must set up the database before the app will work properly.

1. Go to your Supabase Dashboard: https://ydxeavrjmaujmoysrhqx.supabase.co
2. Navigate to the **SQL Editor**
3. Open `DATABASE_SCHEMA.md` in this project
4. Copy and execute all SQL commands in order:
   - Create tables (sections 1-7)
   - Enable RLS (section: Enable RLS)
   - Create RLS policies (all policy sections)
   - Create indexes
   - Create functions and triggers

### 3. Enable Email Authentication

1. In Supabase Dashboard, go to **Authentication** → **Settings**
2. Enable **Email** provider
3. Configure email templates (optional)

### 4. Run the Application

```bash
# Run on Chrome (web)
flutter run -d chrome

# Run on Android/iOS emulator
flutter run

# Run on specific device
flutter devices  # List devices
flutter run -d <device_id>
```

## Project Structure

```
lib/
├── config/
│   └── supabase_config.dart         # Supabase credentials
├── core/
│   └── supabase_client.dart         # Global Supabase client
├── models/
│   ├── user_profile.dart            # User model with roles
│   ├── team.dart                    # Team model
│   ├── player.dart                  # Player/roster model
│   ├── tournament.dart              # Tournament with formats
│   └── tournament_registration.dart # Registration model
├── services/
│   └── auth_service.dart            # Authentication service
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart        # Login UI
│   │   └── signup_screen.dart       # Signup UI
│   └── home_screen.dart             # Main app screen
├── widgets/                         # (Empty - ready for reusable widgets)
└── main.dart                        # App entry point
```

## User Roles

### Team Captain
- Create and manage teams
- Add players to team roster
- Register teams for tournaments
- View tournament schedules
- Update match scores (for their team)

### Tournament Organizer
- Create tournaments with multiple formats
- Set registration deadlines and fees
- Approve/reject team registrations
- Generate tournament brackets
- Manage match schedules
- Update all match scores

### Admin
- All captain and organizer permissions
- Manage user accounts

## Volleyball Player Positions

The app supports these volleyball positions:
- Setter
- Outside Hitter
- Middle Blocker
- Libero
- Opposite
- Defensive Specialist

## Database Tables

1. **user_profiles** - User accounts with roles
2. **tournaments** - Tournament information and settings
3. **teams** - Teams with captain ownership
4. **players** - Player rosters with positions
5. **tournament_registrations** - Team registrations for tournaments
6. **matches** - Match schedules and scores
7. **match_sets** - Individual set scores

## Security

- Row Level Security (RLS) enabled on all tables
- Captains can only modify their own teams
- Organizers can only modify their own tournaments
- Public read access for tournaments and teams
- User-specific write permissions

## Development Roadmap

### Phase 1: Team Management (Next)
- [ ] Create team service
- [ ] Team creation screen
- [ ] Team list screen
- [ ] Player roster management
- [ ] Team details screen

### Phase 2: Tournament Management
- [ ] Create tournament service
- [ ] Tournament creation screen
- [ ] Tournament list screen
- [ ] Tournament details screen
- [ ] Team registration flow

### Phase 3: Bracket & Scheduling
- [ ] Bracket generation algorithms
- [ ] Match scheduling
- [ ] Bracket visualization
- [ ] Score entry screens

### Phase 4: Real-time Features
- [ ] Live score updates
- [ ] Real-time bracket updates
- [ ] Push notifications

### Phase 5: Additional Features
- [ ] Pickleball support
- [ ] Team statistics
- [ ] Player stats
- [ ] Tournament history
- [ ] Photo uploads for teams

## Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Troubleshooting

### Authentication Issues
- Ensure email provider is enabled in Supabase
- Check that database triggers are created
- Verify RLS policies are set up correctly

### Database Connection Issues
- Confirm Supabase URL and anon key are correct
- Check network connectivity
- Verify Supabase project is not paused

### Build Issues
- Run `flutter clean` then `flutter pub get`
- Check Flutter version: `flutter --version`
- Update dependencies: `flutter pub upgrade`

## Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## Support

For issues or questions:
- Check `DATABASE_SCHEMA.md` for database setup
- Check `SETUP_SUMMARY.md` for quick reference
- Review Flutter documentation: https://docs.flutter.dev/
- Review Supabase documentation: https://supabase.com/docs

## License

[Add your license here]

## Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- Volleyball and Pickleball communities
