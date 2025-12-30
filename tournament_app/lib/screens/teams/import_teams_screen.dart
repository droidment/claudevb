import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../models/team.dart';
import '../../services/team_service.dart';

class ImportTeamsScreen extends StatefulWidget {
  const ImportTeamsScreen({super.key});

  @override
  State<ImportTeamsScreen> createState() => _ImportTeamsScreenState();
}

class _ImportTeamsScreenState extends State<ImportTeamsScreen> {
  final _teamService = TeamService();
  List<CsvTeamImport> _allTeams = [];
  List<CsvTeamImport> _filteredTeams = [];
  bool _isLoading = false;
  bool _isImporting = false;
  String? _error;
  String _selectedCategory = "Men's Volleyball";

  final List<String> _categories = [
    "All",
    "Men's Volleyball",
    "Throwball",
    "45+ Volleyball",
    "PRO LEVEL LEAGUE",
  ];

  Future<void> _pickAndParseCsv() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.first;
      String csvContent;

      if (file.bytes != null) {
        csvContent = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        csvContent = await File(file.path!).readAsString();
      } else {
        throw Exception('Could not read file');
      }

      _parseCsvContent(csvContent);
    } catch (e) {
      setState(() {
        _error = 'Error reading file: $e';
        _isLoading = false;
      });
    }
  }

  void _parseCsvContent(String content) {
    try {
      final lines = content.split('\n');
      if (lines.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Skip header row
      final teams = <CsvTeamImport>[];
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Parse CSV line (handling quoted fields)
        final row = _parseCsvLine(line);
        if (row.length < 5) continue; // Skip invalid rows

        // Skip rows marked as "Not playing" or "Not Playing"
        if (row.length > 14) {
          final paidValue = row[14].trim().toLowerCase();
          if (paidValue.contains('not playing')) continue;
        }

        final team = CsvTeamImport.fromCsvRow(row);
        if (team.teamName.isNotEmpty) {
          teams.add(team);
        }
      }

      setState(() {
        _allTeams = teams;
        _filterTeams();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error parsing CSV: $e';
        _isLoading = false;
      });
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());

    return result;
  }

  void _filterTeams() {
    if (_selectedCategory == "All") {
      _filteredTeams = List.from(_allTeams);
    } else if (_selectedCategory == "Men's Volleyball") {
      _filteredTeams = _allTeams.where((t) => t.isMensVolleyball).toList();
    } else if (_selectedCategory == "Throwball") {
      _filteredTeams = _allTeams.where((t) => t.isThrowball).toList();
    } else if (_selectedCategory == "45+ Volleyball") {
      _filteredTeams = _allTeams.where((t) => t.is45PlusVolleyball).toList();
    } else if (_selectedCategory == "PRO LEVEL LEAGUE") {
      _filteredTeams = _allTeams
          .where((t) => t.category?.contains('PRO LEVEL') ?? false)
          .toList();
    } else {
      _filteredTeams = List.from(_allTeams);
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      for (final team in _filteredTeams) {
        team.selected = value ?? false;
      }
    });
  }

  int get _selectedCount => _filteredTeams.where((t) => t.selected).length;
  int get _paidCount => _filteredTeams.where((t) => t.paid).length;

  Future<void> _importSelectedTeams() async {
    final selectedTeams = _filteredTeams.where((t) => t.selected).toList();
    if (selectedTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No teams selected for import'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Import'),
        content: Text(
          'Import ${selectedTeams.length} teams?\n\n'
          'Paid: ${selectedTeams.where((t) => t.paid).length}\n'
          'Unpaid: ${selectedTeams.where((t) => !t.paid).length}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isImporting = true);

    try {
      final imported = await _teamService.importTeams(selectedTeams);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${imported.length} teams!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing teams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Teams from CSV'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_filteredTeams.isNotEmpty)
            TextButton.icon(
              onPressed: _isImporting ? null : _importSelectedTeams,
              icon: _isImporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload),
              label: Text('Import ($_selectedCount)'),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _allTeams.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _pickAndParseCsv,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.file_upload),
              label: Text(_isLoading ? 'Loading...' : 'Select CSV File'),
            )
          : null,
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
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickAndParseCsv,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_allTeams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Import Teams from CSV',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a CSV file to import teams',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildExpectedFormatCard(),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Category filter and stats
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                          _filterTeams();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _pickAndParseCsv,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reload'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip(
                    'Total',
                    _filteredTeams.length.toString(),
                    Colors.blue,
                  ),
                  _buildStatChip(
                    'Selected',
                    _selectedCount.toString(),
                    Colors.green,
                  ),
                  _buildStatChip('Paid', _paidCount.toString(), Colors.orange),
                ],
              ),
            ],
          ),
        ),

        // Select all checkbox
        CheckboxListTile(
          title: const Text('Select All'),
          value:
              _filteredTeams.isNotEmpty &&
              _filteredTeams.every((t) => t.selected),
          tristate: true,
          onChanged: _toggleSelectAll,
        ),
        const Divider(height: 1),

        // Teams list
        Expanded(
          child: ListView.builder(
            itemCount: _filteredTeams.length,
            itemBuilder: (context, index) {
              final team = _filteredTeams[index];
              return _buildTeamTile(team);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildTeamTile(CsvTeamImport team) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: CheckboxListTile(
        value: team.selected,
        onChanged: (value) {
          setState(() => team.selected = value ?? false);
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                team.teamName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (team.paid)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PAID',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Captain: ${team.captainName}'),
            if (team.captainPhone != null)
              Text(
                'Phone: ${team.captainPhone}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            if (team.captainEmail != null)
              Text(
                'Email: ${team.captainEmail}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            if (team.specialRequests != null &&
                team.specialRequests!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.yellow.shade200),
                ),
                child: Text(
                  'Note: ${team.specialRequests}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        secondary: CircleAvatar(
          backgroundColor: team.paid ? Colors.green : Colors.grey.shade300,
          child: Text(
            team.teamName.isNotEmpty ? team.teamName[0].toUpperCase() : '?',
            style: TextStyle(
              color: team.paid ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpectedFormatCard() {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expected CSV Format:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Columns: Timestamp, Email, Score, Category, Team Name, '
              'Captain Name, Phone, Contact 2, Player Count, Special Requests, '
              'Rules Acknowledged, Signed By, Date, Column 13, Paid',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Paid column: "Y", "Yes", or "Paid" for paid teams',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
