import 'package:flutter/material.dart';
import '../../models/tournament_registration.dart';
import '../../services/tournament_service.dart';
import '../../theme/theme.dart';

class ManageLunchesScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const ManageLunchesScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<ManageLunchesScreen> createState() => _ManageLunchesScreenState();
}

class _ManageLunchesScreenState extends State<ManageLunchesScreen> {
  final _tournamentService = TournamentService();
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Track lunch changes: teamId -> {nonveg, veg, noNeed, paymentStatus}
  final Map<String, Map<String, dynamic>> _lunchChanges = {};

  static const double _lunchPrice = 10.0;

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

      // Sort by team name
      teams.sort((a, b) {
        final nameA =
            (a['teams'] as Map<String, dynamic>?)?['name'] as String? ?? '';
        final nameB =
            (b['teams'] as Map<String, dynamic>?)?['name'] as String? ?? '';
        return nameA.compareTo(nameB);
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

  Future<void> _saveAllLunches() async {
    final colors = context.colors;
    if (_lunchChanges.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes to save')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      for (final entry in _lunchChanges.entries) {
        final teamId = entry.key;
        final changes = entry.value;

        await _tournamentService.updateRegistration(
          tournamentId: widget.tournamentId,
          teamId: teamId,
          lunchNonvegCount: changes['nonveg'] as int?,
          lunchVegCount: changes['veg'] as int?,
          lunchNoNeedCount: changes['noNeed'] as int?,
          lunchPaymentStatus: changes['paymentStatus'] as LunchPaymentStatus?,
        );
      }

      _lunchChanges.clear();
      await _loadTeams();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lunch orders saved successfully'),
            backgroundColor: colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _updateLunchCount(String teamId, String type, int delta) {
    setState(() {
      // Find current values
      final team = _teams.firstWhere(
        (t) => (t['teams'] as Map<String, dynamic>?)?['id'] == teamId,
      );

      int currentNonveg =
          _lunchChanges[teamId]?['nonveg'] as int? ??
          team['lunch_nonveg_count'] as int? ??
          0;
      int currentVeg =
          _lunchChanges[teamId]?['veg'] as int? ??
          team['lunch_veg_count'] as int? ??
          0;
      int currentNoNeed =
          _lunchChanges[teamId]?['noNeed'] as int? ??
          team['lunch_no_need_count'] as int? ??
          0;

      // Apply change
      switch (type) {
        case 'nonveg':
          currentNonveg = (currentNonveg + delta).clamp(0, 99);
          break;
        case 'veg':
          currentVeg = (currentVeg + delta).clamp(0, 99);
          break;
        case 'noNeed':
          currentNoNeed = (currentNoNeed + delta).clamp(0, 99);
          break;
      }

      // Store changes
      _lunchChanges[teamId] = {
        'nonveg': currentNonveg,
        'veg': currentVeg,
        'noNeed': currentNoNeed,
        'paymentStatus': _lunchChanges[teamId]?['paymentStatus'],
      };

      // Update display
      final teamIndex = _teams.indexWhere(
        (t) => (t['teams'] as Map<String, dynamic>?)?['id'] == teamId,
      );
      if (teamIndex != -1) {
        _teams[teamIndex]['lunch_nonveg_count'] = currentNonveg;
        _teams[teamIndex]['lunch_veg_count'] = currentVeg;
        _teams[teamIndex]['lunch_no_need_count'] = currentNoNeed;
      }
    });
  }

  void _updatePaymentStatus(String teamId, LunchPaymentStatus status) {
    setState(() {
      final team = _teams.firstWhere(
        (t) => (t['teams'] as Map<String, dynamic>?)?['id'] == teamId,
      );

      _lunchChanges[teamId] = {
        'nonveg':
            _lunchChanges[teamId]?['nonveg'] ??
            team['lunch_nonveg_count'] as int? ??
            0,
        'veg':
            _lunchChanges[teamId]?['veg'] ??
            team['lunch_veg_count'] as int? ??
            0,
        'noNeed':
            _lunchChanges[teamId]?['noNeed'] ??
            team['lunch_no_need_count'] as int? ??
            0,
        'paymentStatus': status,
      };

      // Update display
      final teamIndex = _teams.indexWhere(
        (t) => (t['teams'] as Map<String, dynamic>?)?['id'] == teamId,
      );
      if (teamIndex != -1) {
        _teams[teamIndex]['lunch_payment_status'] = status.dbValue;
      }
    });
  }

  int _getTotalLunches() {
    int total = 0;
    for (final team in _teams) {
      final nonveg =
          _lunchChanges[(team['teams']
                  as Map<String, dynamic>?)?['id']]?['nonveg']
              as int? ??
          team['lunch_nonveg_count'] as int? ??
          0;
      final veg =
          _lunchChanges[(team['teams'] as Map<String, dynamic>?)?['id']]?['veg']
              as int? ??
          team['lunch_veg_count'] as int? ??
          0;
      total += nonveg + veg;
    }
    return total;
  }

  int _getTotalNonVeg() {
    int total = 0;
    for (final team in _teams) {
      final nonveg =
          _lunchChanges[(team['teams']
                  as Map<String, dynamic>?)?['id']]?['nonveg']
              as int? ??
          team['lunch_nonveg_count'] as int? ??
          0;
      total += nonveg;
    }
    return total;
  }

  int _getTotalVeg() {
    int total = 0;
    for (final team in _teams) {
      final veg =
          _lunchChanges[(team['teams'] as Map<String, dynamic>?)?['id']]?['veg']
              as int? ??
          team['lunch_veg_count'] as int? ??
          0;
      total += veg;
    }
    return total;
  }

  double _getTotalRevenue() {
    return _getTotalLunches() * _lunchPrice;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Manage Lunches'),
        actions: [
          if (_lunchChanges.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_lunchChanges.length} unsaved',
                    style: TextStyle(
                      color: colors.isDark ? colors.textPrimary : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeams,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: colors.error),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadTeams,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Summary Card
                _buildSummaryCard(),
                // Team List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _teams.length,
                    itemBuilder: (context, index) =>
                        _buildTeamLunchCard(_teams[index]),
                  ),
                ),
                // Save Button
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    final colors = context.colors;
    final totalNonVeg = _getTotalNonVeg();
    final totalVeg = _getTotalVeg();
    final totalLunches = _getTotalLunches();
    final totalRevenue = _getTotalRevenue();

    return Card(
      margin: const EdgeInsets.all(16),
      color: colors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Lunch Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryItem(
                  'Non-Veg',
                  totalNonVeg.toString(),
                  colors.volleyballPrimary,
                ),
                _buildSummaryItem('Veg', totalVeg.toString(), colors.success),
                _buildSummaryItem(
                  'Total',
                  totalLunches.toString(),
                  colors.accent,
                ),
                _buildSummaryItem(
                  'Revenue',
                  '\$${totalRevenue.toStringAsFixed(0)}',
                  colors.pickleballPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: colors.textMuted)),
      ],
    );
  }

