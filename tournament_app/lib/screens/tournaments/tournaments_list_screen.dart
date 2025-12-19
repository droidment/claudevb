import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/tournament.dart';
import '../../services/tournament_service.dart';
import 'tournament_detail_screen.dart';
import 'join_by_invite_screen.dart';

class TournamentsListScreen extends StatefulWidget {
  const TournamentsListScreen({super.key});

  @override
  State<TournamentsListScreen> createState() => _TournamentsListScreenState();
}

class _TournamentsListScreenState extends State<TournamentsListScreen> {
  final _tournamentService = TournamentService();
  List<Tournament> _tournaments = [];
  bool _isLoading = true;
  String? _error;
  String _selectedSport = 'all';
  TournamentStatus? _selectedStatus;
  double? _userLatitude;
  double? _userLongitude;
  bool _showNearbyOnly = false;
  double _maxDistance = 50.0; // km

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
      final tournaments = await _tournamentService.getAllTournaments(
        sportType: _selectedSport == 'all' ? null : _selectedSport,
        status: _selectedStatus,
      );
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

  void _navigateToTournamentDetail(String tournamentId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TournamentDetailScreen(
          tournamentId: tournamentId,
          isOrganizer: false,
        ),
      ),
    );
  }

  Future<void> _getUserLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location enabled! You can now filter by distance.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Tournament> _filterTournaments() {
    if (!_showNearbyOnly || _userLatitude == null || _userLongitude == null) {
      return _tournaments;
    }

    return _tournaments.where((tournament) {
      final distance = tournament.distanceFrom(_userLatitude, _userLongitude);
      return distance != null && distance <= _maxDistance;
    }).toList();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Tournaments',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sport Type',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('All', 'all'),
                  _buildFilterChip('Volleyball', 'volleyball'),
                  _buildFilterChip('Pickleball', 'pickleball'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Status',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildStatusFilterChip('All', null),
                  _buildStatusFilterChip(
                    'Open',
                    TournamentStatus.registrationOpen,
                  ),
                  _buildStatusFilterChip(
                    'Ongoing',
                    TournamentStatus.ongoing,
                  ),
                  _buildStatusFilterChip(
                    'Completed',
                    TournamentStatus.completed,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Distance',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Show nearby tournaments only'),
                subtitle: Text(
                  _userLatitude != null
                      ? 'Within ${_maxDistance.round()} km'
                      : 'Enable location to use this filter',
                ),
                value: _showNearbyOnly,
                onChanged: _userLatitude != null
                    ? (value) {
                        setState(() => _showNearbyOnly = value);
                      }
                    : null,
              ),
              if (_showNearbyOnly) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Max distance: ${_maxDistance.round()} km',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Slider(
                        value: _maxDistance,
                        min: 5,
                        max: 200,
                        divisions: 39,
                        label: '${_maxDistance.round()} km',
                        onChanged: (value) {
                          setState(() => _maxDistance = value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              if (_userLatitude == null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _getUserLocation();
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Enable Location'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {}); // Trigger rebuild with filters
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedSport == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSport = value;
        });
      },
    );
  }

  Widget _buildStatusFilterChip(String label, TournamentStatus? value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
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

  IconData _getSportIcon(String sportType) {
    return sportType == 'volleyball'
        ? Icons.sports_volleyball
        : Icons.sports_tennis;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Tournaments'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const JoinByInviteScreen(),
                ),
              );
            },
            tooltip: 'Join by Invite Code',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _buildBody(),
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
            ElevatedButton(
              onPressed: _loadTournaments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredTournaments = _filterTournaments();

    if (filteredTournaments.isEmpty && _tournaments.isNotEmpty && _showNearbyOnly) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Nearby Tournaments',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try increasing the distance filter',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showNearbyOnly = false;
                });
              },
              child: const Text('Show All Tournaments'),
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Tournaments Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for upcoming tournaments',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            if (_selectedSport != 'all' || _selectedStatus != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedSport = 'all';
                    _selectedStatus = null;
                  });
                  _loadTournaments();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTournaments,
      child: Column(
        children: [
          // Active filters display
          if (_selectedSport != 'all' || _selectedStatus != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Text('Filters: '),
                  if (_selectedSport != 'all')
                    Chip(
                      label: Text(_selectedSport.toUpperCase()),
                      onDeleted: () {
                        setState(() => _selectedSport = 'all');
                        _loadTournaments();
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                  if (_selectedStatus != null)
                    Chip(
                      label: Text(_selectedStatus!.displayName),
                      onDeleted: () {
                        setState(() => _selectedStatus = null);
                        _loadTournaments();
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTournaments.length,
              itemBuilder: (context, index) {
                final tournament = filteredTournaments[index];
                final distance = tournament.distanceFrom(_userLatitude, _userLongitude);
                return _buildTournamentCard(tournament, distance);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(Tournament tournament, double? distance) {
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
                    color: Theme.of(context).colorScheme.primary,
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
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      tournament.status.displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                  if (distance != null) ...[
                    Icon(Icons.near_me, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${distance.toStringAsFixed(1)} km away',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (tournament.location != null) ...[
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
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
                      color: Colors.grey[600],
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
                      Icon(Icons.groups, size: 16, color: Colors.grey[600]),
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
                        color: Colors.grey[600],
                      ),
                      Text(
                        '\$${tournament.entryFee!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
              // Registration button for open tournaments
              if (tournament.status == TournamentStatus.registrationOpen) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Team registration coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.how_to_reg),
                    label: const Text('Register Team'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
