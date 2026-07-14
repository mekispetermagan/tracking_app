enum ProjectType {
  scratch('scratch', 'Scratch'),
  robotics('robotics', 'Robotics'),
  appInventor('app_inventor', 'App Inventor'),
  webDevelopment('web_development', 'Web development'),
  other('other', 'Other');

  const ProjectType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ProjectType fromApiValue(String value) {
    return ProjectType.values.firstWhere((type) => type.apiValue == value);
  }
}

enum CompletionStatus {
  completed('completed', 'Completed'),
  partlyCompleted('partly_completed', 'Partly completed'),
  notCompleted('not_completed', 'Not completed');

  const CompletionStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CompletionStatus fromApiValue(String value) {
    return CompletionStatus.values.firstWhere(
      (status) => status.apiValue == value,
    );
  }
}

class SessionLog {
  final int id;
  final int mentorProfileId;
  final int courseId;
  final DateTime date;
  final String projectTitle;
  final ProjectType projectType;
  final String? otherProjectType;
  final String? gamesPlayed;
  final CompletionStatus completionStatus;
  final String? whatWorked;
  final String? challenges;
  final String? nextStep;
  final List<int> studentIds;
  final DateTime createdAt;

  const SessionLog({
    required this.id,
    required this.mentorProfileId,
    required this.courseId,
    required this.date,
    required this.projectTitle,
    required this.projectType,
    required this.otherProjectType,
    required this.gamesPlayed,
    required this.completionStatus,
    required this.whatWorked,
    required this.challenges,
    required this.nextStep,
    required this.studentIds,
    required this.createdAt,
  });

  factory SessionLog.fromJson(Map<String, dynamic> json) {
    return SessionLog(
      id: json['id'] as int,
      mentorProfileId: json['mentor_profile_id'] as int,
      courseId: json['course_id'] as int,
      date: DateTime.parse(json['date'] as String),
      projectTitle: json['project_title'] as String,
      projectType: ProjectType.fromApiValue(json['project_type'] as String),
      otherProjectType: json['other_project_type'] as String?,
      gamesPlayed: json['games_played'] as String?,
      completionStatus: CompletionStatus.fromApiValue(
        json['completion_status'] as String,
      ),
      whatWorked: json['what_worked'] as String?,
      challenges: json['challenges'] as String?,
      nextStep: json['next_step'] as String?,
      studentIds: List<int>.from(json['student_ids'] as List),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SessionLogCreateRequest {
  final int courseId;
  final DateTime date;
  final String projectTitle;
  final ProjectType projectType;
  final String? otherProjectType;
  final String? gamesPlayed;
  final CompletionStatus completionStatus;
  final String? whatWorked;
  final String? challenges;
  final String? nextStep;
  final List<int> studentIds;

  const SessionLogCreateRequest({
    required this.courseId,
    required this.date,
    required this.projectTitle,
    required this.projectType,
    required this.completionStatus,
    required this.studentIds,
    this.otherProjectType,
    this.gamesPlayed,
    this.whatWorked,
    this.challenges,
    this.nextStep,
  });

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'date': _dateToJson(date),
      'project_title': projectTitle,
      'project_type': projectType.apiValue,
      'other_project_type': otherProjectType,
      'games_played': gamesPlayed,
      'completion_status': completionStatus.apiValue,
      'what_worked': whatWorked,
      'challenges': challenges,
      'next_step': nextStep,
      'student_ids': studentIds,
    };
  }
}

String _dateToJson(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}
