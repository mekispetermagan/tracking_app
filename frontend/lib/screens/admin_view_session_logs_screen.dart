import '../widgets/session_log_management_view.dart';

class AdminViewSessionLogsScreen extends SessionLogManagementView {
  const AdminViewSessionLogsScreen({
    required super.sessionLogs,
    required super.courses,
    required super.mentors,
    required super.selectedSessionLogId,
    required super.courseIdFilter,
    required super.mentorIdFilter,
    required super.projectTypeFilter,
    required super.canView,
    required super.isLoading,
    required super.message,
    required super.courseNameFor,
    required super.teachingMentorNamesFor,
    required super.clearMessage,
    required super.onCourseFilterChanged,
    required super.onMentorFilterChanged,
    required super.onProjectTypeFilterChanged,
    required super.onClearFilters,
    required super.onSelectSessionLog,
    required super.onView,
    required super.onHome,
    required super.onLogout,
    super.key,
  });
}
