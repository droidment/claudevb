import 'package:flutter/material.dart';
import '../../models/tournament.dart';
import '../../services/tournament_service.dart';
import '../../theme/theme.dart';
import 'tournament_detail_screen.dart';

class JoinByInviteScreen extends StatefulWidget {
  const JoinByInviteScreen({super.key});

  @override
  State<JoinByInviteScreen> createState() => _JoinByInviteScreenState();
}

class _JoinByInviteScreenState extends State<JoinByInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  final _tournamentService = TournamentService();

  bool _isSearching = false;
  Tournament? _foundTournament;
  String? _error;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _searchByInviteCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _foundTournament = null;
    });

    try {
      final inviteCode = _inviteCodeController.text.trim().toUpperCase();
      final tournament = await _tournamentService.getTournamentByInviteCode(inviteCode);

      setState(() {
        if (tournament != null) {
          _foundTournament = tournament;
        } else {
          _error = 'No tournament found with this invite code';
        }
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error searching for tournament: $e';
        _isSearching = false;
      });
    }
  }

  void _viewTournamentDetails() {
    if (_foundTournament != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TournamentDetailScreen(
            tournamentId: _foundTournament!.id,
            isOrganizer: false,
          ),
        ),
      );
    }
  }

  Color _getStatusColor(TournamentStatus status) {
    final colors = context.colors;
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

  IconData _getSportIcon(String sportType) {
    return sportType == 'volleyball'
        ? Icons.sports_volleyball
        : Icons.sports_tennis;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Join Private Tournament'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                color: colors.warningLight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock_open,
                        size: 64,
                        color: colors.warning,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Join Private Tournament',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the invite code shared by the tournament organizer to access and join a private tournament.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Invite Code Input
              TextFormField(
                controller: _inviteCodeController,
                decoration: const InputDecoration(
                  labelText: 'Invite Code',
                  hintText: 'e.g., A7B2E9F1',
                  prefixIcon: Icon(Icons.vpn_key),
                  border: OutlineInputBorder(),
                  helperText: 'Enter the 8-character invite code',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an invite code';
                  }
                  if (value.trim().length != 8) {
                    return 'Invite code must be 8 characters';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _searchByInviteCode(),
              ),
              const SizedBox(height: 16),

              // Search Button
              FilledButton.icon(
                onPressed: _isSearching ? null : _searchByInviteCode,
                icon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isSearching ? 'Searching...' : 'Find Tournament'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_error != null) ...[
                Card(
                  color: colors.errorLight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tournament Found
              if (_foundTournament != null) ...[
                Text(
                  'Tournament Found!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.success,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  child: InkWell(
                    onTap: _viewTournamentDetails,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getSportIcon(_foundTournament!.sportType),
                                size: 40,
                                color: colors.accent,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _foundTournament!.name,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _foundTournament!.format.displayName,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_foundTournament!.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor(_foundTournament!.status),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: _getStatusColor(_foundTournament!.status),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Private - ${_foundTournament!.status.displayName}',
                                  style: TextStyle(
                                    color: _getStatusColor(_foundTournament!.status),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_foundTournament!.description != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _foundTournament!.description!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          if (_foundTournament!.location != null)
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 18, color: colors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _foundTournament!.location!,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          if (_foundTournament!.startDate != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: colors.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  'Starts: ${_foundTournament!.startDate!.month}/${_foundTournament!.startDate!.day}/${_foundTournament!.startDate!.year}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _viewTournamentDetails,
                            icon: const Icon(Icons.visibility),
                            label: const Text('View Full Details'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),
                          if (_foundTournament!.status == TournamentStatus.registrationOpen) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Team registration coming soon!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.how_to_reg),
                              label: const Text('Register Your Team'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                                foregroundColor: colors.success,
                                side: BorderSide(color: colors.success, width: 2),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Help Section
              const SizedBox(height: 32),
              Card(
                color: colors.accentLight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help_outline, color: colors.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Need Help?',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '- Ask the tournament organizer for the invite code\n'
                        '- The code is 8 characters long (letters and numbers)\n'
                        '- Codes are case-insensitive\n'
                        '- Make sure registration is still open',
                        style: TextStyle(color: colors.textPrimary, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
