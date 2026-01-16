import 'package:flutter/material.dart';
import '../../models/scoring_config.dart';
import '../../theme/theme.dart';

/// Screen to configure phase-based scoring for a tournament
class ScoringConfigScreen extends StatefulWidget {
  final String sportType;
  final TournamentScoringConfig? initialConfig;

  const ScoringConfigScreen({
    super.key,
    required this.sportType,
    this.initialConfig,
  });

  @override
  State<ScoringConfigScreen> createState() => _ScoringConfigScreenState();
}

class _ScoringConfigScreenState extends State<ScoringConfigScreen> {
  late TournamentScoringConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig ??
        (widget.sportType == 'pickleball'
            ? TournamentScoringConfig.pickleballDefault()
            : TournamentScoringConfig.volleyballDefault());
  }

  bool get isVolleyball => widget.sportType == 'volleyball';

  List<PhaseScoring> get availablePresets => isVolleyball
      ? VolleyballScoringPresets.all
      : PickleballScoringPresets.all;

  void _updatePhase(TournamentPhase phase, PhaseScoring scoring) {
    setState(() {
      switch (phase) {
        case TournamentPhase.poolPlay:
          _config = _config.copyWith(poolPlay: scoring);
          break;
        case TournamentPhase.quarterFinals:
          _config = _config.copyWith(quarterFinals: scoring);
          break;
        case TournamentPhase.semiFinals:
          _config = _config.copyWith(semiFinals: scoring);
          break;
        case TournamentPhase.finals:
          _config = _config.copyWith(finals: scoring);
          break;
      }
    });
  }

  void _applyPreset(String presetName) {
    setState(() {
      if (isVolleyball) {
        switch (presetName) {
          case 'quick':
            _config = TournamentScoringConfig(
              sportType: 'volleyball',
              poolPlay: VolleyballScoringPresets.singleSet21,
              quarterFinals: VolleyballScoringPresets.singleSet21,
              semiFinals: VolleyballScoringPresets.singleSet25,
              finals: VolleyballScoringPresets.bestOf3_21_21_15,
            );
            break;
          case 'standard':
            _config = TournamentScoringConfig.volleyballDefault();
            break;
          case 'competitive':
            _config = TournamentScoringConfig(
              sportType: 'volleyball',
              poolPlay: VolleyballScoringPresets.singleSet25,
              quarterFinals: VolleyballScoringPresets.bestOf3_21_21_15,
              semiFinals: VolleyballScoringPresets.bestOf3_21_21_15,
              finals: VolleyballScoringPresets.bestOf3_25_25_15,
            );
            break;
          case 'full':
            _config = TournamentScoringConfig.volleyballBestOfThree();
            break;
        }
      } else {
        switch (presetName) {
          case 'quick':
            _config = TournamentScoringConfig.pickleballCasual();
            break;
          case 'standard':
            _config = TournamentScoringConfig.pickleballDefault();
            break;
          case 'competitive':
            _config = TournamentScoringConfig(
              sportType: 'pickleball',
              poolPlay: PickleballScoringPresets.singleGame11,
              quarterFinals: PickleballScoringPresets.bestOf3_11,
              semiFinals: PickleballScoringPresets.bestOf3_11,
              finals: PickleballScoringPresets.bestOf3_11,
            );
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('${isVolleyball ? "Volleyball" : "Pickleball"} Scoring'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_config),
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sport indicator
          Card(
            color: isVolleyball ? colors.volleyballPrimary.withValues(alpha: 0.15) : colors.pickleballPrimary.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isVolleyball ? Icons.sports_volleyball : Icons.sports_tennis,
                    size: 32,
                    color: isVolleyball ? colors.volleyballPrimary : colors.pickleballPrimary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVolleyball ? 'Volleyball Scoring' : 'Pickleball Scoring',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isVolleyball
                              ? 'Configure points per set (15, 21, or 25) and format for each phase'
                              : 'Configure points per game (7 or 11) and format for each phase',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Presets
          Text(
            'Quick Presets',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('Quick Tournament', 'quick', Icons.flash_on),
              _buildPresetChip('Standard', 'standard', Icons.sports),
              _buildPresetChip('Competitive', 'competitive', Icons.emoji_events),
              if (isVolleyball)
                _buildPresetChip('Full (Best of 3)', 'full', Icons.star),
            ],
          ),
          const SizedBox(height: 24),

          // Phase configurations
          Text(
            'Phase-by-Phase Configuration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize scoring for each tournament phase',
            style: TextStyle(color: colors.textSecondary),
          ),
          const SizedBox(height: 16),

          _buildPhaseCard(
            TournamentPhase.poolPlay,
            _config.poolPlay,
            Icons.grid_view,
            colors.accent,
          ),
          _buildPhaseCard(
            TournamentPhase.quarterFinals,
            _config.quarterFinals,
            Icons.looks_4,
            colors.pickleballPrimary,
          ),
          _buildPhaseCard(
            TournamentPhase.semiFinals,
            _config.semiFinals,
            Icons.looks_two,
            colors.volleyballPrimary,
          ),
          _buildPhaseCard(
            TournamentPhase.finals,
            _config.finals,
            Icons.emoji_events,
            colors.warning,
          ),

          const SizedBox(height: 24),

          // Summary
          Card(
            color: colors.cardBackgroundLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Divider(color: colors.divider),
                  _buildSummaryRow('Pool Play', _config.poolPlay),
                  _buildSummaryRow('Quarter-Finals', _config.quarterFinals),
                  _buildSummaryRow('Semi-Finals', _config.semiFinals),
                  _buildSummaryRow('Finals', _config.finals),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, String preset, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => _applyPreset(preset),
    );
  }

  Widget _buildPhaseCard(
    TournamentPhase phase,
    PhaseScoring currentScoring,
    IconData icon,
    Color color,
  ) {
    final colors = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phase.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        currentScoring.displayName,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showScoringPicker(phase, currentScoring),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String phase, PhaseScoring scoring) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              phase,
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              scoring.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScoringPicker(TournamentPhase phase, PhaseScoring currentScoring) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ScoringPickerSheet(
        phase: phase,
        currentScoring: currentScoring,
        isVolleyball: isVolleyball,
        onSelected: (scoring) {
          _updatePhase(phase, scoring);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Bottom sheet for selecting scoring format
class _ScoringPickerSheet extends StatefulWidget {
  final TournamentPhase phase;
  final PhaseScoring currentScoring;
  final bool isVolleyball;
  final ValueChanged<PhaseScoring> onSelected;

  const _ScoringPickerSheet({
    required this.phase,
    required this.currentScoring,
    required this.isVolleyball,
    required this.onSelected,
  });

  @override
  State<_ScoringPickerSheet> createState() => _ScoringPickerSheetState();
}

class _ScoringPickerSheetState extends State<_ScoringPickerSheet> {
  late int _numberOfSets;
  late int _pointsPerSet;
  int? _tiebreakPoints;

  @override
  void initState() {
    super.initState();
    _numberOfSets = widget.currentScoring.numberOfSets;
    _pointsPerSet = widget.currentScoring.pointsPerSet;
    _tiebreakPoints = widget.currentScoring.tiebreakPoints;
  }

  List<int> get availablePoints =>
      widget.isVolleyball ? [15, 21, 25] : [7, 11];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      color: colors.cardBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configure ${widget.phase.displayName}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Number of sets/games
          Text(
            widget.isVolleyball ? 'Number of Sets' : 'Number of Games',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOptionCard(
                  'Single ${widget.isVolleyball ? "Set" : "Game"}',
                  '1',
                  _numberOfSets == 1,
                  () => setState(() {
                    _numberOfSets = 1;
                    _tiebreakPoints = null;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOptionCard(
                  'Best of 3',
                  '3',
                  _numberOfSets == 3,
                  () => setState(() => _numberOfSets = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Points per set
          Text(
            'Points to Win ${widget.isVolleyball ? "Set" : "Game"}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: availablePoints.map((points) {
              final isSelected = _pointsPerSet == points;
              return ChoiceChip(
                label: Text('$points'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _pointsPerSet = points);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Tiebreak points (only for best of 3 volleyball)
          if (_numberOfSets == 3 && widget.isVolleyball) ...[
            Text(
              'Tiebreak Set (3rd Set) Points',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('Same as regular ($_pointsPerSet)'),
                  selected: _tiebreakPoints == null,
                  onSelected: (selected) {
                    if (selected) setState(() => _tiebreakPoints = null);
                  },
                ),
                ...availablePoints
                    .where((p) => p <= _pointsPerSet)
                    .map((points) {
                  return ChoiceChip(
                    label: Text('$points'),
                    selected: _tiebreakPoints == points,
                    onSelected: (selected) {
                      if (selected) setState(() => _tiebreakPoints = points);
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.accentLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.preview, color: colors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        _buildPreview(),
                        style: TextStyle(color: colors.accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onSelected(PhaseScoring(
                      numberOfSets: _numberOfSets,
                      pointsPerSet: _pointsPerSet,
                      tiebreakPoints: _tiebreakPoints,
                    ));
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    String title,
    String value,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentLight : colors.searchBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.accent : colors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? colors.accent : colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? colors.accent : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildPreview() {
    if (_numberOfSets == 1) {
      return 'Single ${widget.isVolleyball ? "set" : "game"} to $_pointsPerSet points';
    } else {
      if (_tiebreakPoints != null && _tiebreakPoints != _pointsPerSet) {
        return 'Best of 3: First two to $_pointsPerSet, tiebreak to $_tiebreakPoints';
      }
      return 'Best of 3: All ${widget.isVolleyball ? "sets" : "games"} to $_pointsPerSet points';
    }
  }
}
