import '../core/supabase_client.dart';
import '../models/tournament_staff.dart';

/// Service for managing tournament staff (admins and scorers)
class TournamentStaffService {
  /// Get all staff for a tournament
  Future<List<TournamentStaff>> getStaffForTournament(String tournamentId) async {
    final response = await supabase
        .from('tournament_staff')
        .select('''
          *,
          user:user_profiles!tournament_staff_user_id_fkey(email, full_name),
          assigned_by_user:user_profiles!tournament_staff_assigned_by_fkey(full_name)
        ''')
        .eq('tournament_id', tournamentId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => TournamentStaff.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get current user's permissions for a tournament
  Future<TournamentPermissions> getPermissionsForTournament(
    String tournamentId,
  ) async {
    final user = supabase.auth.currentUser;
    if (user == null) return TournamentPermissions.none;

    // Check if user is the tournament owner
    final tournamentResponse = await supabase
        .from('tournaments')
        .select('organizer_id')
        .eq('id', tournamentId)
        .maybeSingle();

    final isOwner = tournamentResponse != null &&
        tournamentResponse['organizer_id'] == user.id;

    // Check if user is staff
    final staffResponse = await supabase
        .from('tournament_staff')
        .select('id, role')
        .eq('tournament_id', tournamentId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (staffResponse == null) {
      return TournamentPermissions(isOwner: isOwner);
    }

    final role = StaffRoleExtension.fromString(staffResponse['role'] as String);
    return TournamentPermissions(
      isOwner: isOwner,
      isAdmin: role == StaffRole.admin,
      isScorer: role == StaffRole.scorer,
      staffId: staffResponse['id'] as String,
    );
  }

  /// Add a staff member to a tournament
  Future<TournamentStaff> addStaff({
    required String tournamentId,
    required String userId,
    required StaffRole role,
  }) async {
    final currentUser = supabase.auth.currentUser;

    final response = await supabase
        .from('tournament_staff')
        .insert({
          'tournament_id': tournamentId,
          'user_id': userId,
          'role': role.dbValue,
          'assigned_by': currentUser?.id,
        })
        .select('''
          *,
          user:user_profiles!tournament_staff_user_id_fkey(email, full_name),
          assigned_by_user:user_profiles!tournament_staff_assigned_by_fkey(full_name)
        ''')
        .single();

    return TournamentStaff.fromJson(response);
  }

  /// Update a staff member's role
  Future<TournamentStaff> updateStaffRole({
    required String staffId,
    required StaffRole newRole,
  }) async {
    final response = await supabase
        .from('tournament_staff')
        .update({'role': newRole.dbValue})
        .eq('id', staffId)
        .select('''
          *,
          user:user_profiles!tournament_staff_user_id_fkey(email, full_name),
          assigned_by_user:user_profiles!tournament_staff_assigned_by_fkey(full_name)
        ''')
        .single();

    return TournamentStaff.fromJson(response);
  }

  /// Remove a staff member from a tournament
  Future<void> removeStaff(String staffId) async {
    await supabase.from('tournament_staff').delete().eq('id', staffId);
  }

  /// Search for users by email to add as staff
  Future<List<Map<String, dynamic>>> searchUsersByEmail(String email) async {
    if (email.length < 3) return [];

    final response = await supabase
        .from('user_profiles')
        .select('id, email, full_name')
        .ilike('email', '%$email%')
        .limit(10);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Check if a user is already staff for a tournament
  Future<bool> isUserStaff(String tournamentId, String userId) async {
    final response = await supabase
        .from('tournament_staff')
        .select('id')
        .eq('tournament_id', tournamentId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  /// Get all tournaments where current user is staff
  Future<List<Map<String, dynamic>>> getTournamentsWhereStaff() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('tournament_staff')
        .select('''
          role,
          tournament:tournaments(*)
        ''')
        .eq('user_id', user.id);

    return (response as List).cast<Map<String, dynamic>>();
  }
}
