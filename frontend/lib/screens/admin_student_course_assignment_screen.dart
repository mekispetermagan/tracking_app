import '../controllers/admin_student_management_controller.dart'
    show StudentCourseStatusFilter;
import '../models/models.dart';
import '../widgets/assignment_management_view.dart';

class AdminStudentCourseAssignmentScreen
    extends
        AssignmentManagementView<Student, Course, StudentCourseStatusFilter> {
  const AdminStudentCourseAssignmentScreen({
    required Student? student,
    required List<Course> courses,
    required Set<int> assignedCourseIds,
    required super.statusFilter,
    required super.isLoading,
    required super.isSaving,
    required super.message,
    required super.clearMessage,
    required super.onStatusFilterChanged,
    required super.onAssignmentChanged,
    required super.onSave,
    required super.onCancel,
    super.key,
  }) : super(
         title: 'Assign courses',
         subject: student,
         subjectIdFor: _studentId,
         subjectNameFor: _studentName,
         items: courses,
         assignedItemIds: assignedCourseIds,
         activeFilter: StudentCourseStatusFilter.active,
         allFilter: StudentCourseStatusFilter.all,
         inactiveFilter: StudentCourseStatusFilter.inactive,
         emptyMessage: 'No courses',
         idFor: _courseId,
         titleFor: _courseTitle,
         subtitleFor: _courseSubtitle,
         isActiveFor: _courseIsActive,
       );

  Student? get student => subject;
  List<Course> get courses => items;
  Set<int> get assignedCourseIds => assignedItemIds;
}

int _courseId(Course course) => course.id;
String _courseTitle(Course course) => course.name;
String _courseSubtitle(Course course) {
  return '${course.mentorIds.length} mentors · '
      '${course.studentIds.length} students';
}

bool _courseIsActive(Course course) => course.active;
int _studentId(Student student) => student.id;
String _studentName(Student student) => student.fullName;
