import "../api/api.dart";
import "../models/models.dart";
import "session_log_browser_controller.dart";

class AdminViewSessionLogsController
    extends SessionLogBrowserController<Mentor> {
  AdminViewSessionLogsController({
    AdminSessionLogApi? sessionLogApi,
    SharedCourseApi? courseApi,
    SharedStudentApi? studentApi,
    AdminMentorApi? mentorApi,
    super.studentRecordController,
  }) : _sessionLogApi = sessionLogApi ?? AdminSessionLogApi(),
       _courseApi = courseApi ?? SharedCourseApi(),
       _studentApi = studentApi ?? SharedStudentApi(),
       _mentorApi = mentorApi ?? AdminMentorApi();

  final AdminSessionLogApi _sessionLogApi;
  final SharedCourseApi _courseApi;
  final SharedStudentApi _studentApi;
  final AdminMentorApi _mentorApi;

  @override
  int mentorId(Mentor mentor) => mentor.id;

  @override
  String mentorName(Mentor mentor) => "${mentor.firstName} ${mentor.lastName}";

  @override
  Future<SessionLogBrowserData<Mentor>> loadData({
    required String accessToken,
  }) async {
    final logsResult = await _sessionLogApi.fetchSessionLogs(
      accessToken: accessToken,
    );
    final logs = logsResult.sessionLogs;
    if (logs == null) {
      return SessionLogBrowserData.failure(
        logsResult.message ?? _messageForSessionLogFailure(logsResult.failure),
      );
    }
    if (logs.isEmpty) {
      return const SessionLogBrowserData.success(
        sessionLogs: [],
        courses: [],
        students: [],
        mentors: [],
      );
    }

    final courseResult = await _courseApi.fetchCourses(
      accessToken: accessToken,
      activeOnly: false,
    );
    if (courseResult.courses == null) {
      return SessionLogBrowserData.failure(
        courseResult.message ?? _messageForCourseFailure(courseResult.failure),
      );
    }

    final studentResult = await _studentApi.fetchStudents(
      accessToken: accessToken,
      activeOnly: false,
    );
    if (studentResult.students == null) {
      return SessionLogBrowserData.failure(
        studentResult.message ??
            _messageForStudentFailure(studentResult.failure),
      );
    }

    final mentorResult = await _mentorApi.fetchMentors(
      accessToken: accessToken,
      activeOnly: false,
    );
    if (mentorResult.mentors == null) {
      return SessionLogBrowserData.failure(
        mentorResult.message ?? _messageForMentorFailure(mentorResult.failure),
      );
    }

    return SessionLogBrowserData.success(
      sessionLogs: logs,
      courses: courseResult.courses!,
      students: studentResult.students!,
      mentors: mentorResult.mentors!,
    );
  }

  String _messageForSessionLogFailure(AdminSessionLogFailure? failure) {
    return switch (failure) {
      AdminSessionLogFailure.badRequest => "Invalid session log request.",
      AdminSessionLogFailure.unauthorized => "Login expired.",
      AdminSessionLogFailure.forbidden => "Session log access denied.",
      AdminSessionLogFailure.invalidData => 'Invalid server data.',
      AdminSessionLogFailure.serverError => "Server error.",
      AdminSessionLogFailure.networkError => "Cannot connect to server.",
      null => "Unknown error.",
    };
  }

  String _messageForCourseFailure(SharedCourseFailure? failure) {
    return switch (failure) {
      SharedCourseFailure.badRequest => "Invalid course request.",
      SharedCourseFailure.unauthorized => "Login expired.",
      SharedCourseFailure.forbidden => "Course access denied.",
      SharedCourseFailure.notFound => "Course not found.",
      SharedCourseFailure.conflict => "Course conflict.",
      SharedCourseFailure.invalidData => 'Invalid server data.',
      SharedCourseFailure.serverError => "Server error.",
      SharedCourseFailure.networkError => "Cannot connect to server.",
      null => "Unknown error.",
    };
  }

  String _messageForStudentFailure(SharedStudentFailure? failure) {
    return switch (failure) {
      SharedStudentFailure.badRequest => "Invalid student request.",
      SharedStudentFailure.unauthorized => "Login expired.",
      SharedStudentFailure.forbidden => "Student access denied.",
      SharedStudentFailure.notFound => "Student not found.",
      SharedStudentFailure.conflict => "Student conflict.",
      SharedStudentFailure.invalidData => 'Invalid server data.',
      SharedStudentFailure.serverError => "Server error.",
      SharedStudentFailure.networkError => "Cannot connect to server.",
      null => "Unknown error.",
    };
  }

  String _messageForMentorFailure(AdminMentorFailure? failure) {
    return switch (failure) {
      AdminMentorFailure.badRequest => "Invalid mentor request.",
      AdminMentorFailure.unauthorized => "Login expired.",
      AdminMentorFailure.forbidden => "Mentor access denied.",
      AdminMentorFailure.notFound => "Mentor not found.",
      AdminMentorFailure.conflict => "Mentor conflict.",
      AdminMentorFailure.invalidData => 'Invalid server data.',
      AdminMentorFailure.serverError => "Server error.",
      AdminMentorFailure.networkError => "Cannot connect to server.",
      null => "Unknown error.",
    };
  }
}
