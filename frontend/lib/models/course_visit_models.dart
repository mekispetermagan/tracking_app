enum CourseVisitSessionStatus {
  fullyHeld('fully_held', 'Fully held'),
  partlyHeld('partly_held', 'Partly held'),
  notHeld('not_held', 'Not held');

  const CourseVisitSessionStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CourseVisitSessionStatus fromApiValue(String value) {
    return CourseVisitSessionStatus.values.firstWhere(
      (status) => status.apiValue == value,
    );
  }
}

enum CourseVisitAnswer {
  yes('yes', 'Yes'),
  partly('partly', 'Partly'),
  no('no', 'No');

  const CourseVisitAnswer(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CourseVisitAnswer fromApiValue(String value) {
    return CourseVisitAnswer.values.firstWhere(
      (answer) => answer.apiValue == value,
    );
  }
}

enum CourseVisitLearnerEngagement {
  almostAll('almost_all', 'Almost all'),
  most('most', 'Most'),
  aboutHalf('about_half', 'About half'),
  few('few', 'Few');

  const CourseVisitLearnerEngagement(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CourseVisitLearnerEngagement fromApiValue(String value) {
    return CourseVisitLearnerEngagement.values.firstWhere(
      (engagement) => engagement.apiValue == value,
    );
  }
}

enum CourseVisitEnvironmentStatus {
  safeAndRespectful('safe_and_respectful', 'Safe and respectful'),
  minorConcern('minor_concern', 'Minor concern'),
  seriousConcern('serious_concern', 'Serious concern');

  const CourseVisitEnvironmentStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CourseVisitEnvironmentStatus fromApiValue(String value) {
    return CourseVisitEnvironmentStatus.values.firstWhere(
      (status) => status.apiValue == value,
    );
  }
}

enum CourseVisitMentorRole {
  teaching('teaching', 'Teaching'),
  supporting('supporting', 'Supporting');

  const CourseVisitMentorRole(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CourseVisitMentorRole fromApiValue(String value) {
    return CourseVisitMentorRole.values.firstWhere(
      (role) => role.apiValue == value,
    );
  }
}

enum CourseVisitStudentEnjoyment {
  yes('yes', 'Yes'),
  mixed('mixed', 'Mixed'),
  no('no', 'No');

  const CourseVisitStudentEnjoyment(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CourseVisitStudentEnjoyment fromApiValue(String value) {
    return CourseVisitStudentEnjoyment.values.firstWhere(
      (answer) => answer.apiValue == value,
    );
  }
}

enum CourseVisitStudentLearning {
  clearly('clearly', 'Clearly'),
  partly('partly', 'Partly'),
  no('no', 'No');

  const CourseVisitStudentLearning(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CourseVisitStudentLearning fromApiValue(String value) {
    return CourseVisitStudentLearning.values.firstWhere(
      (answer) => answer.apiValue == value,
    );
  }
}

enum CourseVisitStudentSafety {
  yes('yes', 'Yes'),
  unsure('unsure', 'Unsure'),
  no('no', 'No');

  const CourseVisitStudentSafety(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CourseVisitStudentSafety fromApiValue(String value) {
    return CourseVisitStudentSafety.values.firstWhere(
      (answer) => answer.apiValue == value,
    );
  }
}

enum CourseVisitActionCategory {
  mentorCoaching('mentor_coaching', 'Mentor coaching'),
  followUpVisit('follow_up_visit', 'Follow-up visit'),
  curriculumSupport('curriculum_support', 'Curriculum support'),
  equipment('equipment', 'Equipment'),
  attendanceRetention('attendance_retention', 'Attendance or retention'),
  venueScheduling('venue_scheduling', 'Venue or scheduling'),
  staffing('staffing', 'Staffing'),
  partnerDiscussion('partner_discussion', 'Partner discussion'),
  safeguarding('safeguarding', 'Safeguarding'),
  other('other', 'Other');

  const CourseVisitActionCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CourseVisitActionCategory fromApiValue(String value) {
    return CourseVisitActionCategory.values.firstWhere(
      (category) => category.apiValue == value,
    );
  }
}

class CourseVisitMentor {
  final int mentorId;
  final CourseVisitMentorRole? role;
  final int? performanceRating;

  const CourseVisitMentor({
    required this.mentorId,
    this.role,
    this.performanceRating,
  });

