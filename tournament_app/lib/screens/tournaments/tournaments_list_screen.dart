import 'package:flutter/material.dart';
import '../../models/tournament.dart';
import '../../services/tournament_service.dart';
import '../../theme/theme.dart';
import 'tournament_detail_screen.dart';
import 'join_by_invite_screen.dart';

class TournamentsListScreen extends StatefulWidget {
  const TournamentsListScreen({super.key});

  @override
  State<TournamentsListScreen> createState() => _TournamentsListScreenState();
}

class _TournamentsListScreenState extends State<TournamentsListScreen> {
  final _tournamentService = TournamentService();
  final _searchController = TextEditingController();
  List<Tournament> _tournaments = [];
  Map<String, int> _teamCounts = {};
  bool _isLoading = true;
  String? _error;
  String _selectedSport = 'all';
  TournamentStatus? _selectedStatus;
  double? _userLatitude;
  double? _userLongitude;
  final bool _showNearbyOnly = false;
  final double _maxDistance = 50.0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournaments = await _tournamentService.getAllTournaments(
        sportType: _selectedSport == 'all' ? null : _selectedSport,
        status: _selectedStatus,
      );

      final counts = <String, int>{};
      await Future.wait(
        tournaments.map((t) async {
          counts[t.id] = await _tournamentService.getRegisteredTeamCount(t.id);
        }),
      );

      setState(() {
        _tournaments = tournaments;
        _teamCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToTournamentDetail(String tournamentId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TournamentDetailScreen(
          tournamentId: tournamentId,
          isOrganizer: false,
        ),
      ),
    );
  }

