import '../widgets/student_management_view.dart';

class MentorStudentManagementScreen extends StudentManagementView {
  const MentorStudentManagementScreen({
    required super.students,
    required super.courses,
    required super.courseIdFilter,
    required super.selectedStudentId,
    required super.canEdit,
    required super.isLoading,
    required super.isSaving,
    required super.message,
    required super.clearMessage,
    required super.onCourseFilterChanged,
    required super.onSelectStudent,
    required super.onAdd,
    required super.onEdit,
    required super.onHome,
    required super.onLogout,
    super.key,
  });
}
