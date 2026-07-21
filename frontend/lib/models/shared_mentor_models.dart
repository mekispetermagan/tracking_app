import '_model_utils.dart';

class SharedMentor {
  final int id;
  final String firstName;
  final String lastName;
  final bool active;
  final bool assignedToCourse;

  const SharedMentor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.active,
    required this.assignedToCourse,
  });

  String get fullName => personName(firstName, lastName);

  bool get availableForSession => active && assignedToCourse;

  factory SharedMentor.fromJson(Map<String, dynamic> json) {
    return SharedMentor(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      active: json['active'] as bool,
      assignedToCourse: json['assigned_to_course'] as bool,
    );
  }
}