  List<Tournament> _filterTournaments() {
    var filtered = _tournaments;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        final query = _searchQuery.toLowerCase();
        return t.name.toLowerCase().contains(query) ||
            (t.location?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter by distance
    if (_showNearbyOnly && _userLatitude != null && _userLongitude != null) {
      filtered = filtered.where((tournament) {
        final distance = tournament.distanceFrom(_userLatitude, _userLongitude);
        return distance != null && distance <= _maxDistance;
      }).toList();
    }

    return filtered;
  }

  void _showFilterDialog() {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        final dialogColors = dialogContext.colors;
        return StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Tournaments',
                    style: TextStyle(
                      color: dialogColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sport Type',
                    style: TextStyle(
                      color: dialogColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('All Sports', 'all', setModalState, dialogColors),
                      _buildFilterChip('Volleyball', 'volleyball', setModalState, dialogColors),
                      _buildFilterChip('Pickleball', 'pickleball', setModalState, dialogColors),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Status',
                    style: TextStyle(
                      color: dialogColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildStatusChip('All', null, setModalState, dialogColors),
                      _buildStatusChip('Open', TournamentStatus.registrationOpen, setModalState, dialogColors),
                      _buildStatusChip('Ongoing', TournamentStatus.ongoing, setModalState, dialogColors),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadTournaments();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: dialogColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, StateSetter setModalState, AppColorPalette colors) {
    final isSelected = _selectedSport == value;
    return GestureDetector(
      onTap: () {
        setModalState(() => _selectedSport = value);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : colors.searchBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, TournamentStatus? value, StateSetter setModalState, AppColorPalette colors) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () {
        setModalState(() => _selectedStatus = value);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : colors.searchBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.registrationOpen:
        return 'Open';
      case TournamentStatus.registrationClosed:
        return 'Full';
      case TournamentStatus.ongoing:
        return 'Live';
      case TournamentStatus.completed:
        return 'Ended';
      case TournamentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(TournamentStatus status, AppColorPalette colors) {
    switch (status) {
      case TournamentStatus.registrationOpen:
        return colors.success;
      case TournamentStatus.registrationClosed:
        return colors.warning;
      case TournamentStatus.ongoing:
        return colors.accent;
      case TournamentStatus.completed:
        return colors.textMuted;
      case TournamentStatus.cancelled:
        return colors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Browse Tournaments',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.vpn_key_outlined, color: colors.accent),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const JoinByInviteScreen(),
                            ),
                          );
                        },
                        tooltip: 'Join by Invite Code',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.searchBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search tournaments, locations...',
                          hintStyle: TextStyle(color: colors.textMuted),
                          prefixIcon: Icon(Icons.search, color: colors.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showFilterDialog,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.searchBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.tune, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sport filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildSportChip('All Sports', 'all', colors),
                  const SizedBox(width: 8),
                  _buildSportChip('Volleyball', 'volleyball', colors),
                  const SizedBox(width: 8),
                  _buildSportChip('Pickleball', 'pickleball', colors),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tournament list
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSportChip(String label, String value, AppColorPalette colors) {
    final isSelected = _selectedSport == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSport = value);
        _loadTournaments();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : colors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: colors.searchBackground),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final colors = context.colors;
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colors.accent),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Error loading tournaments',
              style: TextStyle(color: colors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadTournaments,
              style: FilledButton.styleFrom(backgroundColor: colors.accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredTournaments = _filterTournaments();

    if (filteredTournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 80, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No tournaments found',
              style: TextStyle(color: colors.textPrimary, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTournaments,
      color: colors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filteredTournaments.length + 1, // +1 for end message
        itemBuilder: (context, index) {
          if (index == filteredTournaments.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "You've reached the end of the list",
                  style: TextStyle(color: colors.textMuted, fontSize: 14),
                ),
              ),
            );
          }
          final tournament = filteredTournaments[index];
          return _buildTournamentCard(tournament, colors);
        },
      ),
    );
  }

  Widget _buildTournamentCard(Tournament tournament, AppColorPalette colors) {
    final teamCount = _teamCounts[tournament.id] ?? 0;
    final isFull = tournament.maxTeams != null && teamCount >= tournament.maxTeams!;
    final spotsLeft = tournament.maxTeams != null ? tournament.maxTeams! - teamCount : null;
    final isLastCall = spotsLeft != null && spotsLeft > 0 && spotsLeft <= 3;

    return GestureDetector(
      onTap: () => _navigateToTournamentDetail(tournament.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tournament image/header
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.cardBackgroundLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: _buildSportImage(tournament.sportType, colors),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusBadge(tournament.status, isLastCall, colors),
                ),
                // Tournament name overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (tournament.location != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tournament.location!,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Tournament details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Date and price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDateRange(tournament.startDate, tournament.endDate),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        tournament.entryFee != null
                            ? '\$${tournament.entryFee!.toInt()}/team'
                            : 'Free Entry',
                        style: TextStyle(
                          color: tournament.entryFee != null
                              ? colors.accent
                              : colors.success,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Capacity and action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Team capacity
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFull ? 'CAPACITY' : (isLastCall ? 'SPOTS LEFT' : 'ENROLLED'),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isLastCall)
                            Text(
                              'Only $spotsLeft Spots!',
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            Text(
                              tournament.maxTeams != null
                                  ? '$teamCount/${tournament.maxTeams} Teams'
                                  : '$teamCount Teams',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),

                      // Action button
                      _buildActionButton(tournament, isFull, colors),
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

  Widget _buildSportImage(String sportType, AppColorPalette colors) {
    // Create a gradient background with sport icon
    final isVolleyball = sportType == 'volleyball';
    final color = isVolleyball ? Colors.orange.shade700 : Colors.teal.shade600;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.3),
            colors.cardBackgroundLight,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _SportPatternPainter(sportType),
            ),
          ),
          // Sport icon
          Center(
            child: Icon(
              isVolleyball ? Icons.sports_volleyball : Icons.sports_tennis,
              size: 64,
              color: color.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TournamentStatus status, bool isLastCall, AppColorPalette colors) {
    final color = _getStatusColor(status, colors);
    final label = isLastCall ? 'Last Call' : _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.cardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isLastCall ? colors.error : color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isLastCall ? colors.error : color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Tournament tournament, bool isFull, AppColorPalette colors) {
    if (tournament.status == TournamentStatus.registrationOpen && !isFull) {
      return FilledButton(
        onPressed: () => _navigateToTournamentDetail(tournament.id),
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text(
          'Register',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    } else if (isFull) {
      return OutlinedButton(
        onPressed: () => _navigateToTournamentDetail(tournament.id),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textSecondary,
          side: BorderSide(color: colors.textMuted),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('Waitlist'),
      );
    } else {
      return OutlinedButton(
        onPressed: () => _navigateToTournamentDetail(tournament.id),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          side: BorderSide(color: colors.accent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('View'),
      );
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return 'Date TBD';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final startMonth = months[start.month - 1];

    if (end == null) {
      return '$startMonth ${start.day}';
    }

    if (start.month == end.month) {
      return '$startMonth ${start.day} - ${end.day}';
    }

    final endMonth = months[end.month - 1];
    return '$startMonth ${start.day} - $endMonth ${end.day}';
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
      for (var i = 0; i < 6; i++) {
        final y = size.height * 0.3 + (i * 15);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      for (var i = 0; i < 12; i++) {
        final x = i * 35.0;
        canvas.drawLine(
          Offset(x, size.height * 0.3),
          Offset(x, size.height * 0.3 + 75),
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
