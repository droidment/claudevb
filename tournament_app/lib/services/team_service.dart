import '../core/supabase_client.dart';
import '../models/team.dart';
import '../models/player.dart';

class TeamService {
  /// Create a new team
  Future<Team> createTeam({
    required String name,
    String? homeCity,
    String? teamColor,
    String sportType = 'volleyball',
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to create a team');
    }

    final data = {
      'name': name,
      'captain_id': user.id,
      'home_city': homeCity,
      'team_color': teamColor,
      'sport_type': sportType,
    };

    final response = await supabase
        .from('teams')
        .insert(data)
        .select()
        .single();

    return Team.fromJson(response);
  }

  /// Get all teams for the current user (captain)
  Future<List<Team>> getMyTeams() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    final response = await supabase
        .from('teams')
        .select()
        .eq('captain_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Team.fromJson(json)).toList();
  }

  /// Get a single team by ID
  Future<Team> getTeam(String id) async {
    final response = await supabase
        .from('teams')
        .select()
        .eq('id', id)
        .single();

    return Team.fromJson(response);
  }

  /// Update a team
  Future<Team> updateTeam(String id, Map<String, dynamic> updates) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    final response = await supabase
        .from('teams')
        .update(updates)
        .eq('id', id)
        .eq('captain_id', user.id)
        .select()
        .single();

    return Team.fromJson(response);
  }

  /// Delete a team
  Future<void> deleteTeam(String id) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    await supabase
        .from('teams')
        .delete()
        .eq('id', id)
        .eq('captain_id', user.id);
  }

  /// Get all players for a team
  Future<List<Player>> getTeamPlayers(String teamId) async {
    final response = await supabase
        .from('players')
        .select()
        .eq('team_id', teamId)
        .order('jersey_number', ascending: true);

    return (response as List).map((json) => Player.fromJson(json)).toList();
  }

  /// Add a player to a team
  Future<Player> addPlayer({
    required String teamId,
    required String name,
    String? email,
    String? phone,
    int? jerseyNumber,
    String? position,
    int? heightInches,
  }) async {
    final data = {
      'team_id': teamId,
      'name': name,
      'email': email,
      'phone': phone,
      'jersey_number': jerseyNumber,
      'position': position,
      'height_inches': heightInches,
      'is_active': true,
    };

    final response = await supabase
        .from('players')
        .insert(data)
        .select()
        .single();

    return Player.fromJson(response);
  }

  /// Update a player
  Future<Player> updatePlayer(String id, Map<String, dynamic> updates) async {
    final response = await supabase
        .from('players')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Player.fromJson(response);
  }

  /// Delete a player
  Future<void> deletePlayer(String id) async {
    await supabase.from('players').delete().eq('id', id);
  }

  /// Get team with player count
  Future<Map<String, dynamic>> getTeamWithPlayerCount(String teamId) async {
    final team = await getTeam(teamId);
    final players = await getTeamPlayers(teamId);

    return {'team': team, 'playerCount': players.length};
  }

  /// Get all teams (for organizers)
  Future<List<Team>> getAllTeams() async {
    final response = await supabase
        .from('teams')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => Team.fromJson(json)).toList();
  }

  /// Import a team from CSV data (for organizers)
  Future<Team> importTeam({
    required String name,
    required String captainName,
    String? captainEmail,
    String? captainPhone,
    String? contactPerson2,
    String? contactPhone2,
    int? playerCount,
    String? specialRequests,
    String? signedBy,
    DateTime? registrationDate,
    String? category,
    String? homeCity,
    String? teamColor,
    bool registrationPaid = false,
    double? paymentAmount,
    int lunchCount = 0,
    String? notes,
    String sportType = 'volleyball',
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to import a team');
    }

    final data = {
      'name': name,
      'captain_id': user.id, // Organizer becomes the owner
      'home_city': homeCity,
      'team_color': teamColor,
      'sport_type': sportType,
      'registration_paid': registrationPaid,
      'payment_amount': paymentAmount,
      'payment_date': registrationPaid
          ? DateTime.now().toIso8601String()
          : null,
      'lunch_count': lunchCount,
      'captain_name': captainName,
      'captain_email': captainEmail,
      'captain_phone': captainPhone,
      'contact_person_2': contactPerson2,
      'contact_phone_2': contactPhone2,
      'player_count': playerCount,
      'special_requests': specialRequests,
      'signed_by': signedBy,
      'registration_date': registrationDate?.toIso8601String(),
      'category': category,
      'notes': notes,
    };

    final response = await supabase
        .from('teams')
        .insert(data)
        .select()
        .single();

    return Team.fromJson(response);
  }

  /// Import multiple teams from CSV data
  Future<List<Team>> importTeams(List<CsvTeamImport> teams) async {
    final importedTeams = <Team>[];

    for (final csvTeam in teams) {
      if (!csvTeam.selected) continue;

      try {
        final team = await importTeam(
          name: csvTeam.teamName,
          captainName: csvTeam.captainName,
          captainEmail: csvTeam.captainEmail,
          captainPhone: csvTeam.captainPhone,
          contactPerson2: csvTeam.contactPerson2,
          playerCount: csvTeam.playerCount,
          specialRequests: csvTeam.specialRequests,
          registrationDate: csvTeam.registrationDate,
          category: csvTeam.category,
          registrationPaid: csvTeam.paid,
          paymentAmount: csvTeam.paid
              ? 200.0
              : null, // Default registration fee
          lunchCount: csvTeam.lunchCount,
        );
        importedTeams.add(team);
      } catch (e) {
        // Log error but continue with other teams
        print('Error importing team ${csvTeam.teamName}: $e');
      }
    }

    return importedTeams;
  }

  /// Update team payment status
  Future<Team> updatePaymentStatus(
    String teamId, {
    required bool paid,
    double? amount,
  }) async {
    final updates = {
      'registration_paid': paid,
      'payment_amount': amount,
      'payment_date': paid ? DateTime.now().toIso8601String() : null,
    };

    final response = await supabase
        .from('teams')
        .update(updates)
        .eq('id', teamId)
        .select()
        .single();

    return Team.fromJson(response);
  }

  /// Update team lunch count
  Future<Team> updateLunchCount(String teamId, int count) async {
    final response = await supabase
        .from('teams')
        .update({'lunch_count': count})
        .eq('id', teamId)
        .select()
        .single();

    return Team.fromJson(response);
  }
}
