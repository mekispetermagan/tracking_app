import '../widgets/student_management_view.dart';

class AdminStudentManagementScreen extends StudentManagementView {
  const AdminStudentManagementScreen({
    required super.students,
    required super.courses,
    required super.statusFilter,
    required super.courseIdFilter,
    required super.unassignedOnly,
    required super.selectedStudentId,
    required super.canEdit,
    required super.canAssignCourses,
    required super.isLoading,
    required super.isSaving,
    required super.message,
    required super.clearMessage,
    required super.onStatusFilterChanged,
    required super.onCourseFilterChanged,
    required super.onUnassignedFilter,
    required super.onSelectStudent,
    required super.onAdd,
    required super.onEdit,
    required super.onAssignCourses,
    required super.onHome,
    required super.onLogout,
    super.key,
  });
}
