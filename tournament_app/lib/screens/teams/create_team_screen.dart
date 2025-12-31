import 'package:flutter/material.dart';
import '../../services/team_service.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamService = TeamService();
  final _nameController = TextEditingController();
  final _homeCityController = TextEditingController();

  bool _isLoading = false;
  Color _selectedColor = Colors.blue;
  String _selectedSportType = 'volleyball';

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _homeCityController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _teamService.createTeam(
        name: _nameController.text.trim(),
        homeCity: _homeCityController.text.trim().isEmpty
            ? null
            : _homeCityController.text.trim(),
        teamColor: _colorToHex(_selectedColor),
        sportType: _selectedSportType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating team: $e'),
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
        title: const Text('Create Team'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Team Preview
            Card(
              color: _selectedColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _selectedColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: _selectedColor, width: 4),
                      ),
                      child: Center(
                        child: Text(
                          _nameController.text.isEmpty
                              ? '?'
                              : _nameController.text.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _selectedColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.isEmpty
                          ? 'Team Name'
                          : _nameController.text,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_homeCityController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _homeCityController.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Team Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name *',
                hintText: 'e.g., Thunder Spikers',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.groups),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a team name';
                }
                if (value.trim().length < 3) {
                  return 'Team name must be at least 3 characters';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Home City
            TextFormField(
              controller: _homeCityController,
              decoration: const InputDecoration(
                labelText: 'Home City (optional)',
                hintText: 'e.g., San Francisco',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Sport Type
            DropdownButtonFormField<String>(
              initialValue: _selectedSportType,
              decoration: const InputDecoration(
                labelText: 'Sport Type *',
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
                if (value != null) {
                  setState(() => _selectedSportType = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Team Color
            Text(
              'Team Color',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableColors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Create Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _createTeam,
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
              label: Text(_isLoading ? 'Creating...' : 'Create Team'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
