class TournamentRegistration {
  final String id;
  final String tournamentId;
  final String teamId;
  final DateTime registrationDate;
  final PaymentStatus paymentStatus;
  final double? paymentAmount;
  final RegistrationStatus status;
  final String? poolAssignment;
  final int? seedNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.registrationDate,
    required this.paymentStatus,
    this.paymentAmount,
    required this.status,
    this.poolAssignment,
    this.seedNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TournamentRegistration.fromJson(Map<String, dynamic> json) {
    return TournamentRegistration(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      teamId: json['team_id'] as String,
      registrationDate: DateTime.parse(json['registration_date'] as String),
      paymentStatus: PaymentStatusExtension.fromString(
          json['payment_status'] as String? ?? 'pending'),
      paymentAmount: json['payment_amount'] != null
          ? double.parse(json['payment_amount'].toString())
          : null,
      status: RegistrationStatusExtension.fromString(
          json['status'] as String? ?? 'pending'),
      poolAssignment: json['pool_assignment'] as String?,
      seedNumber: json['seed_number'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'team_id': teamId,
      'registration_date': registrationDate.toIso8601String(),
      'payment_status': paymentStatus.dbValue,
      'payment_amount': paymentAmount,
      'status': status.dbValue,
      'pool_assignment': poolAssignment,
      'seed_number': seedNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'tournament_id': tournamentId,
      'team_id': teamId,
      'payment_status': paymentStatus.dbValue,
      'payment_amount': paymentAmount,
      'status': status.dbValue,
      'pool_assignment': poolAssignment,
      'seed_number': seedNumber,
      'notes': notes,
    };
  }
}

enum PaymentStatus {
  pending,
  paid,
  refunded,
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String get dbValue {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }
}

enum RegistrationStatus {
  pending,
  approved,
  rejected,
  withdrawn,
}

extension RegistrationStatusExtension on RegistrationStatus {
  String get displayName {
    switch (this) {
      case RegistrationStatus.pending:
        return 'Pending';
      case RegistrationStatus.approved:
        return 'Approved';
      case RegistrationStatus.rejected:
        return 'Rejected';
      case RegistrationStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  String get dbValue {
    switch (this) {
      case RegistrationStatus.pending:
        return 'pending';
      case RegistrationStatus.approved:
        return 'approved';
      case RegistrationStatus.rejected:
        return 'rejected';
      case RegistrationStatus.withdrawn:
        return 'withdrawn';
    }
  }

  static RegistrationStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return RegistrationStatus.pending;
      case 'approved':
        return RegistrationStatus.approved;
      case 'rejected':
        return RegistrationStatus.rejected;
      case 'withdrawn':
        return RegistrationStatus.withdrawn;
      default:
        return RegistrationStatus.pending;
    }
  }
}
