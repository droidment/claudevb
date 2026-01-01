import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/tournament.dart';
import '../../models/tournament_registration.dart';
import '../../models/scoring_format.dart';
import '../../models/tournament_staff.dart';
import '../../services/tournament_service.dart';
import '../../services/match_service.dart';
import '../../services/tournament_staff_service.dart';
import '../../services/round_robin_generator.dart';
import '../matches/matches_screen.dart';
import '../matches/standings_screen.dart';
import '../matches/bracket_screen.dart';
import '../matches/tournament_results_screen.dart';
import 'edit_tournament_screen.dart';
import 'add_teams_screen.dart';
import 'manage_seeds_screen.dart';
import 'manage_lunches_screen.dart';
import 'scoring_config_screen.dart';
import 'manage_staff_screen.dart';
import '../../models/scoring_config.dart';

// Dark theme colors (consistent with home screen and browse screen)
class _DetailColors {
  static const Color background = Color(0xFF0D1117);
  static const Color cardBackground = Color(0xFF161B22);
  static const Color cardBackgroundLight = Color(0xFF1C2128);
  static const Color accent = Color(0xFF58A6FF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF6E7681);
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color divider = Color(0xFF21262D);
}

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  final bool isOrganizer;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
    this.isOrganizer = false,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  final _tournamentService = TournamentService();
  final _matchService = MatchService();
  final _staffService = TournamentStaffService();
  Tournament? _tournament;
  List<Map<String, dynamic>> _registeredTeams = [];
  bool _isLoading = true;
  bool _isLoadingTeams = false;
  bool _hasMatches = false;
  int _matchCount = 0;
  String? _error;
  ScoringFormat _scoringFormat = ScoringFormat.singleSet;
  TournamentPermissions _permissions = TournamentPermissions.none;
  bool _isFavorited = false;

  /// Check if current user is the organizer of this tournament
  bool get _isCurrentUserOrganizer {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || _tournament == null) return false;
    return _tournament!.organizerId == currentUserId || widget.isOrganizer;
  }

  /// Check if current user can manage the tournament (owner or admin)
  bool get _canManageTournament =>
      _permissions.canManageTournament || _isCurrentUserOrganizer;

  /// Check if current user can manage scores (owner, admin, or scorer)
  bool get _canManageScores =>
      _permissions.canManageScores || _isCurrentUserOrganizer;

  /// Check if tournament format supports schedule generation
  bool get _supportsScheduleGeneration {
    if (_tournament == null) return false;
    return _tournament!.format == TournamentFormat.roundRobin ||
        _tournament!.format == TournamentFormat.poolPlay ||
        _tournament!.format == TournamentFormat.poolPlayToLeagues;
  }

  @override
  void initState() {
    super.initState();
    _loadTournament();
  }

  Future<void> _loadTournament() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournament = await _tournamentService.getTournament(
        widget.tournamentId,
      );

      // Load user's permissions for this tournament
      final permissions = await _staffService.getPermissionsForTournament(
        widget.tournamentId,
      );

      setState(() {
        _tournament = tournament;
        _permissions = permissions;
        _isLoading = false;
      });
      // Load teams after tournament loads
      _loadRegisteredTeams();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRegisteredTeams() async {
    setState(() => _isLoadingTeams = true);

    try {
      final teams = await _tournamentService.getTournamentTeams(
        widget.tournamentId,
      );

      // Check if matches exist
      final hasMatches = await _matchService.hasTournamentMatches(
        widget.tournamentId,
      );
      final matchCount = await _matchService.getMatchCount(
        widget.tournamentId,
      );

      setState(() {
        _registeredTeams = teams;
        _hasMatches = hasMatches;
        _matchCount = matchCount;
        _isLoadingTeams = false;
      });
    } catch (e) {
      setState(() => _isLoadingTeams = false);
    }
  }

  Future<void> _updateStatus(TournamentStatus newStatus) async {
    try {
      await _tournamentService.updateTournamentStatus(
        widget.tournamentId,
        newStatus,
      );
      await _loadTournament();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.displayName}'),
            backgroundColor: _DetailColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: _DetailColors.error,
          ),
        );
      }
    }
  }

  /// Check if tournament is pool play format
  bool get _isPoolPlayFormat {
    if (_tournament == null) return false;
    return _tournament!.format == TournamentFormat.poolPlay ||
        _tournament!.format == TournamentFormat.poolPlayToLeagues;
  }

  /// Group registered teams by pool assignment
  Map<String, List<String>> get _teamsByPool {
    final Map<String, List<String>> grouped = {};
    for (final reg in _registeredTeams) {
      final poolAssignment = reg['pool_assignment'] as String?;
      final teamId = (reg['teams'] as Map<String, dynamic>)['id'] as String;

      if (poolAssignment != null && poolAssignment.isNotEmpty) {
        grouped.putIfAbsent(poolAssignment, () => []);
        grouped[poolAssignment]!.add(teamId);
      }
    }
    return grouped;
  }

  /// Get teams without pool assignment
  List<String> get _teamsWithoutPool {
    return _registeredTeams
        .where((reg) {
          final poolAssignment = reg['pool_assignment'] as String?;
          return poolAssignment == null || poolAssignment.isEmpty;
        })
        .map((reg) => (reg['teams'] as Map<String, dynamic>)['id'] as String)
        .toList();
  }

  String _getStatusLabel(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.registrationOpen:
        return 'REGISTRATION OPEN';
      case TournamentStatus.registrationClosed:
        return 'REGISTRATION CLOSED';
      case TournamentStatus.ongoing:
        return 'LIVE';
      case TournamentStatus.completed:
        return 'COMPLETED';
      case TournamentStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.registrationOpen:
        return _DetailColors.success;
      case TournamentStatus.registrationClosed:
        return _DetailColors.warning;
      case TournamentStatus.ongoing:
        return _DetailColors.accent;
      case TournamentStatus.completed:
        return _DetailColors.textMuted;
      case TournamentStatus.cancelled:
        return _DetailColors.error;
    }
  }

  IconData _getSportIcon(String sportType) {
    return sportType == 'volleyball'
        ? Icons.sports_volleyball
        : Icons.sports_tennis;
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'TBD';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DetailColors.background,
      body: _buildBody(),
      bottomNavigationBar: _tournament != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _DetailColors.accent),
      );
    }

    if (_error != null || _tournament == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: _DetailColors.error),
            const SizedBox(height: 16),
            Text(
              'Error: ${_error ?? "Tournament not found"}',
              style: const TextStyle(color: _DetailColors.textPrimary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadTournament,
              style: FilledButton.styleFrom(
                backgroundColor: _DetailColors.accent,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTournament,
      color: _DetailColors.accent,
      child: CustomScrollView(
        slivers: [
          // Hero Image Header
          _buildHeroHeader(),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Cards Row
                  _buildInfoCardsRow(),
                  const SizedBox(height: 20),

                  // Category Chips
                  _buildCategoryChips(),
                  const SizedBox(height: 24),

                  // About Section
                  if (_tournament!.description != null) ...[
                    _buildAboutSection(),
                    const SizedBox(height: 24),
                  ],

                  // Schedule Section
                  _buildScheduleSection(),
                  const SizedBox(height: 24),

                  // Location Section
                  if (_tournament!.location != null) ...[
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                  ],

                  // Team Requirements Section
                  _buildTeamRequirementsSection(),
                  const SizedBox(height: 24),

                  // Organizer Section (for organizers only)
                  if (_canManageTournament) ...[
                    _buildOrganizerSection(),
                    const SizedBox(height: 24),
                  ],

                  // Add padding for bottom bar
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    final isVolleyball = _tournament!.sportType == 'volleyball';
    final gradientColor =
        isVolleyball ? Colors.orange.shade700 : Colors.teal.shade600;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: _DetailColors.background,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => setState(() => _isFavorited = !_isFavorited),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white, size: 20),
          ),
          onPressed: () {
            // Share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share feature coming soon!')),
            );
          },
        ),
        if (_isCurrentUserOrganizer) ...[
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
            color: _DetailColors.cardBackground,
            onSelected: (value) {
              if (value == 'edit') {
                _editTournament();
              } else if (value == 'status') {
                _showStatusMenu();
              } else if (value == 'delete') {
                _deleteTournament();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit, color: _DetailColors.textSecondary),
                  title: Text('Edit Tournament',
                      style: TextStyle(color: _DetailColors.textPrimary)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'status',
                child: ListTile(
                  leading: Icon(Icons.sync, color: _DetailColors.textSecondary),
                  title: Text('Change Status',
                      style: TextStyle(color: _DetailColors.textPrimary)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: _DetailColors.error),
                  title: Text('Delete',
                      style: TextStyle(color: _DetailColors.error)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background with sport pattern
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradientColor.withValues(alpha: 0.4),
                    _DetailColors.cardBackgroundLight,
                  ],
                ),
              ),
              child: CustomPaint(
                painter: _SportPatternPainter(_tournament!.sportType),
              ),
            ),
            // Large Sport Icon
            Center(
              child: Icon(
                _getSportIcon(_tournament!.sportType),
                size: 120,
                color: gradientColor.withValues(alpha: 0.3),
              ),
            ),
            // Bottom Gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 160,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      _DetailColors.background.withValues(alpha: 0.8),
                      _DetailColors.background,
                    ],
                  ),
                ),
              ),
            ),
            // Tournament Info Overlay
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge and Format
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_tournament!.status),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getStatusLabel(_tournament!.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _DetailColors.cardBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_tournament!.minTeamSize}V${_tournament!.minTeamSize}',
                          style: const TextStyle(
                            color: _DetailColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tournament Name
                  Text(
                    _tournament!.name,
                    style: const TextStyle(
                      color: _DetailColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Sport Type
                  Row(
                    children: [
                      Icon(
                        _getSportIcon(_tournament!.sportType),
                        color: _DetailColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${_tournament!.format.displayName} ${_tournament!.sportType[0].toUpperCase()}${_tournament!.sportType.substring(1)}",
                        style: const TextStyle(
                          color: _DetailColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCardsRow() {
    final teamCount = _registeredTeams.length;

    return Row(
      children: [
        // Entry Fee Card
        Expanded(
          child: _buildInfoCard(
            icon: Icons.payments_outlined,
            value: _tournament!.entryFee != null
                ? '\$${_tournament!.entryFee!.toInt()}'
                : 'Free',
            label: 'ENTRY FEE',
          ),
        ),
        const SizedBox(width: 12),
        // Max Teams Card
        Expanded(
          child: _buildInfoCard(
            icon: Icons.groups_outlined,
            value: _tournament!.maxTeams != null
                ? '$teamCount/${_tournament!.maxTeams}'
                : '$teamCount',
            label: 'TEAMS',
          ),
        ),
        const SizedBox(width: 12),
        // Format Card
        Expanded(
          child: _buildInfoCard(
            icon: Icons.emoji_events_outlined,
            value: _tournament!.format.displayName.split(' ').first,
            label: 'FORMAT',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _DetailColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DetailColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: _DetailColors.accent, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _DetailColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _DetailColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final chips = <Widget>[];

    // Sport type chip
    chips.add(_buildChip(
      Icons.sports,
      _tournament!.sportType[0].toUpperCase() +
          _tournament!.sportType.substring(1),
    ));

    // Format chip
    chips.add(_buildChip(Icons.format_list_bulleted, _tournament!.format.displayName));

    // Privacy chip
    chips.add(_buildChip(
      _tournament!.isPublic ? Icons.public : Icons.lock,
      _tournament!.isPublic ? 'Public' : 'Private',
    ));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _DetailColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _DetailColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _DetailColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _DetailColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About the Event',
          style: TextStyle(
            color: _DetailColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _DetailColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _tournament!.description!,
            style: const TextStyle(
              color: _DetailColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule',
          style: TextStyle(
            color: _DetailColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _DetailColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Registration Deadline
              _buildTimelineItem(
                icon: Icons.how_to_reg,
                iconColor: _DetailColors.error,
                title: 'DEADLINE',
                date: _formatDate(_tournament!.registrationDeadline),
                subtitle: 'Team registration closes',
                isFirst: true,
              ),
              // Start Date
              _buildTimelineItem(
                icon: Icons.play_circle_outline,
                iconColor: _DetailColors.accent,
                title: 'KICKOFF',
                date: _formatDate(_tournament!.startDate),
                subtitle: 'Tournament begins',
              ),
              // End Date
              _buildTimelineItem(
                icon: Icons.emoji_events,
                iconColor: _DetailColors.warning,
                title: 'FINALS',
                date: _formatDate(_tournament!.endDate),
                subtitle: 'Championship game',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String date,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line and icon
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 16,
                color: _DetailColors.divider,
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: _DetailColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: isFirst ? 0 : 12, bottom: isLast ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    color: _DetailColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _DetailColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Location',
              style: TextStyle(
                color: _DetailColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Open maps
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Maps integration coming soon!')),
                );
              },
              child: const Text(
                'Get Directions',
                style: TextStyle(color: _DetailColors.accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Map Placeholder
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: _DetailColors.cardBackgroundLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Placeholder map pattern
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  size: const Size(double.infinity, 150),
                  painter: _MapPlaceholderPainter(),
                ),
              ),
              // Map pin
              const Center(
                child: Icon(
                  Icons.location_on,
                  color: _DetailColors.error,
                  size: 40,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Location details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _DetailColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _DetailColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: _DetailColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tournament!.location!,
                      style: const TextStyle(
                        color: _DetailColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_tournament!.venueDetails != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _tournament!.venueDetails!,
                        style: const TextStyle(
                          color: _DetailColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamRequirementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Team Requirements',
          style: TextStyle(
            color: _DetailColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _DetailColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildRequirementRow(
                'Roster Size',
                'Min ${_tournament!.minTeamSize} - Max ${_tournament!.maxTeamSize}',
                isFirst: true,
              ),
              if (_tournament!.maxTeams != null)
                _buildRequirementRow(
                  'Team Slots',
                  '${_registeredTeams.length} of ${_tournament!.maxTeams} filled',
                ),
              _buildRequirementRow(
                'Format',
                _tournament!.format.displayName,
                isLast: _tournament!.entryFee == null,
              ),
              if (_tournament!.entryFee != null)
                _buildRequirementRow(
                  'Entry Fee',
                  '\$${_tournament!.entryFee!.toStringAsFixed(2)} per team',
                  isLast: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementRow(String label, String value,
      {bool isFirst = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: _DetailColors.divider),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _DetailColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _DetailColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organizer Tools',
          style: TextStyle(
            color: _DetailColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Private tournament invite code
        if (!_tournament!.isPublic && _tournament!.inviteCode != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _DetailColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _DetailColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.vpn_key, color: _DetailColors.warning, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Invite Code',
                      style: TextStyle(
                        color: _DetailColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tournament!.inviteCode!,
                        style: const TextStyle(
                          color: _DetailColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: _DetailColors.warning),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _tournament!.inviteCode!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invite code copied!'),
                            backgroundColor: _DetailColors.success,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Teams section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _DetailColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registered Teams (${_registeredTeams.length})',
                    style: const TextStyle(
                      color: _DetailColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _navigateToAddTeams,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: _DetailColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick action buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildOrganizerActionChip(
                    Icons.format_list_numbered,
                    'Seeds',
                    _navigateToManageSeeds,
                  ),
                  _buildOrganizerActionChip(
                    Icons.restaurant,
                    'Lunches',
                    _navigateToManageLunches,
                  ),
                  _buildOrganizerActionChip(
                    Icons.scoreboard,
                    'Scoring',
                    _navigateToScoringConfig,
                  ),
                  if (_isCurrentUserOrganizer)
                    _buildOrganizerActionChip(
                      Icons.group,
                      'Staff',
                      _navigateToManageStaff,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Schedule/Matches buttons
              if (_hasMatches)
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        Icons.calendar_month,
                        'Schedule ($_matchCount)',
                        _navigateToMatches,
                        isPrimary: true,
                      ),
                    ),
                  ],
                )
              else if (_supportsScheduleGeneration && _registeredTeams.length >= 2)
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        Icons.auto_fix_high,
                        'Generate Schedule',
                        _generateSchedule,
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),

              if (_hasMatches && _isPoolPlayFormat) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        Icons.leaderboard,
                        'Standings',
                        _navigateToStandings,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        Icons.account_tree,
                        'Brackets',
                        _navigateToBrackets,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        Icons.emoji_events,
                        'Results',
                        _navigateToResults,
                        color: _DetailColors.warning,
                      ),
                    ),
                  ],
                ),
              ],

              // Team list preview
              if (_registeredTeams.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: _DetailColors.divider),
                const SizedBox(height: 12),
                ..._registeredTeams.take(5).map((reg) => _buildTeamTile(reg)),
                if (_registeredTeams.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: TextButton(
                        onPressed: _navigateToManageSeeds,
                        child: Text(
                          'View all ${_registeredTeams.length} teams',
                          style: const TextStyle(color: _DetailColors.accent),
                        ),
                      ),
                    ),
                  ),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_off,
                          size: 48,
                          color: _DetailColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No teams registered yet',
                          style: TextStyle(color: _DetailColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerActionChip(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _DetailColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _DetailColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _DetailColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: _DetailColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
    Color? color,
  }) {
    final buttonColor = color ?? (isPrimary ? _DetailColors.accent : _DetailColors.cardBackgroundLight);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? buttonColor : _DetailColors.cardBackgroundLight,
          borderRadius: BorderRadius.circular(10),
          border: isPrimary ? null : Border.all(color: color ?? _DetailColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? Colors.white : (color ?? _DetailColors.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : (color ?? _DetailColors.textPrimary),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamTile(Map<String, dynamic> registration) {
    final teamData = registration['teams'] as Map<String, dynamic>?;
    if (teamData == null) return const SizedBox.shrink();

    final teamName = teamData['name'] as String? ?? 'Unknown Team';
    final teamId = teamData['id'] as String;
    final teamColor = teamData['team_color'] as String?;
    final paymentStatus = registration['payment_status'] as String? ?? 'pending';
    final isPaid = paymentStatus == 'paid';
    final poolAssignment = registration['pool_assignment'] as String?;
    final seedNumber = registration['seed_number'] as int?;

    Color avatarColor = _DetailColors.accent;
    if (teamColor != null) {
      try {
        avatarColor = Color(int.parse(teamColor.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _DetailColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Seed badge
          if (seedNumber != null)
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _DetailColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '$seedNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: _DetailColors.warning,
                  ),
                ),
              ),
            ),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                teamName[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Team info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: const TextStyle(
                    color: _DetailColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    if (poolAssignment != null) ...[
                      Text(
                        'Pool $poolAssignment',
                        style: const TextStyle(
                          color: _DetailColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? _DetailColors.success.withValues(alpha: 0.2)
                            : _DetailColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPaid ? 'PAID' : 'UNPAID',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isPaid
                              ? _DetailColors.success
                              : _DetailColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: _DetailColors.textMuted,
              size: 20,
            ),
            color: _DetailColors.cardBackground,
            onSelected: (value) {
              if (value == 'remove') {
                _removeTeamFromTournament(teamId, teamName);
              } else if (value == 'edit') {
                _editTeamRegistration(registration);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit', style: TextStyle(color: _DetailColors.textPrimary)),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove', style: TextStyle(color: _DetailColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isFull = _tournament!.maxTeams != null &&
        _registeredTeams.length >= _tournament!.maxTeams!;
    final canRegister = _tournament!.status == TournamentStatus.registrationOpen && !isFull;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: _DetailColors.cardBackground,
        border: const Border(
          top: BorderSide(color: _DetailColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Price
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL FEE',
                style: TextStyle(
                  color: _DetailColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _tournament!.entryFee != null
                    ? '\$${_tournament!.entryFee!.toInt()}'
                    : 'Free',
                style: const TextStyle(
                  color: _DetailColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '/ team',
                style: TextStyle(
                  color: _DetailColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Register Button
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: canRegister
                  ? () {
                      // Navigate to registration
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registration feature coming soon!'),
                        ),
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: canRegister
                    ? _DetailColors.accent
                    : _DetailColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isFull
                        ? 'Full'
                        : canRegister
                            ? 'Register Team'
                            : _tournament!.status.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (canRegister) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  Future<void> _editTournament() async {
    if (_tournament == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditTournamentScreen(tournament: _tournament!),
      ),
    );

    if (result == true) {
      await _loadTournament();
    }
  }

  void _showStatusMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _DetailColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _DetailColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Change Status',
              style: TextStyle(
                color: _DetailColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...TournamentStatus.values.map((status) {
              final isSelected = _tournament?.status == status;
              return ListTile(
                leading: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                ),
                title: Text(
                  status.displayName,
                  style: TextStyle(
                    color: _DetailColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: _DetailColors.accent)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  _updateStatus(status);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.registrationOpen:
        return Icons.how_to_reg;
      case TournamentStatus.registrationClosed:
        return Icons.lock;
      case TournamentStatus.ongoing:
        return Icons.play_circle;
      case TournamentStatus.completed:
        return Icons.check_circle;
      case TournamentStatus.cancelled:
        return Icons.cancel;
    }
  }

  Future<void> _deleteTournament() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _DetailColors.cardBackground,
        title: const Text(
          'Delete Tournament',
          style: TextStyle(color: _DetailColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this tournament? This action cannot be undone.',
          style: TextStyle(color: _DetailColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _DetailColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _tournamentService.deleteTournament(widget.tournamentId);
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tournament deleted successfully'),
              backgroundColor: _DetailColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting tournament: $e'),
              backgroundColor: _DetailColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToAddTeams() async {
    if (_tournament == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddTeamsScreen(
          tournamentId: _tournament!.id,
          tournamentName: _tournament!.name,
          sportType: _tournament!.sportType,
        ),
      ),
    );

    if (result == true) {
      await _loadRegisteredTeams();
    }
  }

  Future<void> _navigateToManageSeeds() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageSeedsScreen(
          tournamentId: _tournament!.id,
          tournamentName: _tournament!.name,
        ),
      ),
    );

    await _loadRegisteredTeams();
  }

  Future<void> _navigateToManageLunches() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageLunchesScreen(
          tournamentId: _tournament!.id,
          tournamentName: _tournament!.name,
        ),
      ),
    );

    await _loadRegisteredTeams();
  }

  Future<void> _navigateToScoringConfig() async {
    if (_tournament == null) return;

    final newConfig = await Navigator.of(context).push<TournamentScoringConfig>(
      MaterialPageRoute(
        builder: (context) => ScoringConfigScreen(
          sportType: _tournament!.sportType,
          initialConfig: _tournament!.scoringConfig,
        ),
      ),
    );

    if (newConfig != null) {
      try {
        await _tournamentService.updateTournament(
          _tournament!.id,
          {'scoring_config': newConfig.toJsonString()},
        );
        await _loadTournament();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scoring configuration saved'),
              backgroundColor: _DetailColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving scoring config: $e'),
              backgroundColor: _DetailColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToManageStaff() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageStaffScreen(
          tournamentId: _tournament!.id,
          tournamentName: _tournament!.name,
        ),
      ),
    );

    await _loadTournament();
  }

  Future<void> _navigateToMatches() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchesScreen(
          tournamentId: widget.tournamentId,
          tournamentName: _tournament!.name,
          isOrganizer: _canManageScores,
          scoringFormat: _scoringFormat,
          tournamentScoringConfig: _tournament!.scoringConfig,
        ),
      ),
    );

    await _loadRegisteredTeams();
  }

  Future<void> _navigateToStandings() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StandingsScreen(
          tournamentId: widget.tournamentId,
          tournamentName: _tournament!.name,
          isOrganizer: _canManageScores,
          scoringFormat: _scoringFormat,
          venue: _tournament!.location,
          tournamentScoringConfig: _tournament!.scoringConfig,
        ),
      ),
    );
  }

  Future<void> _navigateToBrackets() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BracketScreen(
          tournamentId: widget.tournamentId,
          tournamentName: _tournament!.name,
          isOrganizer: _canManageScores,
          scoringFormat: _scoringFormat,
          tournamentScoringConfig: _tournament!.scoringConfig,
        ),
      ),
    );
  }

  Future<void> _navigateToResults() async {
    if (_tournament == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TournamentResultsScreen(
          tournamentId: widget.tournamentId,
          tournamentName: _tournament!.name,
          isOrganizer: _canManageTournament,
        ),
      ),
    );

    await _loadTournament();
  }

  Future<void> _generateSchedule() async {
    if (_tournament == null || _registeredTeams.isEmpty) return;

    if (_registeredTeams.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('At least 2 teams are required to generate matches'),
            backgroundColor: _DetailColors.warning,
          ),
        );
      }
      return;
    }

    // For pool play formats, check that teams have pool assignments
    if (_isPoolPlayFormat) {
      final teamsWithoutPool = _teamsWithoutPool;
      if (teamsWithoutPool.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${teamsWithoutPool.length} team(s) have no pool assignment. '
                'Please assign all teams to pools first.',
              ),
              backgroundColor: _DetailColors.warning,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final teamsByPool = _teamsByPool;
      for (final entry in teamsByPool.entries) {
        if (entry.value.length < 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Pool ${entry.key} has only ${entry.value.length} team(s). '
                  'Each pool needs at least 2 teams.',
                ),
                backgroundColor: _DetailColors.warning,
              ),
            );
          }
          return;
        }
      }
    }

    // Show configuration dialog
    final config = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _GenerateScheduleDialog(
        numberOfTeams: _registeredTeams.length,
        tournamentFormat: _tournament!.format,
        teamsByPool: _isPoolPlayFormat ? _teamsByPool : null,
      ),
    );

    if (config == null) return;

    setState(() {
      _scoringFormat = config['scoringFormat'] as ScoringFormat;
    });

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Card(
              color: _DetailColors.cardBackground,
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _DetailColors.accent),
                    SizedBox(height: 16),
                    Text(
                      'Generating matches...',
                      style: TextStyle(color: _DetailColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      List<Map<String, dynamic>> matchesData;

      if (_isPoolPlayFormat) {
        matchesData = RoundRobinGenerator.generatePoolPlayMatches(
          tournamentId: widget.tournamentId,
          teamsByPool: _teamsByPool,
          startTime: config['startTime'] as DateTime,
          matchDurationMinutes: config['matchDuration'] as int,
          numberOfCourts: config['numberOfCourts'] as int,
          venue: _tournament!.location,
        );
      } else {
        final teamIds = _registeredTeams
            .map((reg) => (reg['teams'] as Map<String, dynamic>)['id'] as String)
            .toList();

        matchesData = RoundRobinGenerator.generateMatches(
          tournamentId: widget.tournamentId,
          teamIds: teamIds,
          startTime: config['startTime'] as DateTime,
          matchDurationMinutes: config['matchDuration'] as int,
          numberOfCourts: config['numberOfCourts'] as int,
          venue: _tournament!.location,
        );
      }

      await _matchService.createMatches(matchesData);

      if (mounted) Navigator.of(context).pop();

      await _loadRegisteredTeams();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${matchesData.length} matches generated successfully!'),
            backgroundColor: _DetailColors.success,
          ),
        );

        _navigateToMatches();
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating schedule: $e'),
            backgroundColor: _DetailColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeTeamFromTournament(String teamId, String teamName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _DetailColors.cardBackground,
        title: const Text(
          'Remove Team',
          style: TextStyle(color: _DetailColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove "$teamName" from this tournament?',
          style: const TextStyle(color: _DetailColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _DetailColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _tournamentService.removeTeamFromTournament(
          tournamentId: widget.tournamentId,
          teamId: teamId,
        );
        await _loadRegisteredTeams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$teamName removed from tournament'),
              backgroundColor: _DetailColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing team: $e'),
              backgroundColor: _DetailColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _editTeamRegistration(Map<String, dynamic> registration) async {
    final teamData = registration['teams'] as Map<String, dynamic>?;
    if (teamData == null) return;

    final teamId = teamData['id'] as String;
    final teamName = teamData['name'] as String? ?? 'Team';
    String? poolAssignment = registration['pool_assignment'] as String?;
    int? seedNumber = registration['seed_number'] as int?;
    final paymentStatusStr = registration['payment_status'] as String? ?? 'pending';
    PaymentStatus paymentStatus = PaymentStatusExtension.fromString(paymentStatusStr);

    final poolController = TextEditingController(text: poolAssignment ?? '');
    final seedController = TextEditingController(text: seedNumber?.toString() ?? '');

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        PaymentStatus dialogPaymentStatus = paymentStatus;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: _DetailColors.cardBackground,
            title: Text(
              'Edit $teamName',
              style: const TextStyle(color: _DetailColors.textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Status Toggle
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dialogPaymentStatus == PaymentStatus.paid
                          ? _DetailColors.success.withValues(alpha: 0.1)
                          : _DetailColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          dialogPaymentStatus == PaymentStatus.paid
                              ? Icons.check_circle
                              : Icons.pending,
                          color: dialogPaymentStatus == PaymentStatus.paid
                              ? _DetailColors.success
                              : _DetailColors.warning,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _DetailColors.textSecondary,
                                ),
                              ),
                              Text(
                                dialogPaymentStatus.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: dialogPaymentStatus == PaymentStatus.paid
                                      ? _DetailColors.success
                                      : _DetailColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: dialogPaymentStatus == PaymentStatus.paid,
                          activeColor: _DetailColors.success,
                          onChanged: (value) {
                            setDialogState(() {
                              dialogPaymentStatus = value
                                  ? PaymentStatus.paid
                                  : PaymentStatus.pending;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Seed Number
                  TextField(
                    controller: seedController,
                    style: const TextStyle(color: _DetailColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Seed Number',
                      labelStyle: const TextStyle(color: _DetailColors.textSecondary),
                      hintText: 'e.g., 1, 2, 3',
                      hintStyle: const TextStyle(color: _DetailColors.textMuted),
                      filled: true,
                      fillColor: _DetailColors.cardBackgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.format_list_numbered,
                        color: _DetailColors.textMuted,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Pool Assignment
                  TextField(
                    controller: poolController,
                    style: const TextStyle(color: _DetailColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Pool Assignment',
                      labelStyle: const TextStyle(color: _DetailColors.textSecondary),
                      hintText: 'e.g., A, B, C',
                      hintStyle: const TextStyle(color: _DetailColors.textMuted),
                      filled: true,
                      fillColor: _DetailColors.cardBackgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.grid_view,
                        color: _DetailColors.textMuted,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop({
                  'paymentStatus': dialogPaymentStatus,
                  'save': true,
                }),
                style: FilledButton.styleFrom(
                  backgroundColor: _DetailColors.accent,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && result['save'] == true) {
      try {
        final newPaymentStatus = result['paymentStatus'] as PaymentStatus;
        await _tournamentService.updateRegistration(
          tournamentId: widget.tournamentId,
          teamId: teamId,
          poolAssignment: poolController.text.isNotEmpty
              ? poolController.text.toUpperCase()
              : null,
          seedNumber: int.tryParse(seedController.text),
          paymentStatus: newPaymentStatus,
        );
        await _loadRegisteredTeams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$teamName registration updated'),
              backgroundColor: _DetailColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating registration: $e'),
              backgroundColor: _DetailColors.error,
            ),
          );
        }
      }
    }

    poolController.dispose();
    seedController.dispose();
  }
}

/// Custom painter for sport-themed background patterns
class _SportPatternPainter extends CustomPainter {
  final String sportType;

  _SportPatternPainter(this.sportType);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    if (sportType == 'volleyball') {
      // Draw net pattern
      for (var i = 0; i < 8; i++) {
        final y = size.height * 0.3 + (i * 20);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      for (var i = 0; i < 15; i++) {
        final x = i * 30.0;
        canvas.drawLine(
          Offset(x, size.height * 0.3),
          Offset(x, size.height * 0.3 + 140),
          paint,
        );
      }
    } else {
      // Draw court lines for pickleball
      final rect = Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.2,
        size.width * 0.8,
        size.height * 0.6,
      );
      canvas.drawRect(rect, paint);
      canvas.drawLine(
        Offset(size.width * 0.5, size.height * 0.2),
        Offset(size.width * 0.5, size.height * 0.8),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for map placeholder
class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _DetailColors.divider
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid pattern
    for (var i = 0; i < 10; i++) {
      final x = i * size.width / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var i = 0; i < 6; i++) {
      final y = i * size.height / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dialog for configuring schedule generation
class _GenerateScheduleDialog extends StatefulWidget {
  final int numberOfTeams;
  final TournamentFormat tournamentFormat;
  final Map<String, List<String>>? teamsByPool;

  const _GenerateScheduleDialog({
    required this.numberOfTeams,
    required this.tournamentFormat,
    this.teamsByPool,
  });

  bool get isPoolPlay => teamsByPool != null && teamsByPool!.isNotEmpty;

  @override
  State<_GenerateScheduleDialog> createState() => _GenerateScheduleDialogState();
}

class _GenerateScheduleDialogState extends State<_GenerateScheduleDialog> {
  DateTime _startTime = DateTime.now().add(const Duration(days: 1));
  int _matchDuration = 60;
  int _numberOfCourts = 2;
  ScoringFormat _scoringFormat = ScoringFormat.singleSet;

  int get _totalMatches {
    if (widget.isPoolPlay) {
      final teamsPerPool = widget.teamsByPool!.map(
        (key, value) => MapEntry(key, value.length),
      );
      return RoundRobinGenerator.calculatePoolPlayTotalMatches(teamsPerPool);
    } else {
      return RoundRobinGenerator.calculateTotalMatches(widget.numberOfTeams);
    }
  }

  int get _estimatedDuration {
    if (widget.isPoolPlay) {
      final teamsPerPool = widget.teamsByPool!.map(
        (key, value) => MapEntry(key, value.length),
      );
      return RoundRobinGenerator.estimatePoolPlayDuration(
        teamsPerPool: teamsPerPool,
        matchDurationMinutes: _matchDuration,
        numberOfCourts: _numberOfCourts,
      );
    } else {
      return RoundRobinGenerator.estimateTournamentDuration(
        numberOfTeams: widget.numberOfTeams,
        matchDurationMinutes: _matchDuration,
        numberOfCourts: _numberOfCourts,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMatches = _totalMatches;
    final estimatedDuration = _estimatedDuration;

    return AlertDialog(
      backgroundColor: _DetailColors.cardBackground,
      title: Text(
        widget.isPoolPlay
            ? 'Generate Pool Play Schedule'
            : 'Generate Tournament Schedule',
        style: const TextStyle(color: _DetailColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pool play info
            if (widget.isPoolPlay) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _DetailColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.grid_view, color: _DetailColors.accent, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Pool Play Format',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _DetailColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...widget.teamsByPool!.entries.map((entry) {
                      final poolMatches = RoundRobinGenerator.calculateTotalMatches(
                        entry.value.length,
                      );
                      return Text(
                        'Pool ${entry.key}: ${entry.value.length} teams -> $poolMatches matches',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _DetailColors.textSecondary,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              'This will create $totalMatches matches for ${widget.numberOfTeams} teams.',
              style: const TextStyle(color: _DetailColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Start Date & Time
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );

                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_startTime),
                  );

                  if (time != null) {
                    setState(() {
                      _startTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _DetailColors.cardBackgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: _DetailColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start Date & Time',
                            style: TextStyle(
                              color: _DetailColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_startTime.month}/${_startTime.day}/${_startTime.year} '
                            'at ${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: _DetailColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit, color: _DetailColors.textMuted, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Match Duration
            const Text(
              'Match Duration',
              style: TextStyle(color: _DetailColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _DetailColors.accent,
                      inactiveTrackColor: _DetailColors.divider,
                      thumbColor: _DetailColors.accent,
                    ),
                    child: Slider(
                      value: _matchDuration.toDouble(),
                      min: 30,
                      max: 120,
                      divisions: 9,
                      label: '$_matchDuration min',
                      onChanged: (value) {
                        setState(() => _matchDuration = value.toInt());
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '$_matchDuration min',
                    style: const TextStyle(
                      color: _DetailColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Number of Courts
            const Text(
              'Number of Courts',
              style: TextStyle(color: _DetailColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _DetailColors.accent,
                      inactiveTrackColor: _DetailColors.divider,
                      thumbColor: _DetailColors.accent,
                    ),
                    child: Slider(
                      value: _numberOfCourts.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      label: '$_numberOfCourts',
                      onChanged: (value) {
                        setState(() => _numberOfCourts = value.toInt());
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '$_numberOfCourts courts',
                    style: const TextStyle(
                      color: _DetailColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scoring Format
            const Text(
              'Scoring Format',
              style: TextStyle(color: _DetailColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...ScoringFormat.values.map((format) {
              final isSelected = _scoringFormat == format;
              return GestureDetector(
                onTap: () => setState(() => _scoringFormat = format),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _DetailColors.accent.withValues(alpha: 0.1)
                        : _DetailColors.cardBackgroundLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? _DetailColors.accent : _DetailColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<ScoringFormat>(
                        value: format,
                        groupValue: _scoringFormat,
                        activeColor: _DetailColors.accent,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _scoringFormat = value);
                          }
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              format.displayName,
                              style: TextStyle(
                                color: _DetailColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              format.shortDescription,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _DetailColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Estimated Duration
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _DetailColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: _DetailColors.success),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Duration',
                        style: TextStyle(
                          fontSize: 12,
                          color: _DetailColors.success,
                        ),
                      ),
                      Text(
                        '${(estimatedDuration / 60).toStringAsFixed(1)} hours',
                        style: const TextStyle(
                          fontSize: 16,
                          color: _DetailColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop({
              'startTime': _startTime,
              'matchDuration': _matchDuration,
              'numberOfCourts': _numberOfCourts,
              'scoringFormat': _scoringFormat,
            });
          },
          style: FilledButton.styleFrom(backgroundColor: _DetailColors.accent),
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Generate'),
        ),
      ],
    );
  }
}
