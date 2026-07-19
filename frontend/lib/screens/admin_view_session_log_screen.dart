import '../widgets/session_log_detail_view.dart';

class AdminViewSessionLogScreen extends SessionLogDetailView {
  const AdminViewSessionLogScreen({
    required super.sessionLog,
    required super.courseName,
    required super.submittedByMentorName,
    required super.teachingMentorNames,
    required super.supportingMentorNames,
    required super.students,
    required super.onStudentSelected,
    required super.onViewPhotos,
    required super.onBack,
    super.key,
  }) : super(photoButtonLabel: 'View photos');
}
