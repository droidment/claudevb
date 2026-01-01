# Tournament App - UI Screens Documentation

This document provides comprehensive UI analysis of all 23 Flutter screens in the tournament management application for volleyball and pickleball tournaments. Use this as a reference for UI/UX redesign.

---

## Table of Contents

1. [Authentication Screens](#authentication-screens)
2. [Home Screen](#home-screen)
3. [Team Screens](#team-screens)
4. [Tournament Management Screens](#tournament-management-screens)
5. [Match and Tournament Execution Screens](#match-and-tournament-execution-screens)
6. [Screen Summary Table](#screen-summary-table)
7. [Key Design Patterns](#key-design-patterns)

---

## Authentication Screens

### 1. LoginScreen
**File:** `lib/screens/auth/login_screen.dart`
**Purpose:** Authenticate users with email and password

**Key UI Elements:**
- Volleyball icon (80px, blue color)
- "Tournament Scheduler" heading with subtitle "Volleyball & Pickleball"
- Email input field with email validation
- Password input field with visibility toggle button
- "Forgot Password?" text button
- "Login" filled button (full width)
- "Sign Up" text link at bottom
- Form validation with error messages
- Loading spinner during authentication

**User Interactions:**
- Enter email and password
- Toggle password visibility (eye icon)
- Click "Forgot Password?" to reset password
- Click "Login" to authenticate
- Click "Sign Up" to navigate to signup screen

**Navigation:**
- **From:** AuthWrapper (entry point)
- **To:** HomeScreen (on successful login), SignupScreen (on sign up link)

---

### 2. SignupScreen
**File:** `lib/screens/auth/signup_screen.dart`
**Purpose:** Create new user accounts with role selection

**Key UI Elements:**
- Volleyball icon (60px, blue color)
- "Join Tournament Scheduler" heading
- Full Name input field (required)
- Email input field with validation (required)
- Phone input field (optional)
- Role dropdown selector:
  - "Team Captain" option
  - "Tournament Organizer" option
- Password input field with visibility toggle (min 6 chars)
- Confirm Password input field with visibility toggle
- "Create Account" filled button (full width)
- "Login" text link at bottom
- Form validation with specific error messages

**User Interactions:**
- Fill in profile information (name, email, phone)
- Select role from dropdown
- Enter and confirm password
- Click "Create Account" to register
- Click "Login" link to go back

**Navigation:**
- **From:** LoginScreen
- **To:** LoginScreen (after successful signup or cancel)

---

## Home Screen

### 3. HomeScreen
**File:** `lib/screens/home_screen.dart`
**Purpose:** Main hub for users with role-based navigation

**Key UI Elements:**

**Bottom Navigation Bar** (role-based destinations):
- Home tab
- Tournaments tab
- My Teams tab (captains)
- Organize tab (organizers)
- Profile tab

**Home Tab Content:**
- Volleyball icon (100px, blue color)
- Welcome greeting with user's full name
- User role display badge (Team Captain/Tournament Organizer/User)
- "Join Private Tournament" card (orange background):
  - Lock icon
  - "Join Private Tournament" heading
  - "Enter invite code" subtitle
  - Arrow icon
- "Manage Teams" card (captains only):
  - Groups icon
  - "Manage Teams" heading
  - "View and manage your teams" subtitle
- "Create Tournament" card (organizers only):
  - Add icon
  - "Create Tournament" heading
  - "Start a new tournament" subtitle

**Profile Tab Content:**
- Avatar circle with first letter of user name
- User's full name (large text)
- User's email
- Role badge
- Phone number (if provided)
- "Logout" button with icon

**User Interactions:**
- Click bottom nav items to switch tabs
- Click "Join Private Tournament" card → JoinByInviteScreen
- Click "Manage Teams" card → TeamsListScreen
- Click "Create Tournament" card → CreateTournamentScreen
- Click "Logout" button to sign out

**Navigation:**
- **From:** AuthWrapper (after login)
- **To:** TournamentsListScreen, TeamsListScreen, OrganizeScreen, JoinByInviteScreen

---

## Team Screens

### 4. TeamsListScreen
**File:** `lib/screens/teams/teams_list_screen.dart`
**Purpose:** Display and manage user's teams

**Key UI Elements:**
- AppBar with "My Teams" title
- "Import from CSV" icon button in app bar (file_upload icon)
- Floating Action Button with "+" icon for creating team

**Team Cards:**
- Color circle avatar with team initial
- PAID/UNPAID status badge (green/orange)
- Team name (bold)
- Home city with location_on icon
- Captain phone with phone icon
- Lunch count with restaurant icon
- Arrow icon for navigation

**States:**
- Loading: Centered CircularProgressIndicator
- Empty: Group_off icon (80px) + "No Teams Yet" heading + "Create your first team" text + "Create Team" button
- Error: Error icon + error message + "Retry" button
- RefreshIndicator for pull-to-refresh

**User Interactions:**
- Click team card → TeamDetailScreen
- Click FAB → CreateTeamScreen
- Click "Import from CSV" → ImportTeamsScreen
- Pull to refresh teams list
- Click "Retry" on error

**Navigation:**
- **From:** HomeScreen (My Teams tab)
- **To:** TeamDetailScreen, CreateTeamScreen, ImportTeamsScreen

---

### 5. CreateTeamScreen
**File:** `lib/screens/teams/create_team_screen.dart`
**Purpose:** Create a new team with customization options

**Key UI Elements:**

**Team Preview Card** (real-time updates):
- Circular avatar (100px) with team initial
- Team color as background/border
- Team name display (or "Team Name" placeholder)
- Home city (if entered)

**Form Fields:**
- Team Name input (required, min 3 chars)
  - Groups icon prefix
  - "e.g., Thunder Spikers" hint
- Home City input (optional)
  - Location_city icon prefix
  - "e.g., San Francisco" hint
- Sport Type dropdown (required)
  - Sports icon prefix
  - Options: "Volleyball", "Pickleball"

**Team Color Selector:**
- "Team Color" heading
- 10 color circles in a Wrap layout:
  - Blue, Red, Green, Orange, Purple
  - Teal, Pink, Indigo, Amber, Cyan
- Selected color: checkmark icon, shadow effect, thick border
- Unselected: thin grey border

**Actions:**
- "Create Team" filled button (full width, 50px height)
- Loading spinner in button during creation

**User Interactions:**
- Type team name → preview updates
- Type home city → preview updates
- Select sport type from dropdown
- Click color circles to select team color
- Click "Create Team" to save

**Navigation:**
- **From:** TeamsListScreen
- **To:** TeamsListScreen (pop with result=true after creation)

---

### 6. TeamDetailScreen
**File:** `lib/screens/teams/team_detail_screen.dart`
**Purpose:** View team details, manage roster, and team information

**Key UI Elements:**

**AppBar:**
- Team name as title
- Delete icon button (with confirmation)

**Team Header Card:**
- Large circular avatar (80px) with team color
- Team name heading
- Home city with location icon
- Category badge (if available)
- Status badges row:
  - PAID/PENDING badge (green/orange)
  - "X LUNCHES" badge (if >0)
  - "X PLAYERS" badge

**Registration Info Card:**
- Section heading "Registration Information"
- Captain name with person icon
- Captain email with email icon
- Captain phone with phone icon
- Category with category icon
- Player count with group icon
- Contact Person 2 info (if available)
- Registration date with calendar icon
- Special Requests box (amber background, if available)
- Notes box (blue background, if available)

**Roster Section:**
- "Roster (X players)" heading with count chip
- Add Player FAB

**Player Cards:**
- Jersey number badge (amber)
- Player name
- Position badge (blue)
- Height display
- Popup menu (Edit, Delete)

**Empty Roster State:**
- Person_off icon
- "No Players Yet" text
- "Add Player" button

**Add/Edit Player Dialog:**
- Name input (required)
- Jersey Number input (number keyboard)
- Position dropdown (Outside Hitter, Middle Blocker, Setter, Opposite, Libero, Defensive Specialist)
- Height inputs (feet and inches)
- Cancel/Add or Cancel/Save buttons

**User Interactions:**
- Click FAB → Add Player dialog
- Click player card → Edit Player dialog
- Click popup menu → Edit/Delete options
- Confirm deletion with AlertDialog
- Click delete in app bar → Delete entire team with confirmation
- Pull to refresh

**Navigation:**
- **From:** TeamsListScreen
- **To:** TeamsListScreen (pop after deletion)

---

### 7. ImportTeamsScreen
**File:** `lib/screens/teams/import_teams_screen.dart`
**Purpose:** Bulk import teams from CSV files

**Key UI Elements:**
- AppBar with "Import Teams" title
- File picker button
- CSV preview table
- Team selection checkboxes
- Import button
- Progress indicator during import

**User Interactions:**
- Click to select CSV file
- Preview imported data
- Select/deselect teams to import
- Click Import to create teams

**Navigation:**
- **From:** TeamsListScreen
- **To:** TeamsListScreen (after import)

---

## Tournament Management Screens

### 8. TournamentsListScreen
**File:** `lib/screens/tournaments/tournaments_list_screen.dart`
**Purpose:** Browse and filter public tournaments

**Key UI Elements:**

**AppBar:**
- "Browse Tournaments" title
- "Join by Invite Code" icon button (vpn_key)
- "Filter" icon button (filter_list)

**Filter Bottom Sheet:**
- "Filter Tournaments" heading
- Sport Type section:
  - FilterChips: All, Volleyball, Pickleball
- Status section:
  - FilterChips: All, Registration Open, Ongoing, Completed
- "Show nearby tournaments" toggle switch
- Distance slider (5-200 km range)
- "Enable Location" button (if not enabled)
- "Apply Filters" filled button

**Active Filters Bar:**
- Horizontal scrollable chips showing active filters
- Clear button for each filter

**Tournament Cards:**
- Sport icon (volleyball/tennis)
- Tournament name (bold)
- Format label (small text)
- Status badge:
  - Registration Open: Green
  - Registration Closed: Orange
  - Ongoing: Blue
  - Completed: Grey
  - Cancelled: Red
- Description (if available, max 2 lines)
- Location with location_on icon
- Distance (if location enabled)
- Date with calendar icon
- Teams count and max teams
- Entry fee with money icon
- "Register Team" button (if open)

**States:**
- Loading: Centered spinner
- Empty: Search icon + "No Tournaments Found" + filter message
- No nearby: Location icon + message about no nearby tournaments
- RefreshIndicator

**User Interactions:**
- Click filter icon → Filter bottom sheet
- Select filter chips
- Toggle nearby tournaments
- Adjust distance slider
- Click "Enable Location"
- Click "Apply Filters"
- Click tournament card → TournamentDetailScreen
- Pull to refresh

**Navigation:**
- **From:** HomeScreen (Tournaments tab)
- **To:** TournamentDetailScreen, JoinByInviteScreen

---

### 9. CreateTournamentScreen
**File:** `lib/screens/tournaments/create_tournament_screen.dart`
**Purpose:** Create new tournament with comprehensive configuration

**Key UI Elements:**

**Section Headers** (blue colored with icons):

**Basic Information Section:**
- Tournament Name input (required)
  - Trophy icon prefix
  - "e.g., Summer Championship 2024" hint
- Description textarea (optional)
  - Description icon prefix
  - Max 500 chars

**Sport & Format Section:**
- Sport Type dropdown
  - Options: Volleyball, Pickleball
- Tournament Format dropdown
  - Options: Round Robin, Single Elimination, Double Elimination, Pool Play, Pool Play to Leagues
- Format description info card (blue background)

**Dates Section:**
- Registration Deadline picker
  - Calendar icon, tap to open date/time picker
- Start Date picker
- End Date picker

**Location Section:**
- Location input
  - Location_on icon prefix
  - "e.g., San Francisco Sports Center" hint
- Venue Details textarea
  - Info icon prefix

**Team Settings Section:**
- Max Teams input (number)
- Min Team Size input (default: 6)
- Max Team Size input (default: 12)

**Privacy Settings Section:**
- "Public Tournament" toggle switch
  - Public/Lock icon
- Info card explaining private tournaments and invite codes

**Location Coordinates Section (Optional):**
- "Use Current Location" outlined button
- "From Address" outlined button
- Coordinates display card (if set)
  - Map icon, lat/lng display
  - Clear button

**Entry Fee Section:**
- Entry Fee input (decimal keyboard)
  - Money icon prefix
  - "$" prefix text

**Actions:**
- "Create Tournament" filled button (full width)
- Loading spinner during creation

**User Interactions:**
- Fill all tournament details
- Click date fields → Date/Time picker dialogs
- Toggle privacy settings
- Click location buttons → Get coordinates
- Submit form with validation

**Navigation:**
- **From:** OrganizeScreen, HomeScreen
- **To:** OrganizeScreen (pop with result=true)

---

### 10. EditTournamentScreen
**File:** `lib/screens/tournaments/edit_tournament_screen.dart`
**Purpose:** Edit existing tournament details

**Key UI Elements:**
- Same layout as CreateTournamentScreen
- All fields pre-populated with current tournament data
- Invite code display card (for private tournaments)
- "Save Changes" button instead of "Create Tournament"
- Coordinates display with clear button

**User Interactions:**
- Modify any tournament field
- Update dates, location, privacy
- Clear or update coordinates
- Click "Save Changes"

**Navigation:**
- **From:** TournamentDetailScreen
- **To:** TournamentDetailScreen (pop with result=true)

---

### 11. TournamentDetailScreen
**File:** `lib/screens/tournaments/tournament_detail_screen.dart`
**Purpose:** Central hub for tournament management and viewing

**Key UI Elements:**

**AppBar:**
- "Tournament Details" title
- Edit icon button (organizers only)
- More menu (Change Status, Delete)

**Header Card:**
- Sport icon (48px)
- Tournament name (headline)
- Format label
- Status badge (clickable for organizers):
  - Color-coded container
  - Status icon and text
  - Dropdown arrow (organizers)
- Description (if available)

**Private Tournament Card** (if private, organizers only):
- Lock icon
- "Private Tournament" heading
- Invite code display
- Copy button

**Tournament Details Card:**
- Sport type row
- Format row
- Location row (if set)
- Venue details row (if set)

**Important Dates Card:**
- Registration Deadline
- Start Date
- End Date

**Team Requirements Card:**
- Maximum Teams
- Team Size range
- Entry Fee

**Registered Teams Section** (organizers/admins only):
- "Registered Teams" heading with count chip
- Add Teams icon button
- Action buttons row:
  - "Manage Seeds" outlined button
  - "Add Teams" outlined button
- Second row:
  - "Lunches" outlined button
  - "Scoring" outlined button (purple)
- "Manage Staff" button (organizers only, indigo)
- "View Schedule" / "Generate Schedule" button
- "View Standings & Tier Progression" button (pool play)
- "Brackets" and "Results" buttons (pool play)

**Team Tiles:**
- Seed number badge (if set)
- Team avatar with color
- Team name
- PAID/UNPAID badge
- Location
- Pool assignment badge
- Lunch count badge
- Popup menu (Edit Registration, Remove)

**Edit Registration Dialog:**
- Payment Status toggle switch
- Seed Number input
- Pool Assignment input
- Cancel/Save buttons

**Generate Schedule Dialog:**
- Pool play info card (if applicable)
- Total matches calculation
- Start Date & Time picker
- Match Duration slider (30-120 min)
- Number of Courts slider (1-8)
- Scoring Format radio buttons
- Estimated Duration display
- Cancel/Generate buttons

**User Interactions:**
- Click status badge → Status menu (organizers)
- Click edit icon → EditTournamentScreen
- Click "Add Teams" → AddTeamsScreen
- Click "Manage Seeds" → ManageSeedsScreen
- Click "Lunches" → ManageLunchesScreen
- Click "Scoring" → ScoringConfigScreen
- Click "Manage Staff" → ManageStaffScreen
- Click "Generate Schedule" → Dialog → Generate matches
- Click "View Schedule" → MatchesScreen
- Click "View Standings" → StandingsScreen
- Click "Brackets" → BracketScreen
- Click "Results" → TournamentResultsScreen
- Click team tile popup → Edit/Remove

**Navigation:**
- **From:** OrganizeScreen, TournamentsListScreen
- **To:** Multiple screens as listed above

---

### 12. AddTeamsScreen
**File:** `lib/screens/tournaments/add_teams_screen.dart`
**Purpose:** Register multiple teams to a tournament

**Key UI Elements:**

**AppBar:**
- "Add Teams" title
- Popup menu (Select All, Select None)

**Header Container** (primary color background):
- "Adding to:" label
- Tournament name (bold)
- Sport type indicator row:
  - Sports icon
  - "Showing Volleyball/Pickleball teams only" text
- Selected count display (if >0)

**Team Cards:**
- Checkbox (leading)
- Team color avatar with initial
- Team name
- Location row (if available)
- Phone row (if available)
- PAID badge (if paid)
- Selection highlight: Primary color border when selected

**Bottom Action Bar:**
- "Add X Team(s)" filled button
- Disabled when none selected
- Loading spinner during registration

**Empty State:**
- Group_off icon (80px)
- "No [Sport] Teams Available" heading
- Explanation text about creating teams
- "Go Back" outlined button

**User Interactions:**
- Click checkbox/card to toggle selection
- Click menu → Select All/None
- Click "Add Teams" to register
- Pull to refresh

**Navigation:**
- **From:** TournamentDetailScreen
- **To:** TournamentDetailScreen (pop with result=true)

---

### 13. ManageSeedsScreen
**File:** `lib/screens/tournaments/manage_seeds_screen.dart`
**Purpose:** Set team seeding and pool assignments with drag-and-drop

**Key UI Elements:**

**AppBar:**
- Tournament name as title
- "Save" icon button (with unsaved changes indicator)

**Info Banner** (blue background):
- Info icon
- "Enter seed numbers directly in the boxes. Drag teams to reorder. Lower seed = stronger team."

**Pool Filter** (pool play formats):
- "Filter by Pool" dropdown
- Options: All Pools, Pool A, Pool B, etc.

**Team Cards** (ReorderableListView):
- Drag handle icon (left)
- Inline seed input field:
  - 50px width text field
  - Number keyboard
  - Amber color when has seed
  - Grey when empty
  - Placeholder "-"
- Team avatar with color
- Team name
- PAID badge
- Pool assignment badge
- Location (if available)
- Yellow highlight when changed

**Pool Assignment Section:**
- Pool dropdown on each team card

**Actions:**
- "Save All Seeds" filled button (bottom)
- Shows unsaved changes count

**User Interactions:**
- Type seed number directly in inline field
- Drag teams to reorder
- Select pool assignment
- Click "Save" to persist all changes
- See yellow highlights for unsaved changes

**Navigation:**
- **From:** TournamentDetailScreen
- **To:** TournamentDetailScreen (pop after save)

---

### 14. ManageLunchesScreen
**File:** `lib/screens/tournaments/manage_lunches_screen.dart`
**Purpose:** Track team lunch reservations and payments

**Key UI Elements:**

**AppBar:**
- Tournament name as title
- "Save" icon button

**Summary Card** (top):
- Total lunches count
- Total revenue calculation
- Paid vs unpaid breakdown

**Team Cards:**
- Team name and avatar
- Lunch count inputs:
  - Non-veg counter (red icon)
  - Vegetarian counter (green icon)
  - "No Need" counter (grey icon)
- Increment/decrement buttons
- Total lunches per team
- Cost calculation ($10 per lunch)
- Payment status toggle/dropdown:
  - Not Paid (red)
  - Partial (orange)
  - Paid (green)

**Actions:**
- "Save All Lunches" filled button

**User Interactions:**
- Click +/- to adjust lunch counts
- Toggle payment status
- Click "Save" to persist

**Navigation:**
- **From:** TournamentDetailScreen
- **To:** TournamentDetailScreen

---

### 15. ScoringConfigScreen
**File:** `lib/screens/tournaments/scoring_config_screen.dart`
**Purpose:** Configure scoring rules for tournament phases

**Key UI Elements:**

**AppBar:**
- "Scoring Configuration" title
- Sport type subtitle

**Quick Presets Section:**
- "Quick Presets" heading
- Preset chips:
  - "Volleyball Standard" (25 pts, best of 3)
  - "Volleyball Rally" (15 pts, best of 3)
  - "Pickleball Standard" (11 pts, best of 3)

**Phase Configuration Cards:**
Each phase (Pool Play, Quarter-Finals, Semi-Finals, Finals) has:
- Phase name heading
- "Edit" button
- Current configuration display:
  - Best of X sets
  - Points per set
  - Win by 2 indicator
  - Point cap (if set)
  - Tiebreaker rules

**Edit Phase Bottom Sheet:**
- Phase name heading
- "Best of" selector (1, 3, 5)
- Points per set input
- "Win by 2" toggle
- Point cap input (optional)
- Tiebreaker set points input
- "Clear" and "Apply" buttons

**Summary Card:**
- Configuration summary for all phases
- Save indicator

**Actions:**
- "Save Configuration" filled button

**User Interactions:**
- Click preset chips to quick-apply
- Click "Edit" on phase cards
- Configure scoring in bottom sheet
- Apply changes per phase
- Save all configurations

**Navigation:**
- **From:** TournamentDetailScreen
- **To:** TournamentDetailScreen (pop with new config)

---

### 16. ManageStaffScreen
**File:** `lib/screens/tournaments/manage_staff_screen.dart`
**Purpose:** Add and manage tournament staff with role-based permissions

**Key UI Elements:**

**AppBar:**
- "Manage Staff" title

**Role Explanation Card:**
- Two sections (Admin, Scorer)
- Each with:
  - Role icon
  - Role name
  - Permissions list

**Staff Sections:**

**Admins Section:**
- "Admins" heading with count
- Admin staff cards

**Scorers Section:**
- "Scorers" heading with count
- Scorer staff cards

**Staff Cards:**
- User avatar with initial
- User name
- User email
- Role badge (purple for Admin, blue for Scorer)
- Popup menu (Change Role, Remove)

**Add Staff FAB:**
- Plus icon

**Add Staff Dialog:**
- "Add Staff Member" heading
- Email search input with search icon
- Search results list (users matching email)
- Selected user display
- Role dropdown (Admin, Scorer)
- Cancel/Add buttons

**User Interactions:**
- Click FAB → Add Staff dialog
- Search users by email
- Select user from results
- Choose role
- Add staff member
- Click popup menu → Change Role/Remove
- Confirm removal

**Navigation:**
- **From:** TournamentDetailScreen
- **To:** TournamentDetailScreen

---

### 17. OrganizeScreen
**File:** `lib/screens/tournaments/organize_screen.dart`
**Purpose:** View and manage tournaments created by the organizer

**Key UI Elements:**

**AppBar:**
- "My Tournaments" title

**Floating Action Button:**
- Plus icon for creating tournament

**Tournament Cards:**
- Sport icon (volleyball/tennis)
- Tournament name
- Format label
- Status badge (color-coded)
- Location (if set)
- Date
- Team count

**Empty State:**
- Trophy icon (80px)
- "No Tournaments Yet" heading
- "Create your first tournament" text
- "Create Tournament" button

**RefreshIndicator**

**User Interactions:**
- Click tournament card → TournamentDetailScreen
- Click FAB → CreateTournamentScreen
- Pull to refresh

**Navigation:**
- **From:** HomeScreen (Organize tab)
- **To:** TournamentDetailScreen, CreateTournamentScreen

---

### 18. JoinByInviteScreen
**File:** `lib/screens/tournaments/join_by_invite_screen.dart`
**Purpose:** Join private tournaments using invite codes

**Key UI Elements:**

**AppBar:**
- "Join Tournament" title

**Invite Code Input Section:**
- "Enter Invite Code" heading
- Text input field:
  - 8 character max
  - All caps transformation
  - VPN key icon prefix
  - "e.g., ABC12345" hint
- "Search" filled button

**Tournament Preview Card** (after search):
- Tournament name
- Format and sport badges
- Status badge
- Location (if set)
- Date
- Teams count
- Entry fee
- "Join Tournament" filled button

**Help Section Card:**
- Help icon
- "What's an invite code?" heading
- Explanation text about private tournaments

**Error States:**
- "Tournament not found" message
- Invalid code format message

**User Interactions:**
- Type invite code (8 chars)
- Click "Search" to find tournament
- View tournament preview
- Click "Join Tournament" to register
- See success/error messages

**Navigation:**
- **From:** HomeScreen, TournamentsListScreen
- **To:** TournamentDetailScreen (after joining)

---

## Match and Tournament Execution Screens

### 19. MatchesScreen
**File:** `lib/screens/matches/matches_screen.dart`
**Purpose:** View tournament match schedule

**Key UI Elements:**

**AppBar:**
- "Schedule" title
- Tournament name subtitle

**Filter Chips Row:**
- "All" chip
- "Scheduled" chip (blue)
- "In Progress" chip (orange)
- "Completed" chip (green)

**Match Groups by Round:**
- Round heading ("Round X")
- Match count chip

**Match Cards:**
- Match number badge
- Status icon:
  - Scheduled: Blue clock
  - In Progress: Orange play
  - Completed: Green check
  - Cancelled: Red cancel
- Team 1 name (or "TBD")
- Team 2 name (or "TBD")
- Score display:
  - "vs" if pending
  - "X - Y" sets if completed
- Scheduled time with clock icon
- Court number with volleyball icon
- Pool assignment badge (if pool play)

**Empty State:**
- Calendar icon (80px)
- "No Matches Yet" heading
- Explanation text

**RefreshIndicator**

**User Interactions:**
- Click filter chips to filter matches
- Click match card → MatchDetailScreen
- Pull to refresh

**Navigation:**
- **From:** TournamentDetailScreen
- **To:** MatchDetailScreen

---

### 20. MatchDetailScreen
**File:** `lib/screens/matches/match_detail_screen.dart`
**Purpose:** Record match scores and manage individual match details

**Key UI Elements:**

**AppBar:**
- "Match X" title
- Refresh icon button

**Match Info Card:**
- Match number
- Status badge (color-coded)
- Pool/Phase label
- Court and time info

**Teams Card:**
- Team 1:
  - Avatar with color
  - Team name
  - Current sets won badge
- "VS" divider
- Team 2:
  - Avatar with color
  - Team name
  - Current sets won badge
- Winner indicator (trophy icon on winning team)

**Sets Card:**
- "Sets" heading
- Set list:
  - Set number badge
  - Team 1 score
  - Team 2 score
  - Set winner indicator
  - Popup menu (Edit, Delete)
- "Add Set" FAB

**Add/Edit Set Dialog:**
- "Add Set" / "Edit Set X" heading
- Team 1 name + score input
- Team 2 name + score input
- Score validation message
- Cancel/Save buttons

**Actions Card** (organizers/scorers):
- "Start Match" button (if scheduled)
- "Mark Complete" button (if in progress)
- "Cancel Match" button
- Auto-complete indicator (when best-of reached)

**Status Messages:**
- "Match auto-completed" notification
- Winner announcement

**User Interactions:**
- Click "Add Set" → Set dialog
- Enter scores for both teams
- Click set popup → Edit/Delete
- Click "Start Match" to begin
- Click "Mark Complete" to finish
- Match auto-completes when threshold reached

**Navigation:**
- **From:** MatchesScreen, BracketScreen
- **To:** MatchesScreen (pop after updates)

---

### 21. StandingsScreen
**File:** `lib/screens/matches/standings_screen.dart`
**Purpose:** View pool play standings and manage tier progression

**Key UI Elements:**

**AppBar:**
- "Standings" title
- Refresh icon button

**TabBar:**
- "Pool Standings" tab (with leaderboard icon)
- "Tier Progression" tab (with account_tree icon)

**Pool Standings Tab:**

**Pool Tables** (one per pool):
- Pool name heading ("Pool A", "Pool B", etc.)
- Table headers: Rank, Team, W, L, Pts
- Table rows:
  - Rank number (1, 2, 3...)
  - Team name with avatar
  - Wins count
  - Losses count
  - Points total
- Alternating row colors
- Top teams highlighted

**Tier Progression Tab:**

**Tier Cards:**
- Tier name heading:
  - Advanced (green)
  - Intermediate (blue)
  - Recreational (orange)
- Team assignments list:
  - Team name
  - Original pool badge
  - Pool ranking badge

**Generate Brackets Button** (organizers, if not generated):
- "Generate Tier Brackets" filled button

**Generate Brackets Dialog:**
- Teams per tier input
- Start time picker
- Match duration slider
- Number of courts slider
- Cancel/Generate buttons

**User Interactions:**
- Switch between tabs
- View pool standings
- View tier assignments
- Click "Generate Brackets" (organizers)
- Configure and generate brackets

**Navigation:**
- **From:** TournamentDetailScreen
- **To:** BracketScreen (after generation)

---

### 22. BracketScreen
**File:** `lib/screens/matches/bracket_screen.dart`
**Purpose:** Display tournament bracket matches organized by tier and round

**Key UI Elements:**

**AppBar:**
- "Brackets" title
- Tournament name subtitle
- "View Results" icon button (emoji_events)
- Refresh icon button

**TabBar** (tier tabs):
- "Advanced" tab (green indicator)
- "Intermediate" tab (blue indicator)
- "Recreational" tab (orange indicator)

**Bracket Layout** (horizontal scroll):

**Round Columns:**
- Round heading (Quarter-Finals, Semi-Finals, Finals)
- Tier-colored header bar

**Match Cards:**
- Team 1:
  - Team name (or "TBD"/"Winner of Match X")
  - Sets won badge
  - Trophy icon if winner
- Divider line
- Team 2:
  - Team name (or "TBD")
  - Sets won badge
  - Trophy icon if winner
- Green border if completed
- Orange border if in progress

**Advance Winners Button** (organizers):
- "Advance Winners" outlined button (sync icon)
- Advances winners to next round matches

**Confirmation Dialog:**
- "Advance Winners?" heading
- Explanation text
- Cancel/Advance buttons

**Empty State:**
- Account_tree icon
- "No Bracket Matches" heading
- "Generate brackets from standings" text

**User Interactions:**
- Click tier tabs to switch views
- Horizontal scroll to see all rounds
- Click match card → MatchDetailScreen
- Click "Advance Winners" to progress tournament
- Click "View Results" → TournamentResultsScreen

**Navigation:**
- **From:** StandingsScreen, TournamentDetailScreen
- **To:** MatchDetailScreen, TournamentResultsScreen

---

### 23. TournamentResultsScreen
**File:** `lib/screens/matches/tournament_results_screen.dart`
**Purpose:** Display final tournament results and allow closing tournament

**Key UI Elements:**

**AppBar:**
- "Tournament Results" title
- Tournament name subtitle
- Refresh icon button

**Status Card:**
- Tournament status:
  - Ongoing: Orange with play icon
  - Completed: Green with check icon
- Completion percentage
- Status message

**Tier Results Sections:**

**Tier Heading:**
- Tier name
- Color indicator (green/blue/orange)
- Trophy icon

**Results Table:**
- Headers: Place, Team, Result
- Rows:
  - Place badge (gold/silver/bronze colors for 1-3)
  - Team name with avatar
  - Final result/opponent

**Close Tournament Card** (organizers, if complete):
- "Close Tournament" heading
- Explanation text
- "Close Tournament" filled button (red)

**Close Confirmation Dialog:**
- Warning icon
- "Close Tournament?" heading
- Explanation about finality
- Cancel/Close buttons

**User Interactions:**
- View final results by tier
- See placement rankings
- Click "Close Tournament" (organizers)
- Confirm closure
- Refresh results

**Navigation:**
- **From:** BracketScreen, TournamentDetailScreen
- **To:** BracketScreen (pop after refresh)

---

## Screen Summary Table

| # | Screen Name | File Path | Primary Users |
|---|-------------|-----------|---------------|
| 1 | LoginScreen | `auth/login_screen.dart` | All |
| 2 | SignupScreen | `auth/signup_screen.dart` | New users |
| 3 | HomeScreen | `home_screen.dart` | All |
| 4 | TeamsListScreen | `teams/teams_list_screen.dart` | Captains |
| 5 | CreateTeamScreen | `teams/create_team_screen.dart` | Captains |
| 6 | TeamDetailScreen | `teams/team_detail_screen.dart` | Captains |
| 7 | ImportTeamsScreen | `teams/import_teams_screen.dart` | Captains |
| 8 | TournamentsListScreen | `tournaments/tournaments_list_screen.dart` | All |
| 9 | CreateTournamentScreen | `tournaments/create_tournament_screen.dart` | Organizers |
| 10 | EditTournamentScreen | `tournaments/edit_tournament_screen.dart` | Organizers |
| 11 | TournamentDetailScreen | `tournaments/tournament_detail_screen.dart` | Organizers |
| 12 | AddTeamsScreen | `tournaments/add_teams_screen.dart` | Organizers |
| 13 | ManageSeedsScreen | `tournaments/manage_seeds_screen.dart` | Organizers |
| 14 | ManageLunchesScreen | `tournaments/manage_lunches_screen.dart` | Organizers |
| 15 | ScoringConfigScreen | `tournaments/scoring_config_screen.dart` | Organizers |
| 16 | ManageStaffScreen | `tournaments/manage_staff_screen.dart` | Organizers |
| 17 | OrganizeScreen | `tournaments/organize_screen.dart` | Organizers |
| 18 | JoinByInviteScreen | `tournaments/join_by_invite_screen.dart` | Captains |
| 19 | MatchesScreen | `matches/matches_screen.dart` | All |
| 20 | MatchDetailScreen | `matches/match_detail_screen.dart` | Organizers/Scorers |
| 21 | StandingsScreen | `matches/standings_screen.dart` | All |
| 22 | BracketScreen | `matches/bracket_screen.dart` | All |
| 23 | TournamentResultsScreen | `matches/tournament_results_screen.dart` | All |

---

## Key Design Patterns

### Loading States
- Centered `CircularProgressIndicator`
- Used on all data-fetching screens

### Empty States
- Large icon (64-80px, grey color)
- Heading text
- Subtitle/explanation text
- Primary action button

### Error States
- Error icon (red)
- Error message text
- "Retry" button

### Form Design
- `OutlinedInputBorder` on all text fields
- Icon prefixes for context
- Hint text for examples
- Section headers with icons
- Validation error messages below fields

### Cards
- Used for grouping related content
- Consistent padding (16px)
- Rounded corners (default border radius)
- Optional elevation/shadows

### Status Badges
- Color coding:
  - Green: Paid, Complete, Success
  - Orange: Pending, In Progress, Warning
  - Red: Unpaid, Cancelled, Error
  - Blue: Info, Scheduled
  - Purple: Special features (Scoring, Admin)
- Small rounded containers with bold text

### Navigation
- Bottom navigation on HomeScreen
- AppBar with back button on detail screens
- Floating Action Buttons for primary "create" actions
- Popup menus for secondary actions

### Refresh Pattern
- `RefreshIndicator` wrapping scrollable content
- Pull-to-refresh gesture supported

### Dialogs
- `AlertDialog` for confirmations
- Custom dialogs for forms/editing
- Bottom sheets for filters and options

### Color Scheme
- Primary: Blue (Material default)
- Secondary actions: Purple, Teal, Indigo
- Status colors: Green, Orange, Red
- Backgrounds: Light variants (shade50, shade100)

---

## Notes for Designer

1. **Consistency**: Maintain consistent spacing, typography, and color usage across all screens
2. **Accessibility**: Ensure sufficient color contrast and touch target sizes (min 48px)
3. **Responsiveness**: Consider tablet and web layouts for wider screens
4. **Dark Mode**: Consider dark theme variants for all color choices
5. **Animations**: Add subtle transitions between states and screens
6. **Icons**: Currently using Material Icons - consider custom icon set for brand identity
7. **Typography**: Using Material 3 text styles - consider custom font family
8. **Loading**: Consider skeleton loaders instead of spinners for better UX
9. **Empty States**: Opportunity for custom illustrations
10. **Onboarding**: Consider first-time user experience flows

---

*Documentation generated for UI/UX redesign reference*
