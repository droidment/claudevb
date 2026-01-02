import 'package:flutter/material.dart';
import '../../models/tournament.dart';
import '../../services/tournament_service.dart';
import '../../theme/theme.dart';
import 'create_tournament_screen.dart';
import 'tournament_detail_screen.dart';

class OrganizeScreen extends StatefulWidget {
  const OrganizeScreen({super.key});

  @override
  State<OrganizeScreen> createState() => _OrganizeScreenState();
}

class _OrganizeScreenState extends State<OrganizeScreen> {
  final _tournamentService = TournamentService();
  List<Tournament> _tournaments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournaments = await _tournamentService.getMyTournaments();
      setState(() {
        _tournaments = tournaments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToCreateTournament() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
    );

    if (result == true) {
      _loadTournaments();
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
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateTournament,
        icon: const Icon(Icons.add),
        label: const Text('Create Tournament'),
      ),
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
              onPressed: _loadTournaments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 100,
              color: colors.textMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'No Tournaments Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first tournament to get started!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _navigateToCreateTournament,
              icon: const Icon(Icons.add),
              label: const Text('Create Tournament'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTournaments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tournaments.length,
        itemBuilder: (context, index) {
          final tournament = _tournaments[index];
          return _buildTournamentCard(tournament);
        },
      ),
    );
  }

  Future<void> _navigateToTournamentDetail(String tournamentId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TournamentDetailScreen(
          tournamentId: tournamentId,
          isOrganizer: true,
        ),
      ),
    );

    if (result == true) {
      _loadTournaments();
    }
  }

  Widget _buildTournamentCard(Tournament tournament) {
    final colors = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToTournamentDetail(tournament.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getSportIcon(tournament.sportType),
                    size: 32,
                    color: colors.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tournament.format.displayName,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      tournament.status.displayName,
                      style: TextStyle(
                        color: colors.isDark ? colors.textPrimary : Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: _getStatusColor(tournament.status),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (tournament.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  tournament.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (tournament.location != null) ...[
                    Icon(Icons.location_on, size: 16, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tournament.location!,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (tournament.startDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tournament.startDate!.month}/${tournament.startDate!.day}/${tournament.startDate!.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              if (tournament.maxTeams != null ||
                  tournament.entryFee != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (tournament.maxTeams != null) ...[
                      Icon(Icons.groups, size: 16, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Max ${tournament.maxTeams} teams',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (tournament.entryFee != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.attach_money,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      Text(
                        '\$${tournament.entryFee!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
