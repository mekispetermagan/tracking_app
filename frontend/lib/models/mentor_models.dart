class Mentor {
  final int id;
  final int accountId;
  final String firstName;
  final String lastName;
  final String phone;
  final int? countryId;
  final String preferredLanguage;
  final bool active;
  final List<int> courseIds;

  const Mentor({
    required this.id,
    required this.accountId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.countryId,
    required this.preferredLanguage,
    required this.active,
    required this.courseIds,
  });

  factory Mentor.fromJson(Map<String, dynamic> json) {
    return Mentor(
      id: json['id'] as int,
      accountId: json['account_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      phone: json['phone'] as String,
      countryId: json['country_id'] as int?,
      preferredLanguage: json['preferred_language'] as String,
      active: json['active'] as bool,
      courseIds: List<int>.from(json['course_ids'] as List),
    );
  }

  String get fullName => '$firstName $lastName';
}

class MentorCreateRequest {
  final String firstName;
  final String lastName;
  final String phone;
  final int? countryId;
  final String preferredLanguage;
  final String temporaryPin;
  final bool active;
  final List<int> courseIds;

  const MentorCreateRequest({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.temporaryPin,
    this.countryId,
    this.preferredLanguage = 'en',
    this.active = true,
    this.courseIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'country_id': countryId,
      'preferred_language': preferredLanguage,
      'temporary_pin': temporaryPin,
      'active': active,
      'course_ids': courseIds,
    };
  }
}

class MentorUpdateRequest {
  final String firstName;
  final String lastName;
  final String phone;
  final int? countryId;
  final String preferredLanguage;
  final bool active;
  final List<int> courseIds;

  const MentorUpdateRequest({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.countryId,
    required this.preferredLanguage,
    required this.active,
    required this.courseIds,
  });

  factory MentorUpdateRequest.fromMentor(Mentor mentor) {
    return MentorUpdateRequest(
      firstName: mentor.firstName,
      lastName: mentor.lastName,
      phone: mentor.phone,
      countryId: mentor.countryId,
      preferredLanguage: mentor.preferredLanguage,
      active: mentor.active,
      courseIds: mentor.courseIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'country_id': countryId,
      'preferred_language': preferredLanguage,
      'active': active,
      'course_ids': courseIds,
    };
  }
}

class MentorSelfUpdateRequest {
  final String firstName;
  final String lastName;
  final String phone;
  final int? countryId;
  final String preferredLanguage;

  const MentorSelfUpdateRequest({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.countryId,
    required this.preferredLanguage,
  });

  factory MentorSelfUpdateRequest.fromMentor(Mentor mentor) {
    return MentorSelfUpdateRequest(
      firstName: mentor.firstName,
      lastName: mentor.lastName,
      phone: mentor.phone,
      countryId: mentor.countryId,
      preferredLanguage: mentor.preferredLanguage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'country_id': countryId,
      'preferred_language': preferredLanguage,
    };
  }
}

class MentorResetPinRequest {
  final String temporaryPin;

  const MentorResetPinRequest({required this.temporaryPin});

  Map<String, dynamic> toJson() {
    return {'temporary_pin': temporaryPin};
  }
}
