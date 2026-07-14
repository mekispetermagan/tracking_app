class Course {
  final int id;
  final String name;
  final String description;
  final int countryId;
  final int dayOfWeek;
  final String startTime;
  final bool active;
  final List<int> mentorIds;
  final List<int> studentIds;

  const Course({
    required this.id,
    required this.name,
    required this.description,
    required this.countryId,
    required this.dayOfWeek,
    required this.startTime,
    required this.active,
    required this.mentorIds,
    required this.studentIds,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      countryId: json['country_id'] as int,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      active: json['active'] as bool,
      mentorIds: List<int>.from(json['mentor_ids'] as List),
      studentIds: List<int>.from(json['student_ids'] as List),
    );
  }
}

class CourseCreateRequest {
  final String name;
  final String description;
  final int countryId;
  final int dayOfWeek;
  final String startTime;
  final bool active;
  final List<int> mentorIds;
  final List<int> studentIds;

  const CourseCreateRequest({
    required this.name,
    required this.countryId,
    required this.dayOfWeek,
    required this.startTime,
    this.description = '',
    this.active = true,
    this.mentorIds = const [],
    this.studentIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'country_id': countryId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'active': active,
      'mentor_ids': mentorIds,
      'student_ids': studentIds,
    };
  }
}

class CourseUpdateRequest {
  final String name;
  final String description;
  final int countryId;
  final int dayOfWeek;
  final String startTime;
  final bool active;
  final List<int> mentorIds;
  final List<int> studentIds;

  const CourseUpdateRequest({
    required this.name,
    required this.description,
    required this.countryId,
    required this.dayOfWeek,
    required this.startTime,
    required this.active,
    required this.mentorIds,
    required this.studentIds,
  });

  factory CourseUpdateRequest.fromCourse(Course course) {
    return CourseUpdateRequest(
      name: course.name,
      description: course.description,
      countryId: course.countryId,
      dayOfWeek: course.dayOfWeek,
      startTime: course.startTime,
      active: course.active,
      mentorIds: course.mentorIds,
      studentIds: course.studentIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'country_id': countryId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'active': active,
      'mentor_ids': mentorIds,
      'student_ids': studentIds,
    };
  }
}
