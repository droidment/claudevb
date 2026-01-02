import 'package:flutter/material.dart';
import '../../models/team.dart';
import '../../services/tournament_service.dart';
import '../../theme/theme.dart';

class AddTeamsScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final String sportType;

  const AddTeamsScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.sportType,
  });

  @override
  State<AddTeamsScreen> createState() => _AddTeamsScreenState();
}

class _AddTeamsScreenState extends State<AddTeamsScreen> {
  final _tournamentService = TournamentService();
  List<Team> _availableTeams = [];
  Set<String> _selectedTeamIds = {};
  bool _isLoading = true;
  bool _isAdding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailableTeams();
  }

  Future<void> _loadAvailableTeams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teams = await _tournamentService.getAvailableTeams(
        widget.tournamentId,
        sportType: widget.sportType,
      );
      setState(() {
        _availableTeams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addSelectedTeams() async {
    final colors = context.colors;
    if (_selectedTeamIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one team'),
          backgroundColor: colors.warning,
        ),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      await _tournamentService.registerTeams(
        tournamentId: widget.tournamentId,
        teamIds: _selectedTeamIds.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedTeamIds.length} team(s) added successfully',
            ),
            backgroundColor: colors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding teams: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  void _toggleTeamSelection(String teamId) {
    setState(() {
      if (_selectedTeamIds.contains(teamId)) {
        _selectedTeamIds.remove(teamId);
      } else {
        _selectedTeamIds.add(teamId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedTeamIds = _availableTeams.map((t) => t.id).toSet();
    });
  }

  void _selectNone() {
    setState(() {
      _selectedTeamIds.clear();
    });
  }

  Color _getTeamColor(String? teamColor) {
    final colors = context.colors;
    if (teamColor == null) return colors.accent;
    try {
      return Color(int.parse(teamColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return colors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Add Teams'),
        actions: [
          if (_availableTeams.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'all') {
                  _selectAll();
                } else if (value == 'none') {
                  _selectNone();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('Select All')),
                const PopupMenuItem(value: 'none', child: Text('Select None')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: colors.accentSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adding to:',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.tournamentName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.sports,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Showing ${widget.sportType == 'volleyball' ? 'Volleyball' : 'Pickleball'} teams only',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (_selectedTeamIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedTeamIds.length} team(s) selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Body
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _availableTeams.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _isAdding || _selectedTeamIds.isEmpty
                      ? null
                      : _addSelectedTeams,
                  icon: _isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(
                    _isAdding
                        ? 'Adding...'
                        : 'Add ${_selectedTeamIds.length} Team(s)',
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    final colors = context.colors;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAvailableTeams,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_availableTeams.isEmpty) {
      final sportTypeName =
          widget.sportType == 'volleyball' ? 'Volleyball' : 'Pickleball';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 80, color: colors.textMuted),
            const SizedBox(height: 24),
            Text(
              'No $sportTypeName Teams Available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'All your $sportTypeName teams have already been added to this tournament, or you haven\'t created any $sportTypeName teams yet.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAvailableTeams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableTeams.length,
        itemBuilder: (context, index) {
          final team = _availableTeams[index];
          final isSelected = _selectedTeamIds.contains(team.id);
          return _buildTeamCard(team, isSelected);
        },
      ),
    );
  }

  Widget _buildTeamCard(Team team, bool isSelected) {
    final colors = context.colors;
    final teamColor = _getTeamColor(team.teamColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colors.accent, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _toggleTeamSelection(team.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleTeamSelection(team.id),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              // Team avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: teamColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    team.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: teamColor,
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
                      team.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (team.homeCity != null) ...[
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
                            team.homeCity!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (team.captainPhone != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: colors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            team.captainPhone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Paid status indicator
              if (team.registrationPaid)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: colors.success),
                      const SizedBox(width: 4),
                      Text(
                        'PAID',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
