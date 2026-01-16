import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/tournament.dart';
import '../../services/tournament_service.dart';
import '../../theme/theme.dart';

class EditTournamentScreen extends StatefulWidget {
  final Tournament tournament;

  const EditTournamentScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<EditTournamentScreen> createState() => _EditTournamentScreenState();
}

class _EditTournamentScreenState extends State<EditTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tournamentService = TournamentService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _venueDetailsController;
  late TextEditingController _maxTeamsController;
  late TextEditingController _minTeamSizeController;
  late TextEditingController _maxTeamSizeController;
  late TextEditingController _entryFeeController;

  late String _sportType;
  late TournamentFormat _format;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _registrationDeadline;
  bool _isLoading = false;
  late bool _isPublic;
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeFormWithTournamentData();
  }

  void _initializeFormWithTournamentData() {
    final tournament = widget.tournament;

    _nameController = TextEditingController(text: tournament.name);
    _descriptionController = TextEditingController(text: tournament.description ?? '');
    _locationController = TextEditingController(text: tournament.location ?? '');
    _venueDetailsController = TextEditingController(text: tournament.venueDetails ?? '');
    _maxTeamsController = TextEditingController(
      text: tournament.maxTeams?.toString() ?? '',
    );
    _minTeamSizeController = TextEditingController(
      text: tournament.minTeamSize.toString(),
    );
    _maxTeamSizeController = TextEditingController(
      text: tournament.maxTeamSize.toString(),
    );
    _entryFeeController = TextEditingController(
      text: tournament.entryFee?.toString() ?? '',
    );

    _sportType = tournament.sportType;
    _format = tournament.format;
    _startDate = tournament.startDate;
    _endDate = tournament.endDate;
    _registrationDeadline = tournament.registrationDeadline;
    _isPublic = tournament.isPublic;
    _latitude = tournament.latitude;
    _longitude = tournament.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _venueDetailsController.dispose();
    _maxTeamsController.dispose();
    _minTeamSizeController.dispose();
    _maxTeamSizeController.dispose();
    _entryFeeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime? currentValue;
    switch (type) {
      case 'start':
        currentValue = _startDate;
        break;
      case 'end':
        currentValue = _endDate;
        break;
      case 'registration':
        currentValue = _registrationDeadline;
        break;
    }

    final initialDate = currentValue ?? DateTime.now().add(const Duration(days: 7));
    final firstDate = DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      final initialTime = currentValue != null
          ? TimeOfDay(hour: currentValue.hour, minute: currentValue.minute)
          : const TimeOfDay(hour: 9, minute: 0);

      final time = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      setState(() {
        final dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time?.hour ?? 9,
          time?.minute ?? 0,
        );

        switch (type) {
          case 'start':
            _startDate = dateTime;
            break;
          case 'end':
            _endDate = dateTime;
            break;
          case 'registration':
            _registrationDeadline = dateTime;
            break;
        }
      });
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not set';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _getCurrentLocation() async {
    final colors = context.colors;
    setState(() => _isGettingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location set successfully!'),
            backgroundColor: colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _geocodeAddress() async {
    final colors = context.colors;
    final address = _locationController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a location first'),
          backgroundColor: colors.warning,
        ),
      );
      return;
    }

    setState(() => _isGettingLocation = true);

    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _latitude = locations.first.latitude;
          _longitude = locations.first.longitude;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location coordinates set from address!'),
              backgroundColor: colors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not find coordinates for this address'),
            backgroundColor: colors.error,
          ),
        );
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _updateTournament() async {
    if (!_formKey.currentState!.validate()) return;

    final colors = context.colors;
    setState(() => _isLoading = true);

    try {
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'sport_type': _sportType,
        'format': _format.dbValue,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'registration_deadline': _registrationDeadline?.toIso8601String(),
        'location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'venue_details': _venueDetailsController.text.trim().isEmpty
            ? null
            : _venueDetailsController.text.trim(),
        'max_teams': _maxTeamsController.text.isEmpty
            ? null
            : int.tryParse(_maxTeamsController.text),
        'min_team_size': int.tryParse(_minTeamSizeController.text) ?? 6,
        'max_team_size': int.tryParse(_maxTeamSizeController.text) ?? 12,
        'entry_fee': _entryFeeController.text.isEmpty
            ? null
            : double.tryParse(_entryFeeController.text),
        'is_public': _isPublic,
        'latitude': _latitude,
        'longitude': _longitude,
      };

      await _tournamentService.updateTournament(widget.tournament.id, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tournament updated successfully!'),
            backgroundColor: colors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating tournament: $e'),
            backgroundColor: colors.error,
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
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Edit Tournament'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Section
            _buildSectionHeader('Basic Information'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tournament Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.emoji_events),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a tournament name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Sport & Format Section
            _buildSectionHeader('Sport & Format'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _sportType,
              decoration: const InputDecoration(
                labelText: 'Sport Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'volleyball',
                  child: Text('Volleyball'),
                ),
                DropdownMenuItem(
                  value: 'pickleball',
                  child: Text('Pickleball'),
                ),
              ],
              onChanged: (value) {
                setState(() => _sportType = value!);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TournamentFormat>(
              initialValue: _format,
              decoration: const InputDecoration(
                labelText: 'Tournament Format',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
              items: TournamentFormat.values.map((format) {
                return DropdownMenuItem(
                  value: format,
                  child: Text(format.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _format = value!);
              },
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _format.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dates Section
            _buildSectionHeader('Dates'),
            const SizedBox(height: 8),
            _buildDateTile(
              title: 'Registration Deadline',
              value: _registrationDeadline,
              onTap: () => _selectDate(context, 'registration'),
              icon: Icons.how_to_reg,
            ),
            _buildDateTile(
              title: 'Start Date',
              value: _startDate,
              onTap: () => _selectDate(context, 'start'),
              icon: Icons.play_circle,
            ),
            _buildDateTile(
              title: 'End Date',
              value: _endDate,
              onTap: () => _selectDate(context, 'end'),
              icon: Icons.stop_circle,
            ),
            const SizedBox(height: 24),

            // Location Section
            _buildSectionHeader('Location'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                hintText: 'e.g., City Sports Complex',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _venueDetailsController,
              decoration: const InputDecoration(
                labelText: 'Venue Details',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
                hintText: 'e.g., Court 1-4, parking available',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Team Settings Section
            _buildSectionHeader('Team Settings'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _maxTeamsController,
              decoration: const InputDecoration(
                labelText: 'Max Teams (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.groups),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minTeamSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Min Team Size',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final num = int.tryParse(value);
                      if (num == null || num < 1) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxTeamSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Max Team Size',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final num = int.tryParse(value);
                      if (num == null || num < 1) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Privacy Section
            _buildSectionHeader('Privacy Settings'),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('Public Tournament'),
                subtitle: Text(
                  _isPublic
                      ? 'Anyone can find and join this tournament'
                      : 'Private - accessible only via invite link',
                ),
                value: _isPublic,
                onChanged: (value) {
                  setState(() => _isPublic = value);
                },
                secondary: Icon(
                  _isPublic ? Icons.public : Icons.lock,
                  color: _isPublic ? colors.success : colors.warning,
                ),
              ),
            ),
            if (!_isPublic && widget.tournament.inviteCode != null) ...[
              const SizedBox(height: 8),
              Card(
                color: colors.warningLight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.vpn_key, color: colors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Invite Code:',
                              style: TextStyle(fontSize: 12, color: colors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.tournament.inviteCode!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Location Geo-Coordinates Section
            _buildSectionHeader('Location Coordinates (Optional)'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.my_location, color: colors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Set coordinates to enable nearby tournament search',
                            style: TextStyle(fontSize: 13, color: colors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGettingLocation ? null : _getCurrentLocation,
                            icon: _isGettingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.gps_fixed),
                            label: const Text('Use Current Location'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGettingLocation ? null : _geocodeAddress,
                            icon: const Icon(Icons.search),
                            label: const Text('From Address'),
                          ),
                        ),
                      ],
                    ),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: colors.success, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textPrimary),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  _latitude = null;
                                  _longitude = null;
                                });
                              },
                              tooltip: 'Clear coordinates',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Entry Fee Section
            _buildSectionHeader('Entry Fee'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _entryFeeController,
              decoration: const InputDecoration(
                labelText: 'Entry Fee (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _updateTournament,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final colors = context.colors;
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: colors.accent,
      ),
    );
  }

  Widget _buildDateTile({
    required String title,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(_formatDateTime(value)),
        trailing: const Icon(Icons.calendar_today),
        onTap: onTap,
      ),
    );
  }
}
