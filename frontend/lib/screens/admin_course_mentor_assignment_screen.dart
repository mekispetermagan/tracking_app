import '../controllers/management_types.dart';
import '../models/models.dart';
import '../widgets/assignment_management_view.dart';

class AdminCourseMentorAssignmentScreen
    extends AssignmentManagementView<Course, Mentor, ActiveStatusFilter> {
  const AdminCourseMentorAssignmentScreen({
    required Course? course,
    required List<Mentor> mentors,
    required Set<int> assignedMentorIds,
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
         title: 'Assign mentors',
         subject: course,
         subjectIdFor: _courseId,
         subjectNameFor: _courseName,
         items: mentors,
         assignedItemIds: assignedMentorIds,
         activeFilter: ActiveStatusFilter.active,
         allFilter: ActiveStatusFilter.all,
         inactiveFilter: ActiveStatusFilter.inactive,
         emptyMessage: 'No mentors',
         idFor: _mentorId,
         titleFor: _mentorTitle,
         subtitleFor: _mentorSubtitle,
         isActiveFor: _mentorIsActive,
       );

  Course? get course => subject;
  List<Mentor> get mentors => items;
  Set<int> get assignedMentorIds => assignedItemIds;
}

int _mentorId(Mentor mentor) => mentor.id;
String _mentorTitle(Mentor mentor) => mentor.fullName;
String _mentorSubtitle(Mentor mentor) => mentor.phone;
bool _mentorIsActive(Mentor mentor) => mentor.active;
int _courseId(Course course) => course.id;
String _courseName(Course course) => course.name;