  factory CourseVisitMentor.fromJson(Map<String, dynamic> json) {
    final roleValue = json['role'] as String?;

    return CourseVisitMentor(
      mentorId: json['mentor_id'] as int,
      role: roleValue == null
          ? null
          : CourseVisitMentorRole.fromApiValue(roleValue),
      performanceRating: json['performance_rating'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mentor_id': mentorId,
      'role': role?.apiValue,
      'performance_rating': performanceRating,
    };
  }
}

class CourseVisitStudent {
  final int studentId;
  final bool interviewed;
  final CourseVisitStudentEnjoyment? enjoyment;
  final CourseVisitStudentLearning? learning;
  final CourseVisitStudentSafety? feelsSafe;
  final String? note;

  const CourseVisitStudent({
    required this.studentId,
    this.interviewed = false,
    this.enjoyment,
    this.learning,
    this.feelsSafe,
    this.note,
  });

  factory CourseVisitStudent.fromJson(Map<String, dynamic> json) {
    final enjoymentValue = json['enjoyment'] as String?;
    final learningValue = json['learning'] as String?;
    final feelsSafeValue = json['feels_safe'] as String?;

    return CourseVisitStudent(
      studentId: json['student_id'] as int,
      interviewed: json['interviewed'] as bool,
      enjoyment: enjoymentValue == null
          ? null
          : CourseVisitStudentEnjoyment.fromApiValue(enjoymentValue),
      learning: learningValue == null
          ? null
          : CourseVisitStudentLearning.fromApiValue(learningValue),
      feelsSafe: feelsSafeValue == null
          ? null
          : CourseVisitStudentSafety.fromApiValue(feelsSafeValue),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'interviewed': interviewed,
      'enjoyment': enjoyment?.apiValue,
      'learning': learning?.apiValue,
      'feels_safe': feelsSafe?.apiValue,
      'note': note,
    };
  }
}

class CourseVisitActionCreateRequest {
  final CourseVisitActionCategory category;
  final String description;
  final String? responsiblePerson;
  final DateTime? targetDate;

  const CourseVisitActionCreateRequest({
    required this.category,
    required this.description,
    this.responsiblePerson,
    this.targetDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category.apiValue,
      'description': description,
      'responsible_person': responsiblePerson,
      'target_date': targetDate == null ? null : _dateToJson(targetDate!),
    };
  }
}

class CourseVisitAction {
  final int id;
  final CourseVisitActionCategory category;
  final String description;
  final String? responsiblePerson;
  final DateTime? targetDate;
  final bool completed;
  final DateTime? completedAt;

  const CourseVisitAction({
    required this.id,
    required this.category,
    required this.description,
    required this.responsiblePerson,
    required this.targetDate,
    required this.completed,
    required this.completedAt,
  });

