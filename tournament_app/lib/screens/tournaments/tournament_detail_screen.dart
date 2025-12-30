import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/tournament.dart';
import '../../models/tournament_registration.dart';
import '../../models/team.dart';
import '../../services/tournament_service.dart';
import 'edit_tournament_screen.dart';
import 'add_teams_screen.dart';
import 'manage_seeds_screen.dart';

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
  Tournament? _tournament;
  List<Map<String, dynamic>> _registeredTeams = [];
  bool _isLoading = true;
  bool _isLoadingTeams = false;
  String? _error;

  /// Check if current user is the organizer of this tournament
  bool get _isCurrentUserOrganizer {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || _tournament == null) return false;
    return _tournament!.organizerId == currentUserId || widget.isOrganizer;
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
      setState(() {
        _tournament = tournament;
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
    if (!_isCurrentUserOrganizer) return;

    setState(() => _isLoadingTeams = true);

    try {
      final teams = await _tournamentService.getTournamentTeams(
        widget.tournamentId,
      );
      setState(() {
        _registeredTeams = teams;
        _isLoadingTeams = false;
      });
    } catch (e) {
      setState(() => _isLoadingTeams = false);
      // Silently fail - teams section will show error state
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

  Future<void> _navigateToAddTeams() async {
    if (_tournament == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddTeamsScreen(
          tournamentId: _tournament!.id,
          tournamentName: _tournament!.name,
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

    // Refresh teams after returning from manage seeds
    await _loadRegisteredTeams();
  }

  Future<void> _removeTeamFromTournament(String teamId, String teamName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Team'),
        content: Text(
          'Are you sure you want to remove "$teamName" from this tournament?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing team: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteTournament() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tournament'),
        content: const Text(
          'Are you sure you want to delete this tournament? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting tournament: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showStatusMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: TournamentStatus.values.map((status) {
            return ListTile(
              leading: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
              ),
              title: Text(status.displayName),
              selected: _tournament?.status == status,
              onTap: () {
                Navigator.of(context).pop();
                _updateStatus(status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.registrationOpen:
        return Colors.green;
      case TournamentStatus.registrationClosed:
        return Colors.orange;
      case TournamentStatus.ongoing:
        return Colors.blue;
      case TournamentStatus.completed:
        return Colors.grey;
      case TournamentStatus.cancelled:
        return Colors.red;
    }
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

  IconData _getSportIcon(String sportType) {
    return sportType == 'volleyball'
        ? Icons.sports_volleyball
        : Icons.sports_tennis;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not set';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: _isCurrentUserOrganizer
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editTournament,
                  tooltip: 'Edit Tournament',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteTournament();
                    } else if (value == 'status') {
                      _showStatusMenu();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'status',
                      child: ListTile(
                        leading: Icon(Icons.sync),
                        title: Text('Change Status'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _tournament == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${_error ?? "Tournament not found"}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTournament,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTournament,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getSportIcon(_tournament!.sportType),
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tournament!.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tournament!.format.displayName,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: widget.isOrganizer ? _showStatusMenu : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          _tournament!.status,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(_tournament!.status),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(_tournament!.status),
                            color: _getStatusColor(_tournament!.status),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _tournament!.status.displayName,
                            style: TextStyle(
                              color: _getStatusColor(_tournament!.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.isOrganizer) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              color: _getStatusColor(_tournament!.status),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_tournament!.description != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      _tournament!.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Privacy & Invite Code Card (for organizers of private tournaments)
          if (widget.isOrganizer &&
              !_tournament!.isPublic &&
              _tournament!.inviteCode != null)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Private Tournament',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Share this invite code with teams:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _tournament!.inviteCode!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _tournament!.inviteCode!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Invite code copied to clipboard!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            tooltip: 'Copy invite code',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.isOrganizer &&
              !_tournament!.isPublic &&
              _tournament!.inviteCode != null)
            const SizedBox(height: 16),

          // Privacy Status Card (for all users)
          if (!_tournament!.isPublic)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Private Tournament',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This tournament is invite-only',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_tournament!.isPublic) const SizedBox(height: 16),

          // Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tournament Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.sports,
                    'Sport',
                    _tournament!.sportType.toUpperCase(),
                  ),
                  _buildDetailRow(
                    Icons.format_list_numbered,
                    'Format',
                    _tournament!.format.displayName,
                  ),
                  if (_tournament!.location != null)
                    _buildDetailRow(
                      Icons.location_on,
                      'Location',
                      _tournament!.location!,
                    ),
                  if (_tournament!.venueDetails != null)
                    _buildDetailRow(
                      Icons.info,
                      'Venue',
                      _tournament!.venueDetails!,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dates Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Important Dates',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.how_to_reg,
                    'Registration Deadline',
                    _formatDateTime(_tournament!.registrationDeadline),
                  ),
                  _buildDetailRow(
                    Icons.play_circle,
                    'Start Date',
                    _formatDateTime(_tournament!.startDate),
                  ),
                  _buildDetailRow(
                    Icons.stop_circle,
                    'End Date',
                    _formatDateTime(_tournament!.endDate),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Team Settings Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Requirements',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_tournament!.maxTeams != null)
                    _buildDetailRow(
                      Icons.groups,
                      'Maximum Teams',
                      '${_tournament!.maxTeams}',
                    ),
                  _buildDetailRow(
                    Icons.person,
                    'Team Size',
                    '${_tournament!.minTeamSize} - ${_tournament!.maxTeamSize} players',
                  ),
                  if (_tournament!.entryFee != null)
                    _buildDetailRow(
                      Icons.attach_money,
                      'Entry Fee',
                      '\$${_tournament!.entryFee!.toStringAsFixed(2)}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Registrations section
          if (_isCurrentUserOrganizer) _buildTeamsSection(),
        ],
      ),
    );
  }

  Widget _buildTeamsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registered Teams',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        '${_registeredTeams.length} team${_registeredTeams.length == 1 ? '' : 's'}',
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: _navigateToAddTeams,
                      tooltip: 'Add Teams',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingTeams)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_registeredTeams.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.group_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No teams registered yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _navigateToAddTeams,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Teams'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  // Action buttons row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _navigateToManageSeeds,
                          icon: const Icon(Icons.format_list_numbered),
                          label: const Text('Manage Seeds'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _navigateToAddTeams,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Teams'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._registeredTeams.map((reg) => _buildTeamTile(reg)),
                ],
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
    final homeCity = teamData['home_city'] as String?;
    final teamColor = teamData['team_color'] as String?;
    // Use registration payment_status, not team's registration_paid
    final paymentStatus =
        registration['payment_status'] as String? ?? 'pending';
    final isPaid = paymentStatus == 'paid';
    final poolAssignment = registration['pool_assignment'] as String?;
    final seedNumber = registration['seed_number'] as int?;

    Color avatarColor = Colors.blue;
    if (teamColor != null) {
      try {
        avatarColor = Color(int.parse(teamColor.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seed badge
            if (seedNumber != null)
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Center(
                  child: Text(
                    '$seedNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ),
            CircleAvatar(
              backgroundColor: avatarColor.withOpacity(0.2),
              child: Text(
                teamName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: avatarColor,
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text(teamName)),
            if (isPaid)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PAID',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'UNPAID',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            if (homeCity != null) ...[
              Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 2),
              Text(
                homeCity,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (poolAssignment != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Pool $poolAssignment',
                  style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                ),
              ),
            ],
            if (seedNumber != null) ...[
              const SizedBox(width: 4),
              Text(
                '#$seedNumber',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
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
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Registration'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.remove_circle, color: Colors.red),
                title: Text('Remove', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTeamRegistration(Map<String, dynamic> registration) async {
    final teamData = registration['teams'] as Map<String, dynamic>?;
    if (teamData == null) return;

    final teamId = teamData['id'] as String;
    final teamName = teamData['name'] as String? ?? 'Team';
    String? poolAssignment = registration['pool_assignment'] as String?;
    int? seedNumber = registration['seed_number'] as int?;
    final paymentStatusStr =
        registration['payment_status'] as String? ?? 'pending';
    PaymentStatus paymentStatus = PaymentStatusExtension.fromString(
      paymentStatusStr,
    );

    final poolController = TextEditingController(text: poolAssignment ?? '');
    final seedController = TextEditingController(
      text: seedNumber?.toString() ?? '',
    );

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        PaymentStatus dialogPaymentStatus = paymentStatus;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Edit $teamName'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Status Toggle
                  Card(
                    color: dialogPaymentStatus == PaymentStatus.paid
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            dialogPaymentStatus == PaymentStatus.paid
                                ? Icons.check_circle
                                : Icons.pending,
                            color: dialogPaymentStatus == PaymentStatus.paid
                                ? Colors.green
                                : Colors.orange,
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
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  dialogPaymentStatus.displayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        dialogPaymentStatus ==
                                            PaymentStatus.paid
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: dialogPaymentStatus == PaymentStatus.paid,
                            activeColor: Colors.green,
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
                  ),
                  const SizedBox(height: 16),

                  // Seed Number
                  TextField(
                    controller: seedController,
                    decoration: const InputDecoration(
                      labelText: 'Seed Number',
                      hintText: 'e.g., 1, 2, 3',
                      helperText: 'Lower number = stronger team',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.format_list_numbered),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Pool Assignment
                  TextField(
                    controller: poolController,
                    decoration: const InputDecoration(
                      labelText: 'Pool Assignment',
                      hintText: 'e.g., A, B, C',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grid_view),
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
                onPressed: () => Navigator.of(
                  context,
                ).pop({'paymentStatus': dialogPaymentStatus, 'save': true}),
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
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating registration: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    poolController.dispose();
    seedController.dispose();
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
