import '../models/models.dart';
import '../widgets/course_management_view.dart';

class MentorCourseManagementScreen extends CourseManagementView {
  const MentorCourseManagementScreen({
    required super.courses,
    required super.selectedCourseId,
    required super.canEdit,
    required super.isLoading,
    required super.isSaving,
    required super.message,
    required super.clearMessage,
    required super.onSelectCourse,
    required super.onEdit,
    required super.onHome,
    required super.onLogout,
    super.key,
  }) : super(title: 'My courses', subtitleFor: _mentorCourseSubtitle);
}

const _dayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String _mentorCourseSubtitle(Course course) {
  final parts = course.startTime.split(':');
  final time = parts.length < 2 ? course.startTime : '${parts[0]}:${parts[1]}';

  return '${_dayNames[course.dayOfWeek]} · $time\n'
      '${course.studentIds.length} students';
}
