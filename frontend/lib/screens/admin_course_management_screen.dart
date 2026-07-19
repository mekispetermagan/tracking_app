import '../models/models.dart';
import '../widgets/course_management_view.dart';

class AdminCourseManagementScreen extends CourseManagementView {
  const AdminCourseManagementScreen({
    required super.courses,
    required super.statusFilter,
    required super.selectedCourseId,
    required super.canEdit,
    required super.canAssignMentors,
    required super.isLoading,
    required super.isSaving,
    required super.message,
    required super.clearMessage,
    required super.onStatusFilterChanged,
    required super.onSelectCourse,
    required super.onAdd,
    required super.onEdit,
    required super.onAssignMentors,
    required super.onHome,
    required super.onLogout,
    super.key,
  }) : super(title: 'Manage courses', subtitleFor: _adminCourseSubtitle);
}

String _adminCourseSubtitle(Course course) {
  return '${course.mentorIds.length} mentors · '
      '${course.studentIds.length} students';
}
