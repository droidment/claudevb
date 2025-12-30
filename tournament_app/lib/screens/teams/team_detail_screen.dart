import 'package:flutter/material.dart';
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
        title: const Text('Delete Player'),
        content: Text('Remove ${player.name} from the roster?'),
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
        await _teamService.deletePlayer(player.id);
        _loadTeamData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Player removed from roster'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing player: $e'),
              backgroundColor: Colors.red,
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
        title: const Text('Delete Team'),
        content: const Text(
          'Are you sure you want to delete this team? This action cannot be undone and will remove all players from the roster.',
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
        await _teamService.deleteTeam(widget.teamId);
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting team: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getTeamColor() {
    if (_team?.teamColor == null) return Colors.blue;
    try {
      return Color(int.parse(_team!.teamColor!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildRegistrationInfoCard() {
    // Check if we have any contact or registration info to display
    final hasAnyInfo =
        _team!.captainName != null ||
        _team!.captainEmail != null ||
        _team!.captainPhone != null ||
        _team!.contactPerson2 != null ||
        _team!.registrationDate != null ||
        _team!.specialRequests != null ||
        _team!.signedBy != null ||
        _team!.notes != null ||
        _team!.category != null ||
        _team!.playerCount != null;

    if (!hasAnyInfo) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Registration Info',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Captain Information
            if (_team!.captainName != null)
              _buildInfoRow(Icons.person, 'Captain', _team!.captainName!),
            if (_team!.captainEmail != null)
              _buildInfoRow(Icons.email, 'Email', _team!.captainEmail!),
            if (_team!.captainPhone != null)
              _buildInfoRow(Icons.phone, 'Phone', _team!.captainPhone!),
            if (_team!.category != null)
              _buildInfoRow(Icons.category, 'Category', _team!.category!),
            if (_team!.playerCount != null)
              _buildInfoRow(
                Icons.group,
                'Player Count',
                '${_team!.playerCount} players',
              ),

            // Contact Person 2
            if (_team!.contactPerson2 != null) ...[
              const Divider(height: 24),
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
                _team!.specialRequests!.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 20, color: Colors.orange[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Special Requests',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            _team!.specialRequests!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Notes
            if (_team!.notes != null && _team!.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sticky_note_2, size: 20, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            _team!.notes!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_team?.name ?? 'Team Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTeam,
            tooltip: 'Delete Team',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _team != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddPlayerDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Player'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _team == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${_error ?? "Team not found"}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTeamData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final teamColor = _getTeamColor();

    return RefreshIndicator(
      onRefresh: _loadTeamData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Team Header
          Card(
            color: teamColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: teamColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: teamColor, width: 4),
                    ),
                    child: Center(
                      child: Text(
                        _team!.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: teamColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _team!.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_team!.homeCity != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _team!.homeCity!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                  if (_team!.category != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _team!.category!,
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  // Payment status badges
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_team!.registrationPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'PAID',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pending,
                                size: 16,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'PENDING',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_team!.lunchCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.restaurant,
                                size: 16,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_team!.lunchCount} Lunches',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_team!.playerCount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group,
                                size: 16,
                                color: Colors.purple.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_team!.playerCount} Players',
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Registration Info Section
          _buildRegistrationInfoCard(),
          const SizedBox(height: 16),

          // Roster Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Roster (${_players.length} players)',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_players.isNotEmpty)
                Chip(
                  label: Text('${_players.length}'),
                  backgroundColor: teamColor.withOpacity(0.2),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_players.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Players Yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add players to your roster',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._players.map((player) => _buildPlayerCard(player)),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Player player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTeamColor().withOpacity(0.2),
          child: Text(
            player.jerseyNumber?.toString() ?? '?',
            style: TextStyle(
              color: _getTeamColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          player.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if (player.position != null)
              VolleyballPositionExtension.fromString(
                player.position,
              )?.displayName,
            if (player.heightInches != null) player.heightFormatted,
          ].where((e) => e != null).join(' • '),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding player: $e'),
            backgroundColor: Colors.red,
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
      title: const Text('Add Player'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jerseyController,
                decoration: const InputDecoration(
                  labelText: 'Jersey Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VolleyballPosition>(
                initialValue: _selectedPosition,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightFeetController,
                      decoration: const InputDecoration(
                        labelText: 'Height (ft)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _heightInchesController,
                      decoration: const InputDecoration(
                        labelText: 'Height (in)',
                        border: OutlineInputBorder(),
                      ),
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
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating player: $e'),
            backgroundColor: Colors.red,
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
      title: const Text('Edit Player'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jerseyController,
                decoration: const InputDecoration(
                  labelText: 'Jersey Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VolleyballPosition>(
                initialValue: _selectedPosition,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightFeetController,
                      decoration: const InputDecoration(
                        labelText: 'Height (ft)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _heightInchesController,
                      decoration: const InputDecoration(
                        labelText: 'Height (in)',
                        border: OutlineInputBorder(),
                      ),
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
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
