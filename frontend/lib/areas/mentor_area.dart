import 'package:flutter/material.dart';

import '../controllers/controllers.dart';
import '../screens/screens.dart';

class MentorArea extends StatefulWidget {
  const MentorArea({
    required this.accessToken,
    required this.onLogout,
    super.key,
  });

  final String accessToken;
  final Future<void> Function() onLogout;

  @override
  State<MentorArea> createState() => _MentorAreaState();
}

class _MentorAreaState extends State<MentorArea> {
  final _areaController = MentorAreaController();
  final _courseController = MentorCourseManagementController();
  final _studentController = MentorStudentManagementController();
  final _profileController = MentorProfileController();
  final _sessionLogController = MentorSessionLogController();
  final _viewSessionLogsController = MentorViewSessionLogsController();
  final _photoController = SessionPhotoController();
  final _trackStudentsController = TrackStudentsController();

  bool _showSessionPhotos = false;
  bool _showCoursePhotos = false;

  bool _showChangePin = false;

  @override
  void dispose() {
    _areaController.dispose();
    _courseController.dispose();
    _studentController.dispose();
    _profileController.dispose();
    _sessionLogController.dispose();
    _viewSessionLogsController.dispose();
    _photoController.dispose();
    _trackStudentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _areaController,
        _courseController,
        _studentController,
        _profileController,
        _sessionLogController,
        _viewSessionLogsController,
        _photoController,
        _trackStudentsController,
        _trackStudentsController.recordController,
        _viewSessionLogsController.studentRecordController,
      ]),
      builder: (_, _) => _buildArea(),
    );
  }

  Widget _buildArea() {
    return PopScope(
      canPop: _areaController.screen == MentorScreen.menu,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (_areaController.screen == MentorScreen.myProfile &&
            _showChangePin) {
          setState(() {
            _showChangePin = false;
          });
          return;
        }

        if (_areaController.screen == MentorScreen.manageCourses &&
            _courseController.view == MentorCourseManagementView.form) {
          _courseController.cancelEdit();
          return;
        }

        if (_areaController.screen == MentorScreen.manageStudents &&
            _studentController.view == MentorStudentManagementView.form) {
          _studentController.cancelForm();
          return;
        }

        if (_areaController.screen == MentorScreen.viewSessionLogs &&
            _viewSessionLogsController.view ==
                MentorViewSessionLogsView.studentRecord) {
          _viewSessionLogsController.closeStudentRecord();
          return;
        }

        if (_areaController.screen == MentorScreen.trackStudents &&
            _trackStudentsController.view == TrackStudentsView.record) {
          _trackStudentsController.closeRecord();
          return;
        }

        if (_areaController.screen == MentorScreen.viewSessionLogs &&
            _showSessionPhotos) {
          _closeSessionPhotos();
          return;
        }

        if (_areaController.screen == MentorScreen.viewSessionLogs &&
            _viewSessionLogsController.view ==
                MentorViewSessionLogsView.detail) {
          _viewSessionLogsController.closeDetail();
          return;
        }

        if (_areaController.screen == MentorScreen.viewPhotos &&
            _showCoursePhotos) {
          _closeCoursePhotos();
          return;
        }

        _goHome();
      },
      child: switch (_areaController.screen) {
        MentorScreen.menu => MentorMenuScreen(
          items: _areaController.menuItems,
          onSelect: _selectScreen,
          onLogout: _logout,
        ),

        MentorScreen.myProfile => _buildProfile(),

        MentorScreen.manageCourses => _buildCourseManagement(),

        MentorScreen.manageStudents => _buildStudentManagement(),

        MentorScreen.submitSessionLog => _buildSessionLogForm(),

        MentorScreen.viewSessionLogs => _buildViewSessionLogsArea(),

        MentorScreen.viewPhotos => _buildPhotoArea(),

        MentorScreen.trackStudents => _buildTrackStudentsArea(),

        MentorScreen.submitInvoice => PlaceholderTaskScreen(
          title: 'Submit invoice',
          onHome: _goHome,
          onLogout: _logout,
        ),

        MentorScreen.storyOfTheMonth => PlaceholderTaskScreen(
          title: 'Story of the month',
          onHome: _goHome,
          onLogout: _logout,
        ),
      },
    );
  }

  Widget _buildProfile() {
    if (_showChangePin) {
      return MentorChangePinScreen(
        isChangingPin: _profileController.isChangingPin,
        message: _profileController.message,
        clearMessage: _profileController.clearMessage,
        onChangePin: (request) {
          return _profileController.changePin(
            accessToken: widget.accessToken,
            request: request,
          );
        },
        onCancel: () {
          setState(() {
            _showChangePin = false;
          });
        },
      );
    }

    return MentorProfileScreen(
      mentor: _profileController.mentor,
      countryName: _profileCountryName,
      courseNames: _profileCourseNames,
      isLoading: _profileController.isLoading,
      isSaving: _profileController.isSaving,
      message: _profileController.message,
      clearMessage: _profileController.clearMessage,
      onSave: (request) {
        return _profileController.updateProfile(
          accessToken: widget.accessToken,
          request: request,
        );
      },
      onChangePin: () {
        setState(() {
          _showChangePin = true;
        });
      },
      onReload: _openProfile,
      onHome: _goHome,
      onLogout: _logout,
    );
  }

  Widget _buildCourseManagement() {
    return switch (_courseController.view) {
      MentorCourseManagementView.list => MentorCourseManagementScreen(
        courses: _courseController.courses,
        selectedCourseId: _courseController.selectedCourseId,
        canEdit: _courseController.canEdit,
        isLoading: _courseController.isLoading,
        isSaving: _courseController.isSaving,
        message: _courseController.message,
        clearMessage: _courseController.clearMessage,
        onSelectCourse: _courseController.selectCourse,
        onEdit: _courseController.startEditSelectedCourse,
        onHome: _goHome,
        onLogout: _logout,
      ),

      MentorCourseManagementView.form => MentorCourseFormScreen(
        course: _courseController.selectedCourse!,
        isSaving: _courseController.isSaving,
        message: _courseController.message,
        clearMessage: _courseController.clearMessage,
        onSave:
            ({required description, required dayOfWeek, required startTime}) {
              return _courseController.updateCourse(
                accessToken: widget.accessToken,
                description: description,
                dayOfWeek: dayOfWeek,
                startTime: startTime,
              );
            },
        onCancel: _courseController.cancelEdit,
      ),
    };
  }

  Widget _buildStudentManagement() {
    return switch (_studentController.view) {
      MentorStudentManagementView.list => MentorStudentManagementScreen(
        students: _studentController.visibleStudents,
        courses: _studentController.courses,
        courseIdFilter: _studentController.courseIdFilter,
        selectedStudentId: _studentController.selectedStudentId,
        canEdit: _studentController.canEdit,
        isLoading: _studentController.isLoading,
        isSaving: _studentController.isSaving,
        message: _studentController.message,
        clearMessage: _studentController.clearMessage,
        onCourseFilterChanged: _studentController.setCourseIdFilter,
        onSelectStudent: _studentController.selectStudent,
        onAdd: _studentController.startAddStudent,
        onEdit: _studentController.startEditSelectedStudent,
        onHome: _goHome,
        onLogout: _logout,
      ),

      MentorStudentManagementView.form => MentorStudentFormScreen(
        student: _studentController.formStudent,
        courses: _studentController.courses,
        isSaving: _studentController.isSaving,
        message: _studentController.message,
        clearMessage: _studentController.clearMessage,
        onCreate: (request) {
          return _studentController.createStudent(
            accessToken: widget.accessToken,
            request: request,
          );
        },
        onUpdate: (studentId, request) {
          return _studentController.updateStudent(
            accessToken: widget.accessToken,
            studentId: studentId,
            request: request,
          );
        },
        onCancel: _studentController.cancelForm,
      ),
    };
  }

  Widget _buildSessionLogForm() {
    return MentorSessionLogFormScreen(
      courses: _sessionLogController.courses,
      students: _sessionLogController.students,
      mentors: _sessionLogController.mentors,
      selectedCourseId: _sessionLogController.selectedCourseId,
      selectedStudentIds: _sessionLogController.selectedStudentIds,
      selectedTeachingMentorIds:
          _sessionLogController.selectedTeachingMentorIds,
      selectedSupportingMentorIds:
          _sessionLogController.selectedSupportingMentorIds,
      isLoading: _sessionLogController.isLoading,
      isSaving: _sessionLogController.isSaving,
      message: _sessionLogController.message,
      clearMessage: _sessionLogController.clearMessage,
      onCourseSelected: (courseId) {
        return _sessionLogController.selectCourse(
          accessToken: widget.accessToken,
          courseId: courseId,
        );
      },
      onToggleStudent: _sessionLogController.toggleStudent,
      onSelectAllStudents: _sessionLogController.selectAllStudents,
      onClearStudents: _sessionLogController.clearStudentSelection,
      onToggleTeachingMentor: _sessionLogController.toggleTeachingMentor,
      onToggleSupportingMentor: _sessionLogController.toggleSupportingMentor,
      onClearMentors: _sessionLogController.clearMentorSelection,
      onSubmit: (request) {
        return _sessionLogController.submit(
          accessToken: widget.accessToken,
          request: request,
        );
      },
      onSubmitted: _finishSessionLogSubmission,
      onCancel: _goHome,
    );
  }

  Widget _buildViewSessionLogsArea() {
    final selectedSessionLog = _viewSessionLogsController.selectedSessionLog;

    if (_showSessionPhotos) {
      final sessionLog = selectedSessionLog!;
      final mentorProfileId = _profileController.mentor?.id;

      final participated =
          mentorProfileId != null &&
          (sessionLog.teachingMentorIds.contains(mentorProfileId) ||
              sessionLog.supportingMentorIds.contains(mentorProfileId));

      final alreadySubmitted =
          mentorProfileId != null &&
          _photoController.hasSubmissionForMentor(mentorProfileId);

      return SessionPhotosScreen(
        title: '${sessionLog.projectTitle} photos',
        photos: _photoController.photos,
        selectedPhotos: _photoController.selectedPhotos,
        isLoading: _photoController.isLoading,
        isSelecting: _photoController.isSelecting,
        isUploading: _photoController.isUploading,
        showUploadControls: participated,
        alreadySubmitted: alreadySubmitted,
        canUpload:
            participated && !alreadySubmitted && _photoController.canUpload,
        message: _photoController.message,
        clearMessage: _photoController.clearMessage,
        onSelectPhotos: _photoController.selectPhotos,
        onClearSelection: _photoController.clearSelection,
        onUpload: () async {
          if (mentorProfileId == null) {
            return;
          }

          await _photoController.uploadPhotos(
            accessToken: widget.accessToken,
            sessionLogId: sessionLog.id,
            mentorProfileId: mentorProfileId,
          );
        },
        onBack: _closeSessionPhotos,
      );
    }

    return switch (_viewSessionLogsController.view) {
      MentorViewSessionLogsView.list => MentorViewSessionLogsScreen(
        sessionLogs: _viewSessionLogsController.visibleSessionLogs,
        courses: _viewSessionLogsController.filterCourses,
        selectedSessionLogId: _viewSessionLogsController.selectedSessionLogId,
        courseIdFilter: _viewSessionLogsController.courseIdFilter,
        projectTypeFilter: _viewSessionLogsController.projectTypeFilter,
        canView: _viewSessionLogsController.canView,
        isLoading: _viewSessionLogsController.isLoading,
        message: _viewSessionLogsController.message,
        courseNameFor: _viewSessionLogsController.courseNameFor,
        teachingMentorNamesFor:
            _viewSessionLogsController.teachingMentorNamesFor,
        clearMessage: _viewSessionLogsController.clearMessage,
        onCourseFilterChanged: _viewSessionLogsController.setCourseIdFilter,
        onProjectTypeFilterChanged:
            _viewSessionLogsController.setProjectTypeFilter,
        onClearFilters: _viewSessionLogsController.clearFilters,
        onSelectSessionLog: _viewSessionLogsController.selectSessionLog,
        onView: _viewSessionLogsController.openSelectedSessionLog,
        onHome: _goHome,
        onLogout: _logout,
      ),

      MentorViewSessionLogsView.detail => MentorViewSessionLogScreen(
        sessionLog: selectedSessionLog!,
        courseName: _viewSessionLogsController.courseNameFor(
          selectedSessionLog,
        ),
        submittedByMentorName: _viewSessionLogsController
            .submittedByMentorNameFor(selectedSessionLog),
        teachingMentorNames: _viewSessionLogsController.teachingMentorNamesFor(
          selectedSessionLog,
        ),
        supportingMentorNames: _viewSessionLogsController
            .supportingMentorNamesFor(selectedSessionLog),
        students: _viewSessionLogsController.studentsFor(selectedSessionLog),
        onStudentSelected: (studentId) {
          _viewSessionLogsController.openStudentRecord(
            accessToken: widget.accessToken,
            studentId: studentId,
          );
        },
        onViewPhotos: _openSessionPhotos,
        onBack: _viewSessionLogsController.closeDetail,
      ),

      MentorViewSessionLogsView.studentRecord => StudentRecordScreen(
        studentRecord:
            _viewSessionLogsController.studentRecordController.studentRecord,
        isLoading: _viewSessionLogsController.studentRecordController.isLoading,
        message: _viewSessionLogsController.studentRecordController.message,
        clearMessage:
            _viewSessionLogsController.studentRecordController.clearMessage,
        onBack: _viewSessionLogsController.closeStudentRecord,
      ),
    };
  }

  Widget _buildPhotoArea() {
    if (_showCoursePhotos) {
      return CoursePhotosScreen(
        courseName: _photoController.selectedCourse!.name,
        photos: _photoController.photos,
        isLoading: _photoController.isLoading,
        message: _photoController.message,
        clearMessage: _photoController.clearMessage,
        onBack: _closeCoursePhotos,
      );
    }

    return PhotoCourseSelectionScreen(
      courses: _photoController.courses,
      selectedCourseId: _photoController.selectedCourseId,
      canView: _photoController.canViewCourse,
      isLoading: _photoController.isLoading,
      message: _photoController.message,
      clearMessage: _photoController.clearMessage,
      onSelectCourse: _photoController.selectCourse,
      onView: _openSelectedCoursePhotos,
      onHome: _goHome,
      onLogout: _logout,
    );
  }

  Widget _buildTrackStudentsArea() {
    return switch (_trackStudentsController.view) {
      TrackStudentsView.list => TrackStudentsScreen(
        students: _trackStudentsController.students,
        selectedStudentId: _trackStudentsController.selectedStudentId,
        canView: _trackStudentsController.canView,
        isLoading: _trackStudentsController.isLoading,
        message: _trackStudentsController.message,
        clearMessage: _trackStudentsController.clearMessage,
        onSelectStudent: _trackStudentsController.selectStudent,
        onView: () {
          _trackStudentsController.openSelectedStudentRecord(
            accessToken: widget.accessToken,
          );
        },
        onHome: _goHome,
        onLogout: _logout,
      ),

      TrackStudentsView.record => StudentRecordScreen(
        studentRecord: _trackStudentsController.recordController.studentRecord,
        isLoading: _trackStudentsController.recordController.isLoading,
        message: _trackStudentsController.recordController.message,
        clearMessage: _trackStudentsController.recordController.clearMessage,
        onBack: _trackStudentsController.closeRecord,
      ),
    };
  }

  Future<void> _openSessionPhotos() async {
    final sessionLog = _viewSessionLogsController.selectedSessionLog;

    if (sessionLog == null) {
      return;
    }

    setState(() {
      _showSessionPhotos = true;
    });

    await Future.wait([
      _photoController.loadSessionPhotos(
        accessToken: widget.accessToken,
        sessionLogId: sessionLog.id,
      ),
      if (_profileController.mentor == null)
        _profileController.loadProfile(accessToken: widget.accessToken),
    ]);
  }

  void _closeSessionPhotos() {
    _photoController.closeGallery();

    setState(() {
      _showSessionPhotos = false;
    });
  }

  Future<void> _openSelectedCoursePhotos() async {
    if (!_photoController.canViewCourse) {
      return;
    }

    setState(() {
      _showCoursePhotos = true;
    });

    await _photoController.loadSelectedCoursePhotos(
      accessToken: widget.accessToken,
    );
  }

  void _closeCoursePhotos() {
    _photoController.closeGallery();

    setState(() {
      _showCoursePhotos = false;
    });
  }

  void _finishSessionLogSubmission() {
    _sessionLogController.reset();
    _areaController.reset();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Session log submitted.')));
  }

  String? get _profileCountryName {
    final countryId = _profileController.mentor?.countryId;

    if (countryId == null) {
      return null;
    }

    return 'ID $countryId';
  }

  List<String> get _profileCourseNames {
    final mentor = _profileController.mentor;

    if (mentor == null) {
      return const [];
    }

    final namesById = {
      for (final course in _courseController.courses) course.id: course.name,
    };

    return mentor.courseIds
        .map((courseId) => namesById[courseId] ?? 'Course #$courseId')
        .toList();
  }

  void _selectScreen(MentorScreen screen) {
    _areaController.select(screen);

    if (screen == MentorScreen.myProfile) {
      _openProfile();
    }

    if (screen == MentorScreen.manageCourses) {
      _courseController.openList(accessToken: widget.accessToken);
    }

    if (screen == MentorScreen.manageStudents) {
      _studentController.openList(accessToken: widget.accessToken);
    }

    if (screen == MentorScreen.submitSessionLog) {
      _sessionLogController.initialize(accessToken: widget.accessToken);
    }

    if (screen == MentorScreen.viewSessionLogs) {
      _viewSessionLogsController.openList(accessToken: widget.accessToken);
    }

    if (screen == MentorScreen.viewPhotos) {
      setState(() {
        _showCoursePhotos = false;
      });

      _photoController.initializeCourseSelection(
        accessToken: widget.accessToken,
      );
    }

    if (screen == MentorScreen.trackStudents) {
      _trackStudentsController.openList(accessToken: widget.accessToken);
    }
  }

  void _openProfile() {
    _profileController.loadProfile(accessToken: widget.accessToken);
    _courseController.openList(accessToken: widget.accessToken);
  }

  void _goHome() {
    setState(() {
      _showChangePin = false;
    });

    _profileController.reset();
    _courseController.reset();
    _areaController.reset();
    _studentController.reset();
    _sessionLogController.reset();
    _viewSessionLogsController.reset();
    _photoController.reset();
    _trackStudentsController.reset();

    setState(() {
      _showSessionPhotos = false;
      _showCoursePhotos = false;
    });
  }

  Future<void> _logout() async {
    setState(() {
      _showChangePin = false;
    });

    _profileController.reset();
    _courseController.reset();
    _areaController.reset();
    _studentController.reset();
    _sessionLogController.reset();
    _viewSessionLogsController.reset();
    _photoController.reset();
    _trackStudentsController.reset();

    setState(() {
      _showSessionPhotos = false;
      _showCoursePhotos = false;
    });

    await widget.onLogout();
  }
}
