import '../core/supabase_client.dart';
import '../models/team.dart';
import '../models/player.dart';

class TeamService {
  /// Create a new team
  Future<Team> createTeam({
    required String name,
    String? homeCity,
    String? teamColor,
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
  Future<Team> updateTeam(
    String id,
    Map<String, dynamic> updates,
  ) async {
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
  Future<Player> updatePlayer(
    String id,
    Map<String, dynamic> updates,
  ) async {
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
    await supabase
        .from('players')
        .delete()
        .eq('id', id);
  }

  /// Get team with player count
  Future<Map<String, dynamic>> getTeamWithPlayerCount(String teamId) async {
    final team = await getTeam(teamId);
    final players = await getTeamPlayers(teamId);

    return {
      'team': team,
      'playerCount': players.length,
    };
  }
}
