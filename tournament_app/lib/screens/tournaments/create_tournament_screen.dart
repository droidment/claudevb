import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/tournament.dart';
import '../../services/tournament_service.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tournamentService = TournamentService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _venueDetailsController = TextEditingController();
  final _maxTeamsController = TextEditingController();
  final _minTeamSizeController = TextEditingController(text: '6');
  final _maxTeamSizeController = TextEditingController(text: '12');
  final _entryFeeController = TextEditingController();

  String _sportType = 'volleyball';
  TournamentFormat _format = TournamentFormat.roundRobin;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _registrationDeadline;
  bool _isLoading = false;
  bool _isPublic = true;
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

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
    final initialDate = DateTime.now().add(const Duration(days: 7));
    final firstDate = DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
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
    setState(() => _isGettingLocation = true);

    try {
      // Check location permission
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

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location set successfully!'),
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
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _geocodeAddress() async {
    final address = _locationController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a location first'),
          backgroundColor: Colors.orange,
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
            const SnackBar(
              content: Text('Location coordinates set from address!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find coordinates for this address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _tournamentService.createTournament(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        sportType: _sportType,
        format: _format,
        startDate: _startDate,
        endDate: _endDate,
        registrationDeadline: _registrationDeadline,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        venueDetails: _venueDetailsController.text.trim().isEmpty
            ? null
            : _venueDetailsController.text.trim(),
        maxTeams: _maxTeamsController.text.isEmpty
            ? null
            : int.tryParse(_maxTeamsController.text),
        minTeamSize: int.tryParse(_minTeamSizeController.text) ?? 6,
        maxTeamSize: int.tryParse(_maxTeamSizeController.text) ?? 12,
        entryFee: _entryFeeController.text.isEmpty
            ? null
            : double.tryParse(_entryFeeController.text),
        isPublic: _isPublic,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating tournament: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                    const Icon(Icons.info_outline, color: Colors.blue),
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
                  color: _isPublic ? Colors.green : Colors.orange,
                ),
              ),
            ),
            if (!_isPublic) ...[
              const SizedBox(height: 8),
              Card(
                color: Colors.orange.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'An invite code will be automatically generated after creation. You can share it with teams to join.',
                          style: TextStyle(fontSize: 12),
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
                    const Row(
                      children: [
                        Icon(Icons.my_location, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Set coordinates to enable nearby tournament search',
                            style: TextStyle(fontSize: 13),
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
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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

            // Create Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _createTournament,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(_isLoading ? 'Creating...' : 'Create Tournament'),
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
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
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
