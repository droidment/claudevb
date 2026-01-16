import '../core/supabase_client.dart';
import '../models/tournament.dart';
import '../models/tournament_registration.dart';
import '../models/team.dart';

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
    bool isPublic = true,
    double? latitude,
    double? longitude,
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
      'is_public': isPublic,
      'latitude': latitude,
      'longitude': longitude,
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

  /// Get all public tournaments (for browsing)
  Future<List<Tournament>> getAllTournaments({
    TournamentStatus? status,
    String? sportType,
    bool publicOnly = true,
  }) async {
    var query = supabase.from('tournaments').select();

    // Only show public tournaments by default
    if (publicOnly) {
      query = query.eq('is_public', true);
    }

    if (status != null) {
      query = query.eq('status', status.dbValue);
    }
    if (sportType != null) {
      query = query.eq('sport_type', sportType);
    }

    final response = await query.order('start_date', ascending: true);

    return (response as List).map((json) => Tournament.fromJson(json)).toList();
  }

  /// Get tournament by invite code (for private tournaments)
  Future<Tournament?> getTournamentByInviteCode(String inviteCode) async {
    try {
      final response = await supabase
          .from('tournaments')
          .select()
          .eq('invite_code', inviteCode)
          .single();

      return Tournament.fromJson(response);
    } catch (e) {
      return null;
    }
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

  // ========================================
  // Team Registration Methods
  // ========================================

  /// Register a team to a tournament
  Future<TournamentRegistration> registerTeam({
    required String tournamentId,
    required String teamId,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    double? paymentAmount,
    String? poolAssignment,
    int? seedNumber,
    String? notes,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    final data = {
      'tournament_id': tournamentId,
      'team_id': teamId,
      'payment_status': paymentStatus.dbValue,
      'payment_amount': paymentAmount,
      'status': 'approved', // Auto-approve when organizer adds team
      'pool_assignment': poolAssignment,
      'seed_number': seedNumber,
      'notes': notes,
    };

    final response = await supabase
        .from('tournament_registrations')
        .insert(data)
        .select()
        .single();

    return TournamentRegistration.fromJson(response);
  }

  /// Register multiple teams to a tournament
  Future<List<TournamentRegistration>> registerTeams({
    required String tournamentId,
    required List<String> teamIds,
  }) async {
    final registrations = <TournamentRegistration>[];

    for (final teamId in teamIds) {
      try {
        final registration = await registerTeam(
          tournamentId: tournamentId,
          teamId: teamId,
        );
        registrations.add(registration);
      } catch (e) {
        // Log but continue with other teams
        print('Error registering team $teamId: $e');
      }
    }

    return registrations;
  }

  /// Get all registered teams for a tournament (with team details)
  Future<List<Map<String, dynamic>>> getTournamentTeams(
    String tournamentId,
  ) async {
    final response = await supabase
        .from('tournament_registrations')
        .select('''
          *,
          teams:team_id (
            id,
            name,
            home_city,
            team_color,
            captain_email,
            captain_phone,
            registration_paid,
            lunch_count
          )
        ''')
        .eq('tournament_id', tournamentId)
        .order('seed_number', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Get teams available to add (not yet registered)
  /// Optionally filter by sport type to match the tournament's sport
  Future<List<Team>> getAvailableTeams(
    String tournamentId, {
    String? sportType,
  }) async {
    // Get all teams owned by current user
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    // Get all teams, optionally filtered by sport type
    var teamsQuery = supabase.from('teams').select().eq('captain_id', user.id);
    if (sportType != null) {
      teamsQuery = teamsQuery.eq('sport_type', sportType);
    }
    final teamsResponse = await teamsQuery;

    // Get already registered team IDs
    final registeredResponse = await supabase
        .from('tournament_registrations')
        .select('team_id')
        .eq('tournament_id', tournamentId);

    final registeredIds = (registeredResponse as List)
        .map((r) => r['team_id'] as String)
        .toSet();

    // Filter out already registered teams
    final availableTeams = (teamsResponse as List)
        .map((json) => Team.fromJson(json))
        .where((team) => !registeredIds.contains(team.id))
        .toList();

    return availableTeams;
  }

  /// Remove a team from a tournament
  /// Returns true if removal was successful
  /// Throws exception with details if removal fails
  Future<bool> removeTeamFromTournament({
    required String tournamentId,
    required String teamId,
    bool forceRemove = false,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    // First, check if the registration exists
    final existingReg = await supabase
        .from('tournament_registrations')
        .select('id')
        .eq('tournament_id', tournamentId)
        .eq('team_id', teamId)
        .maybeSingle();

    if (existingReg == null) {
      throw Exception('Team is not registered in this tournament');
    }

    // Check if there are matches involving this team
    if (!forceRemove) {
      final matchCount = await supabase
          .from('matches')
          .select('id')
          .eq('tournament_id', tournamentId)
          .or('team1_id.eq.$teamId,team2_id.eq.$teamId');

      if ((matchCount as List).isNotEmpty) {
        throw Exception(
          'MATCHES_EXIST:${matchCount.length} matches involve this team. '
          'Remove matches first or use force remove.',
        );
      }
    }

    // Perform the delete and verify it worked
    final deletedRows = await supabase
        .from('tournament_registrations')
        .delete()
        .eq('tournament_id', tournamentId)
        .eq('team_id', teamId)
        .select('id');

    if ((deletedRows as List).isEmpty) {
      // Check if user has permission
      final tournament = await supabase
          .from('tournaments')
          .select('organizer_id')
          .eq('id', tournamentId)
          .single();

      final isOrganizer = tournament['organizer_id'] == user.id;

      final team = await supabase
          .from('teams')
          .select('captain_id')
          .eq('id', teamId)
          .single();

      final isCaptain = team['captain_id'] == user.id;

      if (!isOrganizer && !isCaptain) {
        throw Exception(
          'Permission denied. Only the tournament organizer or team captain can remove this team.',
        );
      }

      throw Exception(
        'Failed to remove team. Please check your permissions or try again.',
      );
    }

    return true;
  }

  /// Check if a team has matches in a tournament
  Future<int> getTeamMatchCount({
    required String tournamentId,
    required String teamId,
  }) async {
    final matches = await supabase
        .from('matches')
        .select('id')
        .eq('tournament_id', tournamentId)
        .or('team1_id.eq.$teamId,team2_id.eq.$teamId');

    return (matches as List).length;
  }

  /// Update a team's registration (pool assignment, seed, lunch, etc.)
  Future<TournamentRegistration> updateRegistration({
    required String tournamentId,
    required String teamId,
    String? poolAssignment,
    bool updatePoolAssignment = false,
    int? seedNumber,
    bool updateSeedNumber = false,
    PaymentStatus? paymentStatus,
    double? paymentAmount,
    RegistrationStatus? status,
    String? notes,
    int? lunchNonvegCount,
    int? lunchVegCount,
    int? lunchNoNeedCount,
    LunchPaymentStatus? lunchPaymentStatus,
  }) async {
    final updates = <String, dynamic>{};

    // Use explicit flags to allow setting null values
    if (updatePoolAssignment || poolAssignment != null) {
      updates['pool_assignment'] = poolAssignment;
    }
    if (updateSeedNumber || seedNumber != null) {
      updates['seed_number'] = seedNumber;
    }
    if (paymentStatus != null) {
      updates['payment_status'] = paymentStatus.dbValue;
    }
    if (paymentAmount != null) updates['payment_amount'] = paymentAmount;
    if (status != null) updates['status'] = status.dbValue;
    if (notes != null) updates['notes'] = notes;
    if (lunchNonvegCount != null) {
      updates['lunch_nonveg_count'] = lunchNonvegCount;
    }
    if (lunchVegCount != null) updates['lunch_veg_count'] = lunchVegCount;
    if (lunchNoNeedCount != null) {
      updates['lunch_no_need_count'] = lunchNoNeedCount;
    }
    if (lunchPaymentStatus != null) {
      updates['lunch_payment_status'] = lunchPaymentStatus.dbValue;
    }

    if (updates.isEmpty) {
      // Nothing to update, just fetch current state
      final response = await supabase
          .from('tournament_registrations')
          .select()
          .eq('tournament_id', tournamentId)
          .eq('team_id', teamId)
          .single();
      return TournamentRegistration.fromJson(response);
    }

    final response = await supabase
        .from('tournament_registrations')
        .update(updates)
        .eq('tournament_id', tournamentId)
        .eq('team_id', teamId)
        .select()
        .single();

    return TournamentRegistration.fromJson(response);
  }

  /// Get count of registered teams
  Future<int> getRegisteredTeamCount(String tournamentId) async {
    final response = await supabase
        .from('tournament_registrations')
        .select('id')
        .eq('tournament_id', tournamentId);

    return (response as List).length;
  }
}
