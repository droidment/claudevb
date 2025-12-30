import 'package:flutter/material.dart';
import '../../models/tournament.dart';
import '../../models/tournament_registration.dart';
import '../../services/tournament_service.dart';

class ManageSeedsScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const ManageSeedsScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<ManageSeedsScreen> createState() => _ManageSeedsScreenState();
}

class _ManageSeedsScreenState extends State<ManageSeedsScreen> {
  final _tournamentService = TournamentService();
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Track changes: teamId -> seedNumber
  final Map<String, int?> _seedChanges = {};
  // Track pool changes: teamId -> poolAssignment
  final Map<String, String?> _poolChanges = {};

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teams = await _tournamentService.getTournamentTeams(
        widget.tournamentId,
      );

      // Sort by current seed number, unseeded teams at the end
      teams.sort((a, b) {
        final seedA = a['seed_number'] as int?;
        final seedB = b['seed_number'] as int?;
        if (seedA == null && seedB == null) return 0;
        if (seedA == null) return 1;
        if (seedB == null) return -1;
        return seedA.compareTo(seedB);
      });

      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAllSeeds() async {
    if (_seedChanges.isEmpty && _poolChanges.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes to save')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save all seed and pool changes
      final allTeamIds = {..._seedChanges.keys, ..._poolChanges.keys};
      for (final teamId in allTeamIds) {
        // Only pass values that have changed
        final hasSeedChange = _seedChanges.containsKey(teamId);
        final hasPoolChange = _poolChanges.containsKey(teamId);

        await _tournamentService.updateRegistration(
          tournamentId: widget.tournamentId,
          teamId: teamId,
          seedNumber: hasSeedChange ? _seedChanges[teamId] : null,
          updateSeedNumber: hasSeedChange,
          poolAssignment: hasPoolChange ? _poolChanges[teamId] : null,
          updatePoolAssignment: hasPoolChange,
        );
      }

      _seedChanges.clear();
      _poolChanges.clear();
      await _loadTeams();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seeds saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving seeds: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _autoAssignSeeds() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-Assign Seeds'),
        content: const Text(
          'This will assign seed numbers 1, 2, 3... to all teams in their current order.\n\n'
          'Drag teams to reorder them first if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                for (int i = 0; i < _teams.length; i++) {
                  final teamData = _teams[i]['teams'] as Map<String, dynamic>?;
                  if (teamData != null) {
                    final teamId = teamData['id'] as String;
                    _seedChanges[teamId] = i + 1;
                    _teams[i]['seed_number'] = i + 1;
                  }
                }
              });
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _clearAllSeeds() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Seeds'),
        content: const Text('This will remove seed numbers from all teams.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                for (final team in _teams) {
                  final teamData = team['teams'] as Map<String, dynamic>?;
                  if (teamData != null) {
                    final teamId = teamData['id'] as String;
                    _seedChanges[teamId] = null;
                    team['seed_number'] = null;
                  }
                }
              });
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  /// Calculate optimal number of pools for given team count
  /// Tries to get pools of 4-6 teams each
  int _calculateOptimalPoolCount(int teamCount) {
    if (teamCount <= 6) return 1;
    if (teamCount <= 12) return 2;
    if (teamCount <= 18) return 3;
    if (teamCount <= 24) return 4;
    if (teamCount <= 30) return 5;
    if (teamCount <= 36) return 6;
    // For larger tournaments, aim for pools of 5-6
    return (teamCount / 5).ceil();
  }

  /// Assign pools using snake draft based on seeds
  /// e.g., 4 pools: 1->A, 2->B, 3->C, 4->D, 5->D, 6->C, 7->B, 8->A, 9->A, ...
  void _autoAssignPools() {
    // Check if all teams have seeds
    final unseededTeams = _teams.where((t) => t['seed_number'] == null).length;
    if (unseededTeams > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seeds Required'),
          content: Text(
            '$unseededTeams team${unseededTeams == 1 ? ' has' : 's have'} no seed assigned.\n\n'
            'Please assign seeds to all teams first (use "Auto-assign Seeds"), '
            'then assign pools.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final teamCount = _teams.length;
    final suggestedPools = _calculateOptimalPoolCount(teamCount);

    showDialog(
      context: context,
      builder: (context) {
        int numberOfPools = suggestedPools;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final teamsPerPool = (teamCount / numberOfPools).ceil();
            final poolNames = List.generate(
              numberOfPools,
              (i) => String.fromCharCode('A'.codeUnitAt(0) + i),
            );

            return AlertDialog(
              title: const Text('Auto-Assign Pools'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribute $teamCount teams into pools using snake draft.\n'
                    '(Seed 1→A, 2→B, 3→C, 4→D, 5→D, 6→C, ...)',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Number of Pools: '),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: numberOfPools,
                        items: List.generate(8, (i) => i + 2)
                            .map(
                              (n) =>
                                  DropdownMenuItem(value: n, child: Text('$n')),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => numberOfPools = value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pool Preview:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pools ${poolNames.join(", ")}',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                        Text(
                          '~$teamsPerPool teams per pool',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _assignPoolsSnakeDraft(numberOfPools);
                  },
                  child: const Text('Assign Pools'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _assignPoolsSnakeDraft(int numberOfPools) {
    setState(() {
      // Sort teams by seed
      final sortedTeams = List<Map<String, dynamic>>.from(_teams);
      sortedTeams.sort((a, b) {
        final seedA = a['seed_number'] as int? ?? 9999;
        final seedB = b['seed_number'] as int? ?? 9999;
        return seedA.compareTo(seedB);
      });

      // Snake draft assignment
      final poolNames = List.generate(
        numberOfPools,
        (i) => String.fromCharCode('A'.codeUnitAt(0) + i),
      );

      for (int i = 0; i < sortedTeams.length; i++) {
        final team = sortedTeams[i];
        final teamData = team['teams'] as Map<String, dynamic>?;
        if (teamData == null) continue;

        final teamId = teamData['id'] as String;

        // Snake draft: determine direction based on row
        final row = i ~/ numberOfPools;
        final posInRow = i % numberOfPools;
        final poolIndex = row.isEven
            ? posInRow
            : (numberOfPools - 1 - posInRow);
        final poolName = poolNames[poolIndex];

        _poolChanges[teamId] = poolName;

        // Update local state for display
        for (final t in _teams) {
          final td = t['teams'] as Map<String, dynamic>?;
          if (td != null && td['id'] == teamId) {
            t['pool_assignment'] = poolName;
            break;
          }
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Assigned ${_teams.length} teams to $numberOfPools pools',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _clearAllPools() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Pools'),
        content: const Text(
          'This will remove pool assignments from all teams.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                for (final team in _teams) {
                  final teamData = team['teams'] as Map<String, dynamic>?;
                  if (teamData != null) {
                    final teamId = teamData['id'] as String;
                    _poolChanges[teamId] = null;
                    team['pool_assignment'] = null;
                  }
                }
              });
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Seeds'),
            Text(
              widget.tournamentName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (_seedChanges.isNotEmpty || _poolChanges.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  '${_seedChanges.length + _poolChanges.length} changes',
                ),
                backgroundColor: Colors.orange.shade100,
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'auto_seeds':
                  _autoAssignSeeds();
                  break;
                case 'clear_seeds':
                  _clearAllSeeds();
                  break;
                case 'auto_pools':
                  _autoAssignPools();
                  break;
                case 'clear_pools':
                  _clearAllPools();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'auto_seeds',
                child: ListTile(
                  leading: Icon(Icons.format_list_numbered),
                  title: Text('Auto-assign Seeds'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'auto_pools',
                child: ListTile(
                  leading: Icon(Icons.grid_view),
                  title: Text('Auto-assign Pools'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_seeds',
                child: ListTile(
                  leading: Icon(Icons.clear, color: Colors.red),
                  title: Text(
                    'Clear All Seeds',
                    style: TextStyle(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_pools',
                child: ListTile(
                  leading: Icon(Icons.clear_all, color: Colors.red),
                  title: Text(
                    'Clear All Pools',
                    style: TextStyle(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: (_seedChanges.isNotEmpty || _poolChanges.isNotEmpty)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveAllSeeds,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save All Changes'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadTeams, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No teams registered',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add teams to the tournament first',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Drag teams to reorder, or tap to edit seed number. Lower seed = stronger team.',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),

        // Teams list
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _teams.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _teams.removeAt(oldIndex);
                _teams.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              return _buildTeamItem(_teams[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamItem(Map<String, dynamic> registration, int index) {
    final teamData = registration['teams'] as Map<String, dynamic>?;
    if (teamData == null) {
      return const SizedBox.shrink(key: ValueKey('empty'));
    }

    final teamId = teamData['id'] as String;
    final teamName = teamData['name'] as String? ?? 'Unknown Team';
    final homeCity = teamData['home_city'] as String?;
    final teamColor = teamData['team_color'] as String?;
    final seedNumber = registration['seed_number'] as int?;
    final poolAssignment = registration['pool_assignment'] as String?;
    final paymentStatus =
        registration['payment_status'] as String? ?? 'pending';
    final isPaid = paymentStatus == 'paid';

    Color avatarColor = Colors.blue;
    if (teamColor != null) {
      try {
        avatarColor = Color(int.parse(teamColor.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    final hasSeedChange = _seedChanges.containsKey(teamId);
    final hasPoolChange = _poolChanges.containsKey(teamId);
    final hasChange = hasSeedChange || hasPoolChange;

    return Card(
      key: ValueKey(teamId),
      margin: const EdgeInsets.only(bottom: 8),
      color: hasChange ? Colors.yellow.shade50 : null,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            // Seed badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: seedNumber != null
                    ? Colors.amber.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: seedNumber != null
                    ? Border.all(color: Colors.amber.shade400, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  seedNumber?.toString() ?? '-',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: seedNumber != null
                        ? Colors.amber.shade800
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: avatarColor.withOpacity(0.2),
              child: Text(
                teamName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: avatarColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
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
              ),
          ],
        ),
        subtitle: Row(
          children: [
            if (poolAssignment != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Text(
                  'Pool $poolAssignment',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (homeCity != null) ...[
              Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  homeCity,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editSeed(teamId, teamName, seedNumber),
        ),
        onTap: () => _editSeed(teamId, teamName, seedNumber),
      ),
    );
  }

  Future<void> _editSeed(
    String teamId,
    String teamName,
    int? currentSeed,
  ) async {
    final controller = TextEditingController(
      text: currentSeed?.toString() ?? '',
    );

    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seed for $teamName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Seed Number',
            hintText: 'e.g., 1, 2, 3',
            helperText: 'Leave empty to remove seed',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final seed = int.tryParse(controller.text);
              Navigator.pop(context, seed ?? -1); // -1 means clear
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null) {
      setState(() {
        final newSeed = result == -1 ? null : result;
        _seedChanges[teamId] = newSeed;

        // Update local state
        for (final team in _teams) {
          final data = team['teams'] as Map<String, dynamic>?;
          if (data != null && data['id'] == teamId) {
            team['seed_number'] = newSeed;
            break;
          }
        }
      });
    }
  }
}