  Widget _buildTeamLunchCard(Map<String, dynamic> registration) {
    final colors = context.colors;
    final teamData = registration['teams'] as Map<String, dynamic>?;
    final teamName = teamData?['name'] as String? ?? 'Unknown Team';
    final teamId = teamData?['id'] as String? ?? '';

    final nonveg =
        _lunchChanges[teamId]?['nonveg'] as int? ??
        registration['lunch_nonveg_count'] as int? ??
        0;
    final veg =
        _lunchChanges[teamId]?['veg'] as int? ??
        registration['lunch_veg_count'] as int? ??
        0;
    final noNeed =
        _lunchChanges[teamId]?['noNeed'] as int? ??
        registration['lunch_no_need_count'] as int? ??
        0;

    final paymentStatusStr =
        registration['lunch_payment_status'] as String? ?? 'not_paid';
    final paymentStatus =
        _lunchChanges[teamId]?['paymentStatus'] as LunchPaymentStatus? ??
        LunchPaymentStatusExtension.fromString(paymentStatusStr);

    final totalLunches = nonveg + veg;
    final totalCost = totalLunches * _lunchPrice;

    final hasChanges = _lunchChanges.containsKey(teamId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasChanges ? 4 : 1,
      color: colors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasChanges
            ? BorderSide(color: colors.warning, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Name and Total
            Row(
              children: [
                Expanded(
                  child: Text(
                    teamName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${totalCost.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Lunch Counters
            Row(
              children: [
                Expanded(
                  child: _buildLunchCounter(
                    teamId,
                    'Non-Veg',
                    nonveg,
                    'nonveg',
                    colors.volleyballPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLunchCounter(
                    teamId,
                    'Veg',
                    veg,
                    'veg',
                    colors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLunchCounter(
                    teamId,
                    'No Need',
                    noNeed,
                    'noNeed',
                    colors.textMuted,
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: colors.divider),
            // Payment Status
            Row(
              children: [
                Text(
                  'Payment Status:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                _buildPaymentStatusSelector(teamId, paymentStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLunchCounter(
    String teamId,
    String label,
    int count,
    String type,
    Color color,
  ) {
    final colors = context.colors;
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 28,
              color: count > 0 ? color : colors.textMuted,
              onPressed: count > 0
                  ? () => _updateLunchCount(teamId, type, -1)
                  : null,
            ),
            Container(
              width: 36,
              alignment: Alignment.center,
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              iconSize: 28,
              color: color,
              onPressed: () => _updateLunchCount(teamId, type, 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentStatusSelector(
    String teamId,
    LunchPaymentStatus currentStatus,
  ) {
    return SegmentedButton<LunchPaymentStatus>(
      segments: const [
        ButtonSegment<LunchPaymentStatus>(
          value: LunchPaymentStatus.notPaid,
          label: Text('Not Paid'),
          icon: Icon(Icons.cancel, size: 16),
        ),
        ButtonSegment<LunchPaymentStatus>(
          value: LunchPaymentStatus.partiallyPaid,
          label: Text('Partial'),
          icon: Icon(Icons.pending, size: 16),
        ),
        ButtonSegment<LunchPaymentStatus>(
          value: LunchPaymentStatus.paid,
          label: Text('Paid'),
          icon: Icon(Icons.check_circle, size: 16),
        ),
      ],
      selected: {currentStatus},
      onSelectionChanged: (Set<LunchPaymentStatus> selection) {
        _updatePaymentStatus(teamId, selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildBottomBar() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: colors.divider,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _lunchChanges.isNotEmpty
                    ? () {
                        setState(() {
                          _lunchChanges.clear();
                        });
                        _loadTeams();
                      }
                    : null,
                icon: const Icon(Icons.undo),
                label: const Text('Discard'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _lunchChanges.isNotEmpty && !_isSaving
                    ? _saveAllLunches
                    : null,
                icon: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textPrimary,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save All Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
