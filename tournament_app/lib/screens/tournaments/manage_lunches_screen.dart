import 'package:flutter/material.dart';
import '../../models/tournament_registration.dart';
import '../../services/tournament_service.dart';

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
          const SnackBar(
            content: Text('Lunch orders saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
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
    return Scaffold(
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
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_lunchChanges.length} unsaved',
                    style: const TextStyle(
                      color: Colors.white,
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
                  Icon(Icons.error, size: 64, color: Colors.red),
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
    final totalNonVeg = _getTotalNonVeg();
    final totalVeg = _getTotalVeg();
    final totalLunches = _getTotalLunches();
    final totalRevenue = _getTotalRevenue();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Lunch Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryItem(
                  '🍗 Non-Veg',
                  totalNonVeg.toString(),
                  Colors.brown,
                ),
                _buildSummaryItem('🥗 Veg', totalVeg.toString(), Colors.green),
                _buildSummaryItem(
                  '📦 Total',
                  totalLunches.toString(),
                  Colors.blue,
                ),
                _buildSummaryItem(
                  '💰 Revenue',
                  '\$${totalRevenue.toStringAsFixed(0)}',
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTeamLunchCard(Map<String, dynamic> registration) {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasChanges
            ? BorderSide(color: Colors.orange, width: 2)
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${totalCost.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue,
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
                    '🍗 Non-Veg',
                    nonveg,
                    'nonveg',
                    Colors.brown,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLunchCounter(
                    teamId,
                    '🥗 Veg',
                    veg,
                    'veg',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLunchCounter(
                    teamId,
                    '🚫 No Need',
                    noNeed,
                    'noNeed',
                    Colors.grey,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Payment Status
            Row(
              children: [
                const Text(
                  'Payment Status:',
                  style: TextStyle(fontWeight: FontWeight.w500),
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
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 28,
              color: count > 0 ? color : Colors.grey[300],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
          ],
        ),
      ),
    );
  }
}
