import '../core/supabase_client.dart';
import '../models/tournament.dart';

class TournamentService {
  /// Create a new tournament
  Future<Tournament> createTournament({
    required String name,
    String? description,
    String sportType = 'volleyball',
    required TournamentFormat format,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    String? location,
    String? venueDetails,
    int? maxTeams,
    int minTeamSize = 6,
    int maxTeamSize = 12,
    double? entryFee,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to create a tournament');
    }

    final data = {
      'name': name,
      'description': description,
      'sport_type': sportType,
      'format': format.dbValue,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'location': location,
      'venue_details': venueDetails,
      'max_teams': maxTeams,
      'min_team_size': minTeamSize,
      'max_team_size': maxTeamSize,
      'entry_fee': entryFee,
      'status': TournamentStatus.registrationOpen.dbValue,
      'organizer_id': user.id,
    };

    final response = await supabase
        .from('tournaments')
        .insert(data)
        .select()
        .single();

    return Tournament.fromJson(response);
  }

  /// Get all tournaments organized by the current user
  Future<List<Tournament>> getMyTournaments() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    final response = await supabase
        .from('tournaments')
        .select()
        .eq('organizer_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Tournament.fromJson(json)).toList();
  }

  /// Get all tournaments (for browsing)
  Future<List<Tournament>> getAllTournaments({
    TournamentStatus? status,
    String? sportType,
  }) async {
    var query = supabase.from('tournaments').select();

    if (status != null) {
      query = query.eq('status', status.dbValue);
    }
    if (sportType != null) {
      query = query.eq('sport_type', sportType);
    }

    final response = await query.order('start_date', ascending: true);

    return (response as List).map((json) => Tournament.fromJson(json)).toList();
  }

  /// Get a single tournament by ID
  Future<Tournament> getTournament(String id) async {
    final response = await supabase
        .from('tournaments')
        .select()
        .eq('id', id)
        .single();

    return Tournament.fromJson(response);
  }

  /// Update a tournament
  Future<Tournament> updateTournament(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    final response = await supabase
        .from('tournaments')
        .update(updates)
        .eq('id', id)
        .eq('organizer_id', user.id)
        .select()
        .single();

    return Tournament.fromJson(response);
  }

  /// Update tournament status
  Future<Tournament> updateTournamentStatus(
    String id,
    TournamentStatus status,
  ) async {
    return updateTournament(id, {'status': status.dbValue});
  }

  /// Delete a tournament
  Future<void> deleteTournament(String id) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    await supabase
        .from('tournaments')
        .delete()
        .eq('id', id)
        .eq('organizer_id', user.id);
  }
}
