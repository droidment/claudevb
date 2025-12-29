import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tournament.dart';
import '../../services/tournament_service.dart';
import 'edit_tournament_screen.dart';

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
  bool _isLoading = true;
  String? _error;

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
      final tournament = await _tournamentService.getTournament(widget.tournamentId);
      setState(() {
        _tournament = tournament;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(TournamentStatus newStatus) async {
    try {
      await _tournamentService.updateTournamentStatus(widget.tournamentId, newStatus);
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
        actions: widget.isOrganizer
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editTournament,
                  tooltip: 'Edit Tournament',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteTournament,
                  tooltip: 'Delete Tournament',
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
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tournament!.format.displayName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_tournament!.status).withOpacity(0.1),
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
          if (widget.isOrganizer && !_tournament!.isPublic && _tournament!.inviteCode != null)
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        border: Border.all(color: Colors.orange.shade300, width: 2),
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
                                  content: Text('Invite code copied to clipboard!'),
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
          if (widget.isOrganizer && !_tournament!.isPublic && _tournament!.inviteCode != null)
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
          if (!_tournament!.isPublic)
            const SizedBox(height: 16),

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
                  _buildDetailRow(Icons.sports, 'Sport', _tournament!.sportType.toUpperCase()),
                  _buildDetailRow(Icons.format_list_numbered, 'Format', _tournament!.format.displayName),
                  if (_tournament!.location != null)
                    _buildDetailRow(Icons.location_on, 'Location', _tournament!.location!),
                  if (_tournament!.venueDetails != null)
                    _buildDetailRow(Icons.info, 'Venue', _tournament!.venueDetails!),
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

          // Registrations section (placeholder for future)
          if (widget.isOrganizer)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Team Registrations',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Chip(label: Text('0 teams')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Registration management coming soon',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
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
