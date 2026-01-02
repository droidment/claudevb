import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/team.dart';
import '../../models/player.dart';
import '../../services/team_service.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final _teamService = TeamService();
  Team? _team;
  List<Player> _players = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final team = await _teamService.getTeam(widget.teamId);
      final players = await _teamService.getTeamPlayers(widget.teamId);

      setState(() {
        _team = team;
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddPlayerDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddPlayerDialog(teamId: widget.teamId),
    );

    if (result == true) {
      _loadTeamData();
    }
  }

  Future<void> _showEditPlayerDialog(Player player) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditPlayerDialog(player: player),
    );

    if (result == true) {
      _loadTeamData();
    }
  }

  Future<void> _deletePlayer(Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Delete Player',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove ${player.name} from the roster?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _teamService.deletePlayer(player.id);
        _loadTeamData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Player removed from roster'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing player: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteTeam() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Delete Team',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this team? This action cannot be undone and will remove all players from the roster.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _teamService.deleteTeam(widget.teamId);
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting team: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Color _getTeamColor() {
    if (_team?.teamColor == null) return AppColors.accent;
    try {
      return Color(int.parse(_team!.teamColor!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.accent;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData _getSportIcon() {
    return _team?.sportType == 'volleyball'
        ? Icons.sports_volleyball
        : Icons.sports_tennis;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
      floatingActionButton: _team != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddPlayerDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Player'),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null || _team == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error: ${_error ?? "Team not found"}',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadTeamData,
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeamData,
      color: AppColors.accent,
      child: CustomScrollView(
        slivers: [
          _buildHeroHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats cards
                  _buildStatsRow(),
                  const SizedBox(height: 24),

                  // Registration Info
                  if (_hasRegistrationInfo()) ...[
                    _buildRegistrationInfoSection(),
                    const SizedBox(height: 24),
                  ],

                  // Roster Section
                  _buildRosterSection(),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    final teamColor = _getTeamColor();

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.background,
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
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          color: AppColors.cardBackground,
          onSelected: (value) {
            if (value == 'delete') {
              _deleteTeam();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text('Delete Team',
                    style: TextStyle(color: AppColors.error)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    teamColor.withValues(alpha: 0.6),
                    AppColors.cardBackgroundLight,
                  ],
                ),
              ),
            ),
            // Sport pattern
            CustomPaint(
              painter: _SportPatternPainter(_team!.sportType),
            ),
            // Large Sport Icon
            Positioned(
              right: -30,
              top: 20,
              child: Icon(
                _getSportIcon(),
                size: 180,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            // Bottom gradient for text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.background.withValues(alpha: 0.8),
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),
            // Team Info
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badges
                  Row(
                    children: [
                      _buildStatusBadge(
                        _team!.registrationPaid ? 'PAID' : 'PENDING',
                        _team!.registrationPaid
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getSportIcon(),
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _team!.sportType[0].toUpperCase() +
                                  _team!.sportType.substring(1),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Team Name
                  Text(
                    _team!.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_team!.homeCity != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _team!.homeCity!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.group,
            '${_players.length}',
            'PLAYERS',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.restaurant,
            '${_team!.lunchCount}',
            'LUNCHES',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.people,
            '${_team!.playerCount ?? _players.length}',
            'ROSTER SIZE',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasRegistrationInfo() {
    return _team!.captainName != null ||
        _team!.captainEmail != null ||
        _team!.captainPhone != null ||
        _team!.contactPerson2 != null ||
        _team!.registrationDate != null ||
        _team!.specialRequests != null ||
        _team!.signedBy != null ||
        _team!.notes != null ||
        _team!.category != null;
  }

  Widget _buildRegistrationInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registration Info',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Captain Information
              if (_team!.captainName != null)
                _buildInfoRow(Icons.person, 'Captain', _team!.captainName!),
              if (_team!.captainEmail != null)
                _buildInfoRow(Icons.email, 'Email', _team!.captainEmail!),
              if (_team!.captainPhone != null)
                _buildInfoRow(Icons.phone, 'Phone', _team!.captainPhone!),
              if (_team!.category != null)
                _buildInfoRow(Icons.category, 'Category', _team!.category!),

              // Contact Person 2
              if (_team!.contactPerson2 != null) ...[
                _buildInfoRow(
                  Icons.person_outline,
                  'Contact Person 2',
                  _team!.contactPerson2!,
                ),
                if (_team!.contactPhone2 != null)
                  _buildInfoRow(
                    Icons.phone_outlined,
                    'Phone 2',
                    _team!.contactPhone2!,
                  ),
              ],

              // Registration Details
              if (_team!.registrationDate != null)
                _buildInfoRow(
                  Icons.calendar_today,
                  'Registered',
                  _formatDate(_team!.registrationDate),
                ),
              if (_team!.signedBy != null)
                _buildInfoRow(Icons.draw, 'Signed By', _team!.signedBy!),

              // Special Requests
              if (_team!.specialRequests != null &&
                  _team!.specialRequests!.isNotEmpty)
                _buildNotesRow(
                  Icons.note,
                  'Special Requests',
                  _team!.specialRequests!,
                  AppColors.warning,
                ),

              // Notes
              if (_team!.notes != null && _team!.notes!.isNotEmpty)
                _buildNotesRow(
                  Icons.sticky_note_2,
                  'Notes',
                  _team!.notes!,
                  AppColors.accent,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesRow(
      IconData icon, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Roster',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_players.length} players',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_players.isEmpty)
          _buildEmptyRosterCard()
        else
          ..._players.map((player) => _buildPlayerCard(player)),
      ],
    );
  }

  Widget _buildEmptyRosterCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.person_add_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Players Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add players to your roster',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Player player) {
    final teamColor = _getTeamColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: teamColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: teamColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              player.jerseyNumber?.toString() ?? '?',
              style: TextStyle(
                color: teamColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          player.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          [
            if (player.position != null)
              VolleyballPositionExtension.fromString(
                player.position,
              )?.displayName,
            if (player.heightInches != null) player.heightFormatted,
          ].where((e) => e != null).join(' • '),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          color: AppColors.cardBackground,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: AppColors.textSecondary),
                  SizedBox(width: 12),
                  Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppColors.error),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditPlayerDialog(player);
            } else if (value == 'delete') {
              _deletePlayer(player);
            }
          },
        ),
      ),
    );
  }
}

/// Custom painter for sport pattern background
class _SportPatternPainter extends CustomPainter {
  final String sportType;

  _SportPatternPainter(this.sportType);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Draw scattered sport-related shapes
    for (var i = 0; i < 8; i++) {
      final x = (i * 0.15 + 0.05) * size.width;
      final y = (i % 3 * 0.3 + 0.1) * size.height;
      canvas.drawCircle(Offset(x, y), 20, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Add Player Dialog
class AddPlayerDialog extends StatefulWidget {
  final String teamId;

  const AddPlayerDialog({super.key, required this.teamId});

  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _teamService = TeamService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jerseyController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();

  VolleyballPosition? _selectedPosition;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jerseyController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    super.dispose();
  }

  Future<void> _addPlayer(String teamId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      int? heightInches;
      if (_heightFeetController.text.isNotEmpty ||
          _heightInchesController.text.isNotEmpty) {
        final feet = int.tryParse(_heightFeetController.text) ?? 0;
        final inches = int.tryParse(_heightInchesController.text) ?? 0;
        heightInches = (feet * 12) + inches;
      }

      await _teamService.addPlayer(
        teamId: teamId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        jerseyNumber: _jerseyController.text.isEmpty
            ? null
            : int.tryParse(_jerseyController.text),
        position: _selectedPosition?.dbValue,
        heightInches: heightInches,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Player added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding player: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: const Text(
        'Add Player',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Name *',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _jerseyController,
                label: 'Jersey Number',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<VolleyballPosition>(
                  initialValue: _selectedPosition,
                  dropdownColor: AppColors.cardBackground,
                  decoration: const InputDecoration(
                    labelText: 'Position',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: VolleyballPosition.values.map((position) {
                    return DropdownMenuItem(
                      value: position,
                      child: Text(position.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPosition = value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _heightFeetController,
                      label: 'Height (ft)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _heightInchesController,
                      label: 'Height (in)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : () => _addPlayer(widget.teamId),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardBackgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

// Edit Player Dialog
class EditPlayerDialog extends StatefulWidget {
  final Player player;

  const EditPlayerDialog({super.key, required this.player});

  @override
  State<EditPlayerDialog> createState() => _EditPlayerDialogState();
}

class _EditPlayerDialogState extends State<EditPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _teamService = TeamService();
  late TextEditingController _nameController;
  late TextEditingController _jerseyController;
  late TextEditingController _heightFeetController;
  late TextEditingController _heightInchesController;

  VolleyballPosition? _selectedPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player.name);
    _jerseyController = TextEditingController(
      text: widget.player.jerseyNumber?.toString() ?? '',
    );

    if (widget.player.heightInches != null) {
      _heightFeetController = TextEditingController(
        text: (widget.player.heightInches! ~/ 12).toString(),
      );
      _heightInchesController = TextEditingController(
        text: (widget.player.heightInches! % 12).toString(),
      );
    } else {
      _heightFeetController = TextEditingController();
      _heightInchesController = TextEditingController();
    }

    _selectedPosition = VolleyballPositionExtension.fromString(
      widget.player.position,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jerseyController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    super.dispose();
  }

  Future<void> _updatePlayer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      int? heightInches;
      if (_heightFeetController.text.isNotEmpty ||
          _heightInchesController.text.isNotEmpty) {
        final feet = int.tryParse(_heightFeetController.text) ?? 0;
        final inches = int.tryParse(_heightInchesController.text) ?? 0;
        heightInches = (feet * 12) + inches;
      }

      await _teamService.updatePlayer(widget.player.id, {
        'name': _nameController.text.trim(),
        'jersey_number': _jerseyController.text.isEmpty
            ? null
            : int.tryParse(_jerseyController.text),
        'position': _selectedPosition?.dbValue,
        'height_inches': heightInches,
      });

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Player updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating player: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: const Text(
        'Edit Player',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Name *',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _jerseyController,
                label: 'Jersey Number',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<VolleyballPosition>(
                  initialValue: _selectedPosition,
                  dropdownColor: AppColors.cardBackground,
                  decoration: const InputDecoration(
                    labelText: 'Position',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: VolleyballPosition.values.map((position) {
                    return DropdownMenuItem(
                      value: position,
                      child: Text(position.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPosition = value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _heightFeetController,
                      label: 'Height (ft)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _heightInchesController,
                      label: 'Height (in)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _updatePlayer,
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardBackgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
