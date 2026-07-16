import 'session_log_models.dart';

class StudentRecord {
  final int studentId;
  final String firstName;
  final String lastName;
  final int attendedSessions;
  final double overallActivityScore;
  final List<StudentRecordProjectGroup> projectGroups;
  final List<StudentRecordSkillGame> skillGames;

  const StudentRecord({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.attendedSessions,
    required this.overallActivityScore,
    required this.projectGroups,
    required this.skillGames,
  });

  String get fullName => '$firstName $lastName';

  factory StudentRecord.fromJson(Map<String, dynamic> json) {
    return StudentRecord(
      studentId: json['student_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      attendedSessions: json['attended_sessions'] as int,
      overallActivityScore: (json['overall_activity_score'] as num).toDouble(),
      projectGroups: (json['project_groups'] as List<dynamic>)
          .map(
            (item) => StudentRecordProjectGroup.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      skillGames: (json['skill_games'] as List<dynamic>)
          .map(
            (item) =>
                StudentRecordSkillGame.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class StudentRecordProjectGroup {
  final ProjectType projectType;
  final int completedCount;
  final int partlyCompletedCount;
  final int notCompletedCount;
  final double activityScore;
  final List<StudentRecordProject> projects;

  const StudentRecordProjectGroup({
    required this.projectType,
    required this.completedCount,
    required this.partlyCompletedCount,
    required this.notCompletedCount,
    required this.activityScore,
    required this.projects,
  });

  factory StudentRecordProjectGroup.fromJson(Map<String, dynamic> json) {
    return StudentRecordProjectGroup(
      projectType: ProjectType.fromApiValue(json['project_type'] as String),
      completedCount: json['completed_count'] as int,
      partlyCompletedCount: json['partly_completed_count'] as int,
      notCompletedCount: json['not_completed_count'] as int,
      activityScore: (json['activity_score'] as num).toDouble(),
      projects: (json['projects'] as List<dynamic>)
          .map(
            (item) =>
                StudentRecordProject.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class StudentRecordProject {
  final String projectTitle;
  final DateTime date;
  final CompletionStatus completionStatus;

  const StudentRecordProject({
    required this.projectTitle,
    required this.date,
    required this.completionStatus,
  });

  factory StudentRecordProject.fromJson(Map<String, dynamic> json) {
    return StudentRecordProject(
      projectTitle: json['project_title'] as String,
      date: DateTime.parse(json['date'] as String),
      completionStatus: CompletionStatus.fromApiValue(
        json['completion_status'] as String,
      ),
    );
  }
}

class StudentRecordSkillGame {
  final String name;
  final int practiceCount;

  const StudentRecordSkillGame({
    required this.name,
    required this.practiceCount,
  });

  factory StudentRecordSkillGame.fromJson(Map<String, dynamic> json) {
    return StudentRecordSkillGame(
      name: json['name'] as String,
      practiceCount: json['practice_count'] as int,
    );
  }
}