  factory CourseVisitAction.fromJson(Map<String, dynamic> json) {
    final targetDateValue = json['target_date'] as String?;
    final completedAtValue = json['completed_at'] as String?;

    return CourseVisitAction(
      id: json['id'] as int,
      category: CourseVisitActionCategory.fromApiValue(
        json['category'] as String,
      ),
      description: json['description'] as String,
      responsiblePerson: json['responsible_person'] as String?,
      targetDate: targetDateValue == null
          ? null
          : DateTime.parse(targetDateValue),
      completed: json['completed'] as bool,
      completedAt: completedAtValue == null
          ? null
          : DateTime.parse(completedAtValue),
    );
  }
}

class CourseVisitReport {
  final int id;
  final int submittedByAdminProfileId;
  final int courseId;
  final DateTime date;
  final CourseVisitSessionStatus sessionStatus;
  final CourseVisitAnswer teachingTookPlace;
  final CourseVisitAnswer? sessionFollowedPlan;
  final CourseVisitLearnerEngagement? learnerEngagement;
  final CourseVisitAnswer? equipmentAdequate;
  final CourseVisitEnvironmentStatus? environmentStatus;
  final String whatHappened;
  final String? mainStrength;
  final String? mainProblem;
  final String? supportProvided;
  final int courseHealthRating;
  final bool safeguardingConcern;
  final String? safeguardingNote;
  final List<CourseVisitMentor> mentors;
  final List<CourseVisitStudent> students;
  final List<CourseVisitAction> actions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CourseVisitReport({
    required this.id,
    required this.submittedByAdminProfileId,
    required this.courseId,
    required this.date,
    required this.sessionStatus,
    required this.teachingTookPlace,
    required this.sessionFollowedPlan,
    required this.learnerEngagement,
    required this.equipmentAdequate,
    required this.environmentStatus,
    required this.whatHappened,
    required this.mainStrength,
    required this.mainProblem,
    required this.supportProvided,
    required this.courseHealthRating,
    required this.safeguardingConcern,
    required this.safeguardingNote,
    required this.mentors,
    required this.students,
    required this.actions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseVisitReport.fromJson(Map<String, dynamic> json) {
    final sessionFollowedPlanValue = json['session_followed_plan'] as String?;
    final learnerEngagementValue = json['learner_engagement'] as String?;
    final equipmentAdequateValue = json['equipment_adequate'] as String?;
    final environmentStatusValue = json['environment_status'] as String?;

    return CourseVisitReport(
      id: json['id'] as int,
      submittedByAdminProfileId: json['submitted_by_admin_profile_id'] as int,
      courseId: json['course_id'] as int,
      date: DateTime.parse(json['date'] as String),
      sessionStatus: CourseVisitSessionStatus.fromApiValue(
        json['session_status'] as String,
      ),
      teachingTookPlace: CourseVisitAnswer.fromApiValue(
        json['teaching_took_place'] as String,
      ),
      sessionFollowedPlan: sessionFollowedPlanValue == null
          ? null
          : CourseVisitAnswer.fromApiValue(sessionFollowedPlanValue),
      learnerEngagement: learnerEngagementValue == null
          ? null
          : CourseVisitLearnerEngagement.fromApiValue(learnerEngagementValue),
      equipmentAdequate: equipmentAdequateValue == null
          ? null
          : CourseVisitAnswer.fromApiValue(equipmentAdequateValue),
      environmentStatus: environmentStatusValue == null
          ? null
          : CourseVisitEnvironmentStatus.fromApiValue(environmentStatusValue),
      whatHappened: json['what_happened'] as String,
      mainStrength: json['main_strength'] as String?,
      mainProblem: json['main_problem'] as String?,
      supportProvided: json['support_provided'] as String?,
      courseHealthRating: json['course_health_rating'] as int,
      safeguardingConcern: json['safeguarding_concern'] as bool,
      safeguardingNote: json['safeguarding_note'] as String?,
      mentors: (json['mentors'] as List)
          .map(
            (item) => CourseVisitMentor.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      students: (json['students'] as List)
          .map(
            (item) => CourseVisitStudent.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      actions: (json['actions'] as List)
          .map(
            (item) => CourseVisitAction.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class CourseVisitReportCreateRequest {
  final int courseId;
  final DateTime date;
  final CourseVisitSessionStatus sessionStatus;
  final CourseVisitAnswer teachingTookPlace;
  final CourseVisitAnswer? sessionFollowedPlan;
  final CourseVisitLearnerEngagement? learnerEngagement;
  final CourseVisitAnswer? equipmentAdequate;
  final CourseVisitEnvironmentStatus? environmentStatus;
  final String whatHappened;
  final String? mainStrength;
  final String? mainProblem;
  final String? supportProvided;
  final int courseHealthRating;
  final bool safeguardingConcern;
  final String? safeguardingNote;
  final List<CourseVisitMentor> mentors;
  final List<CourseVisitStudent> students;
  final List<CourseVisitActionCreateRequest> actions;

  const CourseVisitReportCreateRequest({
    required this.courseId,
    required this.date,
    required this.sessionStatus,
    required this.teachingTookPlace,
    required this.whatHappened,
    required this.courseHealthRating,
    required this.mentors,
    required this.students,
    this.sessionFollowedPlan,
    this.learnerEngagement,
    this.equipmentAdequate,
    this.environmentStatus,
    this.mainStrength,
    this.mainProblem,
    this.supportProvided,
    this.safeguardingConcern = false,
    this.safeguardingNote,
    this.actions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'date': _dateToJson(date),
      'session_status': sessionStatus.apiValue,
      'teaching_took_place': teachingTookPlace.apiValue,
      'session_followed_plan': sessionFollowedPlan?.apiValue,
      'learner_engagement': learnerEngagement?.apiValue,
      'equipment_adequate': equipmentAdequate?.apiValue,
      'environment_status': environmentStatus?.apiValue,
      'what_happened': whatHappened,
      'main_strength': mainStrength,
      'main_problem': mainProblem,
      'support_provided': supportProvided,
      'course_health_rating': courseHealthRating,
      'safeguarding_concern': safeguardingConcern,
      'safeguarding_note': safeguardingNote,
      'mentors': mentors.map((mentor) => mentor.toJson()).toList(),
      'students': students.map((student) => student.toJson()).toList(),
      'actions': actions.map((action) => action.toJson()).toList(),
    };
  }
}

String _dateToJson(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}
