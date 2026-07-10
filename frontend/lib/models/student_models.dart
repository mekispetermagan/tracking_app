class Student {
  final int id;
  final String firstName;
  final String lastName;
  final int? originCountryId;
  final int? birthYear;
  final String? gender;
  final bool active;
  final List<int> courseIds;

  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.originCountryId,
    required this.birthYear,
    required this.gender,
    required this.active,
    required this.courseIds,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      originCountryId: json['origin_country_id'] as int?,
      birthYear: json['birth_year'] as int?,
      gender: json['gender'] as String?,
      active: json['active'] as bool,
      courseIds: List<int>.from(json['course_ids'] as List),
    );
  }

  String get fullName => '$firstName $lastName';
}

class StudentCreateRequest {
  final String firstName;
  final String lastName;
  final int? originCountryId;
  final int? birthYear;
  final String? gender;
  final bool active;
  final List<int> courseIds;

  const StudentCreateRequest({
    required this.firstName,
    required this.lastName,
    this.originCountryId,
    this.birthYear,
    this.gender,
    this.active = true,
    this.courseIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'origin_country_id': originCountryId,
      'birth_year': birthYear,
      'gender': gender,
      'active': active,
      'course_ids': courseIds,
    };
  }
}

class StudentUpdateRequest {
  final String firstName;
  final String lastName;
  final int? originCountryId;
  final int? birthYear;
  final String? gender;
  final bool active;
  final List<int> courseIds;

  const StudentUpdateRequest({
    required this.firstName,
    required this.lastName,
    required this.originCountryId,
    required this.birthYear,
    required this.gender,
    required this.active,
    required this.courseIds,
  });

  factory StudentUpdateRequest.fromStudent(Student student) {
    return StudentUpdateRequest(
      firstName: student.firstName,
      lastName: student.lastName,
      originCountryId: student.originCountryId,
      birthYear: student.birthYear,
      gender: student.gender,
      active: student.active,
      courseIds: student.courseIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'origin_country_id': originCountryId,
      'birth_year': birthYear,
      'gender': gender,
      'active': active,
      'course_ids': courseIds,
    };
  }
}
