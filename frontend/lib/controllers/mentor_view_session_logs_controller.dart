import "../api/api.dart";
import "../models/models.dart";
import "session_log_browser_controller.dart";

class MentorViewSessionLogsController
    extends SessionLogBrowserController<SharedMentor> {
  MentorViewSessionLogsController({
    MentorSessionLogApi? sessionLogApi,
    SharedCourseApi? courseApi,
    SharedStudentApi? studentApi,
    SharedCourseMentorsApi? mentorApi,
    super.studentRecordController,
  }) : _sessionLogApi = sessionLogApi ?? MentorSessionLogApi(),
       _courseApi = courseApi ?? SharedCourseApi(),
       _studentApi = studentApi ?? SharedStudentApi(),
       _mentorApi = mentorApi ?? SharedCourseMentorsApi();

  final MentorSessionLogApi _sessionLogApi;
  final SharedCourseApi _courseApi;
  final SharedStudentApi _studentApi;
  final SharedCourseMentorsApi _mentorApi;

  @override
  int mentorId(SharedMentor mentor) => mentor.id;

  @override
  String mentorName(SharedMentor mentor) => mentor.fullName;

  @override
  Future<SessionLogBrowserData<SharedMentor>> loadData({
    required String accessToken,
  }) async {
    final logsResult = await _sessionLogApi.fetchAvailableSessionLogs(
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

    final mentorsById = <int, SharedMentor>{};
    final courseIds = {for (final log in logs) log.courseId};
    for (final courseId in courseIds) {
      final result = await _mentorApi.fetchCourseMentors(
        accessToken: accessToken,
        courseId: courseId,
      );
      if (result.mentors == null) {
        return SessionLogBrowserData.failure(
          result.message ?? _messageForMentorFailure(result.failure),
        );
      }
      for (final mentor in result.mentors!) {
        mentorsById[mentor.id] = mentor;
      }
    }

    return SessionLogBrowserData.success(
      sessionLogs: logs,
      courses: courseResult.courses!,
      students: studentResult.students!,
      mentors: mentorsById.values.toList(),
    );
  }

  String _messageForSessionLogFailure(MentorSessionLogFailure? failure) {
    return switch (failure) {
      MentorSessionLogFailure.badRequest => "Invalid session log request.",
      MentorSessionLogFailure.unauthorized => "Login expired.",
      MentorSessionLogFailure.forbidden => "Session log access denied.",
      MentorSessionLogFailure.notFound => "Session logs not found.",
      MentorSessionLogFailure.conflict => "Session log conflict.",
      MentorSessionLogFailure.serverError => "Server error.",
      MentorSessionLogFailure.networkError => "Cannot connect to server.",
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
      SharedStudentFailure.serverError => "Server error.",
      SharedStudentFailure.networkError => "Cannot connect to server.",
      null => "Unknown error.",
    };
  }

  String _messageForMentorFailure(SharedCourseMentorsFailure? failure) {
    return switch (failure) {
      SharedCourseMentorsFailure.badRequest => "Invalid mentor request.",
      SharedCourseMentorsFailure.unauthorized => "Login expired.",
      SharedCourseMentorsFailure.forbidden => "Mentor access denied.",
      SharedCourseMentorsFailure.notFound => "Course not found.",
      SharedCourseMentorsFailure.serverError => "Server error.",
      SharedCourseMentorsFailure.networkError => "Cannot connect to server.",
      null => "Unknown error.",
    };
  }
}
