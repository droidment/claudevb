class Team {
  final String id;
  final String name;
  final String captainId;
  final String? logoUrl;
  final String? homeCity;
  final String? teamColor;
  final String sportType; // 'volleyball' or 'pickleball'
  final bool registrationPaid;
  final double? paymentAmount;
  final DateTime? paymentDate;
  final int lunchCount;
  final String? captainName;
  final String? captainEmail;
  final String? captainPhone;
  final String? contactPerson2;
  final String? contactPhone2;
  final int? playerCount;
  final String? specialRequests;
  final String? signedBy;
  final DateTime? registrationDate;
  final String? category;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    required this.id,
    required this.name,
    required this.captainId,
    this.logoUrl,
    this.homeCity,
    this.teamColor,
    this.sportType = 'volleyball',
    this.registrationPaid = false,
    this.paymentAmount,
    this.paymentDate,
    this.lunchCount = 0,
    this.captainName,
    this.captainEmail,
    this.captainPhone,
    this.contactPerson2,
    this.contactPhone2,
    this.playerCount,
    this.specialRequests,
    this.signedBy,
    this.registrationDate,
    this.category,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display name for the sport type
  String get sportTypeDisplayName {
    switch (sportType) {
      case 'pickleball':
        return 'Pickleball';
      case 'volleyball':
      default:
        return 'Volleyball';
    }
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      captainId: json['captain_id'] as String,
      logoUrl: json['logo_url'] as String?,
      homeCity: json['home_city'] as String?,
      teamColor: json['team_color'] as String?,
      sportType: json['sport_type'] as String? ?? 'volleyball',
      registrationPaid: json['registration_paid'] as bool? ?? false,
      paymentAmount: (json['payment_amount'] as num?)?.toDouble(),
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'] as String)
          : null,
      lunchCount: json['lunch_count'] as int? ?? 0,
      captainName: json['captain_name'] as String?,
      captainEmail: json['captain_email'] as String?,
      captainPhone: json['captain_phone'] as String?,
      contactPerson2: json['contact_person_2'] as String?,
      contactPhone2: json['contact_phone_2'] as String?,
      playerCount: json['player_count'] as int?,
      specialRequests: json['special_requests'] as String?,
      signedBy: json['signed_by'] as String?,
      registrationDate: json['registration_date'] != null
          ? DateTime.parse(json['registration_date'] as String)
          : null,
      category: json['category'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'captain_id': captainId,
      'logo_url': logoUrl,
      'home_city': homeCity,
      'team_color': teamColor,
      'sport_type': sportType,
      'registration_paid': registrationPaid,
      'payment_amount': paymentAmount,
      'payment_date': paymentDate?.toIso8601String(),
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'captain_id': captainId,
      'logo_url': logoUrl,
      'home_city': homeCity,
      'team_color': teamColor,
      'sport_type': sportType,
      'registration_paid': registrationPaid,
      'payment_amount': paymentAmount,
      'payment_date': paymentDate?.toIso8601String(),
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
  }

  Team copyWith({
    String? id,
    String? name,
    String? captainId,
    String? logoUrl,
    String? homeCity,
    String? teamColor,
    String? sportType,
    bool? registrationPaid,
    double? paymentAmount,
    DateTime? paymentDate,
    int? lunchCount,
    String? captainName,
    String? captainEmail,
    String? captainPhone,
    String? contactPerson2,
    String? contactPhone2,
    int? playerCount,
    String? specialRequests,
    String? signedBy,
    DateTime? registrationDate,
    String? category,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      captainId: captainId ?? this.captainId,
      logoUrl: logoUrl ?? this.logoUrl,
      homeCity: homeCity ?? this.homeCity,
      teamColor: teamColor ?? this.teamColor,
      sportType: sportType ?? this.sportType,
      registrationPaid: registrationPaid ?? this.registrationPaid,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      lunchCount: lunchCount ?? this.lunchCount,
      captainName: captainName ?? this.captainName,
      captainEmail: captainEmail ?? this.captainEmail,
      captainPhone: captainPhone ?? this.captainPhone,
      contactPerson2: contactPerson2 ?? this.contactPerson2,
      contactPhone2: contactPhone2 ?? this.contactPhone2,
      playerCount: playerCount ?? this.playerCount,
      specialRequests: specialRequests ?? this.specialRequests,
      signedBy: signedBy ?? this.signedBy,
      registrationDate: registrationDate ?? this.registrationDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents a team parsed from CSV for import preview
class CsvTeamImport {
  final String teamName;
  final String captainName;
  final String? captainEmail;
  final String? captainPhone;
  final String? contactPerson2;
  final int? playerCount;
  final String? specialRequests;
  final bool paid;
  final String? category;
  final DateTime? registrationDate;
  int lunchCount;
  bool selected;

  CsvTeamImport({
    required this.teamName,
    required this.captainName,
    this.captainEmail,
    this.captainPhone,
    this.contactPerson2,
    this.playerCount,
    this.specialRequests,
    this.paid = false,
    this.category,
    this.registrationDate,
    this.lunchCount = 0,
    this.selected = true,
  });

  /// Parse a CSV row into a CsvTeamImport
  /// Expected columns: Timestamp, Email Address, Score, Category, Team Name,
  /// Captain Name, Phone, Contact Person 2, Number of Players, Special Requests,
  /// Rules Acknowledged, Signed By, Date/Time, Column 13, Paid
  factory CsvTeamImport.fromCsvRow(List<String> row) {
    bool isPaid = false;
    if (row.length > 14) {
      final paidValue = row[14].trim().toUpperCase();
      isPaid = paidValue == 'Y' || paidValue == 'YES' || paidValue == 'PAID';
    }

    int? playerCount;
    if (row.length > 8 && row[8].isNotEmpty) {
      // Handle formats like "9", "Volleyball 9", "7-10", "Volleyball - 9 Players"
      final countStr = row[8].replaceAll(RegExp(r'[^0-9-]'), '');
      if (countStr.contains('-')) {
        playerCount = int.tryParse(countStr.split('-').first);
      } else {
        playerCount = int.tryParse(countStr);
      }
    }

    DateTime? registrationDate;
    if (row.isNotEmpty && row[0].isNotEmpty) {
      try {
        // Parse format like "10/19/2025 12:21:49"
        final parts = row[0].split(' ');
        if (parts.isNotEmpty) {
          final dateParts = parts[0].split('/');
          if (dateParts.length == 3) {
            registrationDate = DateTime(
              int.parse(dateParts[2]),
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
            );
          }
        }
      } catch (_) {}
    }

    return CsvTeamImport(
      teamName: row.length > 4 ? row[4].trim() : '',
      captainName: row.length > 5 ? row[5].trim() : '',
      captainEmail: row.length > 1 ? row[1].trim() : null,
      captainPhone: row.length > 6 ? row[6].trim() : null,
      contactPerson2: row.length > 7 && row[7].isNotEmpty
          ? row[7].trim()
          : null,
      playerCount: playerCount,
      specialRequests: row.length > 9 && row[9].isNotEmpty
          ? row[9].trim()
          : null,
      paid: isPaid,
      category: row.length > 3 ? row[3].trim() : null,
      registrationDate: registrationDate,
    );
  }

  bool get isMensVolleyball {
    if (category == null) return false;
    final cat = category!.toLowerCase();
    return cat.contains("men's volleyball") || cat == "men's volleyball";
  }

  bool get isThrowball {
    if (category == null) return false;
    return category!.toLowerCase().contains('throwball');
  }

  bool get is45PlusVolleyball {
    if (category == null) return false;
    return category!.toLowerCase().contains('45+');
  }

  bool get isNotPlaying {
    if (category == null) return false;
    // Check the paid column for "Not playing" or "Not Playing"
    return false; // This will be checked separately
  }
}
