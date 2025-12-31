import 'package:flutter/material.dart';
import '../../models/tournament_staff.dart';
import '../../services/tournament_staff_service.dart';

class ManageStaffScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const ManageStaffScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  final TournamentStaffService _staffService = TournamentStaffService();

  List<TournamentStaff> _staff = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);

    try {
      final staff = await _staffService.getStaffForTournament(widget.tournamentId);
      if (mounted) {
        setState(() {
          _staff = staff;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addStaff() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddStaffDialog(
        tournamentId: widget.tournamentId,
        staffService: _staffService,
        existingStaffUserIds: _staff.map((s) => s.userId).toSet(),
      ),
    );

    if (result != null) {
      try {
        await _staffService.addStaff(
          tournamentId: widget.tournamentId,
          userId: result['user_id'] as String,
          role: result['role'] as StaffRole,
        );
        _loadStaff();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff member added'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding staff: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _changeRole(TournamentStaff staff) async {
    final newRole = staff.role == StaffRole.admin ? StaffRole.scorer : StaffRole.admin;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Role'),
        content: Text(
          'Change ${staff.displayName} from ${staff.role.displayName} to ${newRole.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _staffService.updateStaffRole(
          staffId: staff.id,
          newRole: newRole,
        );
        _loadStaff();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Changed ${staff.displayName} to ${newRole.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error changing role: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeStaff(TournamentStaff staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Staff'),
        content: Text(
          'Remove ${staff.displayName} from tournament staff?\n\n'
          'They will no longer be able to ${staff.role == StaffRole.admin ? 'manage this tournament' : 'enter scores'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _staffService.removeStaff(staff.id);
        _loadStaff();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${staff.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing staff: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Staff'),
            Text(
              widget.tournamentName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStaff,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
    );
  }

  Widget _buildBody() {
    if (_staff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No staff members yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add admins or scorers to help manage this tournament',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildRoleExplanation(),
          ],
        ),
      );
    }

    final admins = _staff.where((s) => s.role == StaffRole.admin).toList();
    final scorers = _staff.where((s) => s.role == StaffRole.scorer).toList();

    return RefreshIndicator(
      onRefresh: _loadStaff,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRoleExplanation(),
          const SizedBox(height: 24),
          if (admins.isNotEmpty) ...[
            _buildSectionHeader('Admins', Icons.admin_panel_settings, Colors.blue),
            const SizedBox(height: 8),
            ...admins.map(_buildStaffTile),
            const SizedBox(height: 16),
          ],
          if (scorers.isNotEmpty) ...[
            _buildSectionHeader('Scorers', Icons.sports_score, Colors.orange),
            const SizedBox(height: 8),
            ...scorers.map(_buildStaffTile),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleExplanation() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Staff Roles',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRoleRow(
              Icons.admin_panel_settings,
              'Admin',
              'Full control: edit tournament, manage teams, enter scores',
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildRoleRow(
              Icons.sports_score,
              'Scorer',
              'Score entry only: start matches and enter scores',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleRow(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStaffTile(TournamentStaff staff) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: staff.role == StaffRole.admin
              ? Colors.blue.shade100
              : Colors.orange.shade100,
          child: Icon(
            staff.role == StaffRole.admin
                ? Icons.admin_panel_settings
                : Icons.sports_score,
            color: staff.role == StaffRole.admin ? Colors.blue : Colors.orange,
          ),
        ),
        title: Text(staff.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (staff.userEmail != null && staff.userName != null)
              Text(
                staff.userEmail!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (staff.assignedByName != null)
              Text(
                'Added by ${staff.assignedByName}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'change_role') {
              _changeRole(staff);
            } else if (value == 'remove') {
              _removeStaff(staff);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'change_role',
              child: Row(
                children: [
                  Icon(
                    staff.role == StaffRole.admin
                        ? Icons.sports_score
                        : Icons.admin_panel_settings,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Change to ${staff.role == StaffRole.admin ? 'Scorer' : 'Admin'}',
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for adding a new staff member
class _AddStaffDialog extends StatefulWidget {
  final String tournamentId;
  final TournamentStaffService staffService;
  final Set<String> existingStaffUserIds;

  const _AddStaffDialog({
    required this.tournamentId,
    required this.staffService,
    required this.existingStaffUserIds,
  });

  @override
  State<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<_AddStaffDialog> {
  final TextEditingController _emailController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedUser;
  StaffRole _selectedRole = StaffRole.scorer;
  bool _isSearching = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await widget.staffService.searchUsersByEmail(query);
      // Filter out existing staff
      final filtered = results
          .where((u) => !widget.existingStaffUserIds.contains(u['id']))
          .toList();
      if (mounted) {
        setState(() {
          _searchResults = filtered;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Staff Member'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email search field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Search by email',
                hintText: 'Enter at least 3 characters',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 16),

            // Search results
            if (_searchResults.isNotEmpty && _selectedUser == null) ...[
              const Text(
                'Search Results:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.person, size: 16),
                      ),
                      title: Text(user['full_name'] ?? user['email']),
                      subtitle: user['full_name'] != null
                          ? Text(user['email'], style: const TextStyle(fontSize: 11))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedUser = user;
                          _emailController.text = user['email'];
                        });
                      },
                    );
                  },
                ),
              ),
            ],

            // Selected user
            if (_selectedUser != null) ...[
              const SizedBox(height: 8),
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.check, color: Colors.green),
                  ),
                  title: Text(_selectedUser!['full_name'] ?? _selectedUser!['email']),
                  subtitle: _selectedUser!['full_name'] != null
                      ? Text(_selectedUser!['email'])
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedUser = null;
                        _emailController.clear();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Role selection
              const Text(
                'Select Role:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              _buildRoleOption(
                StaffRole.scorer,
                'Scorer',
                'Can start matches and enter scores',
                Icons.sports_score,
                Colors.orange,
              ),
              const SizedBox(height: 8),
              _buildRoleOption(
                StaffRole.admin,
                'Admin',
                'Full tournament control',
                Icons.admin_panel_settings,
                Colors.blue,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedUser != null
              ? () {
                  Navigator.pop(context, {
                    'user_id': _selectedUser!['id'],
                    'role': _selectedRole,
                  });
                }
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildRoleOption(
    StaffRole role,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : null,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
