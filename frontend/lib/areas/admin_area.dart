import 'package:flutter/material.dart';

import '../controllers/controllers.dart';
import '../models/models.dart';
import '../screens/screens.dart';
import '../theme/app_theme.dart';

class AdminArea extends StatefulWidget {
  const AdminArea({
    required this.accessToken,
    required this.onLogout,
    super.key,
  });

  final String accessToken;
  final Future<void> Function() onLogout;

  @override
  State<AdminArea> createState() => _AdminAreaState();
}

class _AdminAreaState extends State<AdminArea> {
  final _areaController = AdminAreaController();
  final _mentorManagementController = AdminMentorManagementController();
  final _courseManagementController = AdminCourseManagementController();
  final _studentManagementController = AdminStudentManagementController();
  final _viewSessionLogsController = AdminViewSessionLogsController();
  final _photoController = SessionPhotoController();
  final _trackStudentsController = TrackStudentsController();
  final _storyController = AdminStoryController();
  final _storyWinnerArchiveController = StoryWinnerArchiveController();
  final _courseVisitController = AdminCourseVisitController();

  CoursePhotoAreaView _coursePhotoView = CoursePhotoAreaView.courseSelection;

  AdminStory? get _selectedStory {
    final storyId = _areaController.selectedStoryId;

    if (storyId == null) {
      return null;
    }

    for (final story in _storyController.stories) {
      if (story.id == storyId) {
        return story;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _areaController.dispose();
    _mentorManagementController.dispose();
    _courseManagementController.dispose();
    _studentManagementController.dispose();
    _viewSessionLogsController.dispose();
    _photoController.dispose();
    _trackStudentsController.dispose();
    _storyController.dispose();
    _storyWinnerArchiveController.dispose();
    _courseVisitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildAdminTheme(),
      child: ListenableBuilder(
        listenable: Listenable.merge([
          _areaController,
          _mentorManagementController,
          _courseManagementController,
          _studentManagementController,
          _viewSessionLogsController,
          _photoController,
          _trackStudentsController,
          _trackStudentsController.recordController,
          _viewSessionLogsController.studentRecordController,
          _storyController,
          _storyWinnerArchiveController,
          _courseVisitController,
        ]),
        builder: (_, _) => _buildArea(),
      ),
    );
  }

  Widget _buildArea() {
    return PopScope(
      canPop: _areaController.screen == AdminScreen.menu,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (_areaController.screen == AdminScreen.manageMentors &&
            _mentorManagementController.view ==
                AdminMentorManagementView.form) {
          _mentorManagementController.cancelTaskScreen();
          return;
        }

        if (_areaController.screen == AdminScreen.manageCourses &&
            _courseManagementController.view !=
                AdminCourseManagementView.list) {
          _courseManagementController.cancelTaskScreen();
          return;
        }

        if (_areaController.screen == AdminScreen.manageStudents &&
            _studentManagementController.view !=
                AdminStudentManagementView.list) {
          _studentManagementController.cancelTaskScreen();
          return;
        }

        if (_areaController.screen == AdminScreen.viewSessionLogs &&
            _viewSessionLogsController.view == SessionLogAreaView.photos) {
          _closeSessionPhotos();
          return;
        }

        if (_areaController.screen == AdminScreen.viewSessionLogs &&
            _viewSessionLogsController.view ==
                SessionLogAreaView.studentRecord) {
          _viewSessionLogsController.closeStudentRecord();
          return;
        }

        if (_areaController.screen == AdminScreen.viewSessionLogs &&
            _viewSessionLogsController.view == SessionLogAreaView.detail) {
          _viewSessionLogsController.closeDetail();
          return;
        }

        if (_areaController.screen == AdminScreen.trackStudents &&
            _trackStudentsController.view == TrackStudentsView.record) {
          _trackStudentsController.closeRecord();
          return;
        }
        if (_areaController.screen == AdminScreen.viewPhotos &&
            _coursePhotoView == CoursePhotoAreaView.courseGallery) {
          _closeCoursePhotos();
          return;
        }

        if (_areaController.screen == AdminScreen.editStory) {
          _areaController.closeStoryEdit();
          return;
        }

        if (_areaController.screen == AdminScreen.storyWinnerArchive) {
          _areaController.closeStoryWinnerArchive();
          return;
        }

        if (_areaController.screen == AdminScreen.courseVisitForm) {
          _areaController.closeCourseVisitForm();
          return;
        }

        if (_areaController.screen != AdminScreen.menu) {
          _returnToMenu();
        }
      },
      child: switch (_areaController.screen) {
        AdminScreen.menu => AdminMenuScreen(
          items: _areaController.menuItems,
          onSelect: _selectScreen,
          onLogout: widget.onLogout,
        ),

        AdminScreen.manageMentors => _buildMentorManagementArea(),

        AdminScreen.manageCourses => _buildCourseManagementArea(),

        AdminScreen.manageStudents => _buildStudentManagementArea(),

        AdminScreen.viewSessionLogs => _buildViewSessionLogsArea(),

        AdminScreen.viewPhotos => _buildPhotoArea(),

        AdminScreen.trackStudents => _buildTrackStudentsArea(),

        AdminScreen.stories => _buildStoriesArea(),

        AdminScreen.editStory => _buildStoryEditArea(),

        AdminScreen.storyWinnerArchive => _buildStoryWinnerArchive(),

        AdminScreen.courseVisits => _buildCourseVisitsArea(),

        AdminScreen.courseVisitForm => _buildCourseVisitFormArea(),

        AdminScreen.reportsData => PlaceholderTaskScreen(
          title: 'Reports & data',
          onHome: _returnToMenu,
          onLogout: widget.onLogout,
        ),
      },
    );
  }

  Widget _buildMentorManagementArea() {
    return switch (_mentorManagementController.view) {
      AdminMentorManagementView.list => AdminMentorManagementScreen(
        mentors: _mentorManagementController.visibleMentors,
        statusFilter: _mentorManagementController.statusFilter,
        selectedMentorId: _mentorManagementController.selectedMentorId,
        canEdit: _mentorManagementController.canEdit,
        isLoading: _mentorManagementController.isLoading,
        isSaving: _mentorManagementController.isSaving,
        message: _mentorManagementController.message,
        clearMessage: _mentorManagementController.clearMessage,
        onStatusFilterChanged: _setMentorStatusFilter,
        onSelectMentor: _mentorManagementController.selectMentor,
        onAdd: _mentorManagementController.startAddMentor,
        onEdit: _mentorManagementController.startEditSelectedMentor,
        onResetPin: _mentorManagementController.startResetPin,
        onHome: _returnToMenu,
        onLogout: widget.onLogout,
      ),

      AdminMentorManagementView.form => AdminMentorFormScreen(
        mentor: _mentorManagementController.formMentor,
        isSaving: _mentorManagementController.isSaving,
        message: _mentorManagementController.message,
        clearMessage: _mentorManagementController.clearMessage,
        onCreate: _createMentor,
        onUpdate: _updateMentor,
        onCancel: _mentorManagementController.cancelTaskScreen,
      ),

      AdminMentorManagementView.resetPin => AdminMentorResetPinScreen(
        mentor: _mentorManagementController.selectedMentor,
        isSaving: _mentorManagementController.isSaving,
        message: _mentorManagementController.message,
        clearMessage: _mentorManagementController.clearMessage,
        onResetPin: _resetMentorPin,
        onCancel: _mentorManagementController.cancelTaskScreen,
      ),
    };
  }

  Widget _buildCourseManagementArea() {
    return switch (_courseManagementController.view) {
      AdminCourseManagementView.list => AdminCourseManagementScreen(
        courses: _courseManagementController.visibleCourses,
        statusFilter: _courseManagementController.statusFilter,
        selectedCourseId: _courseManagementController.selectedCourseId,
        canEdit: _courseManagementController.canEdit,
        canAssignMentors: _courseManagementController.canAssignMentors,
        isLoading: _courseManagementController.isLoading,
        isSaving: _courseManagementController.isSaving,
        message: _courseManagementController.message,
        clearMessage: _courseManagementController.clearMessage,
        onStatusFilterChanged: _setCourseStatusFilter,
        onSelectCourse: _courseManagementController.selectCourse,
        onAdd: _courseManagementController.startAddCourse,
        onEdit: _courseManagementController.startEditSelectedCourse,
        onAssignMentors: _startCourseMentorAssignment,
        onHome: _returnToMenu,
        onLogout: widget.onLogout,
      ),

      AdminCourseManagementView.form => AdminCourseFormScreen(
        course: _courseManagementController.formCourse,
        isSaving: _courseManagementController.isSaving,
        message: _courseManagementController.message,
        clearMessage: _courseManagementController.clearMessage,
        onCreate: _createCourse,
        onUpdate: _updateCourse,
        onCancel: _courseManagementController.cancelTaskScreen,
      ),

      AdminCourseManagementView.assignMentors =>
        AdminCourseMentorAssignmentScreen(
          course: _courseManagementController.selectedCourse,
          mentors: _courseManagementController.visibleMentors,
          assignedMentorIds: _courseManagementController.assignedMentorIds,
          statusFilter: _courseManagementController.mentorStatusFilter,
          isLoading: _courseManagementController.isLoading,
          isSaving: _courseManagementController.isSaving,
          message: _courseManagementController.message,
          clearMessage: _courseManagementController.clearMessage,
          onStatusFilterChanged: _setCourseMentorStatusFilter,
          onAssignmentChanged: (mentorId, assigned) {
            _courseManagementController.setMentorAssigned(
              mentorId: mentorId,
              assigned: assigned,
            );
          },
          onSave: _saveCourseMentorAssignments,
          onCancel: _courseManagementController.cancelTaskScreen,
        ),
    };
  }

  Widget _buildStudentManagementArea() {
    return switch (_studentManagementController.view) {
      AdminStudentManagementView.list => AdminStudentManagementScreen(
        students: _studentManagementController.visibleStudents,
        courses: _studentManagementController.courses,
        statusFilter: _studentManagementController.statusFilter,
        courseIdFilter: _studentManagementController.courseIdFilter,
        unassignedOnly: _studentManagementController.unassignedOnly,
        selectedStudentId: _studentManagementController.selectedStudentId,
        canEdit: _studentManagementController.canEdit,
        canAssignCourses: _studentManagementController.canAssignCourses,
        isLoading: _studentManagementController.isLoading,
        isSaving: _studentManagementController.isSaving,
        message: _studentManagementController.message,
        clearMessage: _studentManagementController.clearMessage,
        onStatusFilterChanged: _studentManagementController.setStatusFilter,
        onCourseFilterChanged: _studentManagementController.setCourseIdFilter,
        onUnassignedFilter: _studentManagementController.setUnassignedFilter,
        onSelectStudent: _studentManagementController.selectStudent,
        onAdd: _studentManagementController.startAddStudent,
        onEdit: _studentManagementController.startEditSelectedStudent,
        onAssignCourses: _startStudentCourseAssignment,
        onHome: _returnToMenu,
        onLogout: widget.onLogout,
      ),

      AdminStudentManagementView.form => AdminStudentFormScreen(
        student: _studentManagementController.formStudent,
        isSaving: _studentManagementController.isSaving,
        message: _studentManagementController.message,
        clearMessage: _studentManagementController.clearMessage,
        onCreate: _createStudent,
        onUpdate: _updateStudent,
        onCancel: _studentManagementController.cancelTaskScreen,
      ),

      AdminStudentManagementView.assignCourses =>
        AdminStudentCourseAssignmentScreen(
          student: _studentManagementController.selectedStudent,
          courses: _studentManagementController.visibleCourses,
          assignedCourseIds: _studentManagementController.assignedCourseIds,
          statusFilter: _studentManagementController.courseStatusFilter,
          isLoading: _studentManagementController.isLoading,
          isSaving: _studentManagementController.isSaving,
          message: _studentManagementController.message,
          clearMessage: _studentManagementController.clearMessage,
          onStatusFilterChanged: _setStudentCourseStatusFilter,
          onAssignmentChanged: (courseId, assigned) {
            _studentManagementController.setCourseAssigned(
              courseId: courseId,
              assigned: assigned,
            );
          },
          onSave: _saveStudentCourseAssignments,
          onCancel: _studentManagementController.cancelTaskScreen,
        ),
    };
  }

  Widget _buildViewSessionLogsArea() {
    final selectedSessionLog = _viewSessionLogsController.selectedSessionLog;

    if (_viewSessionLogsController.view == SessionLogAreaView.photos) {
      return SessionPhotosScreen(
        title: '${selectedSessionLog!.projectTitle} photos',
        photos: _photoController.photos,
        selectedPhotos: const [],
        isLoading: _photoController.isLoading,
        isSelecting: false,
        isUploading: false,
        showUploadControls: false,
        alreadySubmitted: false,
        canUpload: false,
        message: _photoController.message,
        clearMessage: _photoController.clearMessage,
        onSelectPhotos: () async {},
        onClearSelection: () {},
        onUpload: () async {},
        onBack: _closeSessionPhotos,
      );
    }

    return switch (_viewSessionLogsController.view) {
      SessionLogAreaView.list => AdminViewSessionLogsScreen(
        sessionLogs: _viewSessionLogsController.visibleSessionLogs,
        courses: _viewSessionLogsController.filterCourses,
        mentors: _viewSessionLogsController.filterMentors,
        selectedSessionLogId: _viewSessionLogsController.selectedSessionLogId,
        courseIdFilter: _viewSessionLogsController.courseIdFilter,
        mentorIdFilter: _viewSessionLogsController.mentorIdFilter,
        projectTypeFilter: _viewSessionLogsController.projectTypeFilter,
        canView: _viewSessionLogsController.canView,
        isLoading: _viewSessionLogsController.isLoading,
        message: _viewSessionLogsController.message,
        courseNameFor: _viewSessionLogsController.courseNameFor,
        teachingMentorNamesFor:
            _viewSessionLogsController.teachingMentorNamesFor,
        clearMessage: _viewSessionLogsController.clearMessage,
        onCourseFilterChanged: _viewSessionLogsController.setCourseIdFilter,
        onMentorFilterChanged: _viewSessionLogsController.setMentorIdFilter,
        onProjectTypeFilterChanged:
            _viewSessionLogsController.setProjectTypeFilter,
        onClearFilters: _viewSessionLogsController.clearFilters,
        onSelectSessionLog: _viewSessionLogsController.selectSessionLog,
        onView: _viewSessionLogsController.openSelectedSessionLog,
        onHome: _returnToMenu,
        onLogout: widget.onLogout,
      ),

      SessionLogAreaView.detail => AdminViewSessionLogScreen(
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

      SessionLogAreaView.studentRecord => StudentRecordScreen(
        studentRecord:
            _viewSessionLogsController.studentRecordController.studentRecord,
        isLoading: _viewSessionLogsController.studentRecordController.isLoading,
        message: _viewSessionLogsController.studentRecordController.message,
        clearMessage:
            _viewSessionLogsController.studentRecordController.clearMessage,
        onBack: _viewSessionLogsController.closeStudentRecord,
      ),

      SessionLogAreaView.photos => const SizedBox.shrink(),
    };
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
        onHome: _returnToMenu,
        onLogout: widget.onLogout,
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

  Widget _buildStoriesArea() {
    return AdminStoriesScreen(
      stories: _storyController.stories,
      selectedMonth: _storyController.selectedMonth,
      activeOnly: _storyController.activeOnly,
      isLoading: _storyController.isLoading,
      savingStoryId: _storyController.savingStoryId,
      isSelectingWinner: _storyController.isSelectingWinner,
      message: _storyController.message,
      clearMessage: _storyController.clearMessage,
      onMonthChanged: (month) {
        return _storyController.loadMonth(
          accessToken: widget.accessToken,
          month: month,
        );
      },
      onActiveOnlyChanged: (value) {
        return _storyController.setActiveOnly(
          accessToken: widget.accessToken,
          value: value,
        );
      },
      onEditStory: (story) {
        _areaController.openStoryEdit(story.id);
      },
      onDeactivateStory: (storyId) {
        return _storyController.deactivateStory(
          accessToken: widget.accessToken,
          storyId: storyId,
        );
      },
      onActivateStory: (storyId) {
        return _storyController.activateStory(
          accessToken: widget.accessToken,
          storyId: storyId,
        );
      },
      onSelectWinner: (storyId) {
        return _storyController.selectWinner(
          accessToken: widget.accessToken,
          storyId: storyId,
        );
      },
      onViewWinners: _openStoryWinnerArchive,
      onBack: _returnToMenu,
    );
  }

  Widget _buildStoryEditArea() {
    final story = _selectedStory;

    if (story == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit story'),
          leading: BackButton(onPressed: _areaController.closeStoryEdit),
        ),
        body: const Center(child: Text('Story not found.')),
      );
    }

    return AdminStoryEditScreen(
      story: story,
      isSaving: _storyController.savingStoryId == story.id,
      message: _storyController.message,
      clearMessage: _storyController.clearMessage,
      onSave: (text) {
        return _storyController.updateStory(
          accessToken: widget.accessToken,
          storyId: story.id,
          text: text,
        );
      },
      onSaved: _finishStoryEdit,
      onCancel: _areaController.closeStoryEdit,
    );
  }

  Widget _buildStoryWinnerArchive() {
    return StoryWinnerArchiveScreen(
      winners: _storyWinnerArchiveController.winners,
      isLoading: _storyWinnerArchiveController.isLoading,
      message: _storyWinnerArchiveController.message,
      clearMessage: _storyWinnerArchiveController.clearMessage,
      onBack: _areaController.closeStoryWinnerArchive,
    );
  }

  Widget _buildCourseVisitsArea() {
    return AdminCourseVisitsScreen(
      reports: _courseVisitController.filteredReports,
      courses: _courseVisitController.filterCourses,
      selectedCourseId: _courseVisitController.selectedCourseId,
      expandedReportId: _courseVisitController.expandedReportId,
      isLoading: _courseVisitController.isLoading,
      message: _courseVisitController.message,
      courseNameFor: _courseVisitController.courseNameFor,
      mentorNameFor: _courseVisitController.mentorNameFor,
      studentNameFor: _courseVisitController.studentNameFor,
      clearMessage: _courseVisitController.clearMessage,
      onCourseFilterChanged: _courseVisitController.setCourseFilter,
      onToggleReport: _courseVisitController.toggleReport,
      onRefresh: () {
        return _courseVisitController.refresh(accessToken: widget.accessToken);
      },
      onSubmitReport: _areaController.openCourseVisitForm,
      onHome: _returnToMenu,
      onLogout: widget.onLogout,
    );
  }

  Widget _buildCourseVisitFormArea() {
    return AdminCourseVisitFormScreen(
      courses: _courseVisitController.activeCourses,
      mentors: _courseVisitController.activeMentors,
      students: _courseVisitController.activeStudents,
      initialCourseId: _courseVisitController.formInitialCourseId,
      isLoading: _courseVisitController.isLoading,
      isSaving: _courseVisitController.isSubmitting,
      message: _courseVisitController.message,
      clearMessage: _courseVisitController.clearMessage,
      onSubmit: (request) {
        return _courseVisitController.submitReport(
          accessToken: widget.accessToken,
          request: request,
        );
      },
      onSubmitted: _finishCourseVisitSubmission,
      onCancel: _areaController.closeCourseVisitForm,
    );
  }

  Future<void> _selectScreen(AdminScreen screen) async {
    _areaController.select(screen);

    if (screen == AdminScreen.manageMentors) {
      await _mentorManagementController.openList(
        accessToken: widget.accessToken,
      );
    }

    if (screen == AdminScreen.manageCourses) {
      await _courseManagementController.openList(
        accessToken: widget.accessToken,
      );
    }

    if (screen == AdminScreen.manageStudents) {
      await _studentManagementController.openList(
        accessToken: widget.accessToken,
      );
    }

    if (screen == AdminScreen.viewSessionLogs) {
      await _viewSessionLogsController.openList(
        accessToken: widget.accessToken,
      );
    }

    if (screen == AdminScreen.viewPhotos) {
      setState(() {
        _coursePhotoView = CoursePhotoAreaView.courseSelection;
      });

      await _photoController.initializeCourseSelection(
        accessToken: widget.accessToken,
      );
    }

    if (screen == AdminScreen.trackStudents) {
      await _trackStudentsController.openList(accessToken: widget.accessToken);
    }

    if (screen == AdminScreen.stories) {
      await _storyController.initialize(accessToken: widget.accessToken);
    }

    if (screen == AdminScreen.courseVisits) {
      await _courseVisitController.initialize(accessToken: widget.accessToken);
    }
  }

  Future<void> _setMentorStatusFilter(MentorStatusFilter statusFilter) async {
    await _mentorManagementController.setStatusFilter(
      value: statusFilter,
      accessToken: widget.accessToken,
    );
  }

  Future<bool> _createMentor(MentorCreateRequest request) {
    return _mentorManagementController.createMentor(
      accessToken: widget.accessToken,
      request: request,
    );
  }

  Future<bool> _updateMentor(int mentorId, MentorUpdateRequest request) {
    return _mentorManagementController.updateMentor(
      accessToken: widget.accessToken,
      mentorId: mentorId,
      request: request,
    );
  }

  Future<bool> _resetMentorPin(MentorResetPinRequest request) {
    return _mentorManagementController.resetSelectedMentorPin(
      accessToken: widget.accessToken,
      request: request,
    );
  }

  Future<void> _setCourseStatusFilter(CourseStatusFilter statusFilter) async {
    await _courseManagementController.setStatusFilter(
      value: statusFilter,
      accessToken: widget.accessToken,
    );
  }

  Future<void> _startCourseMentorAssignment() async {
    await _courseManagementController.startAssignMentors(
      accessToken: widget.accessToken,
    );
  }

  Future<void> _setCourseMentorStatusFilter(
    CourseMentorStatusFilter statusFilter,
  ) async {
    await _courseManagementController.setMentorStatusFilter(
      value: statusFilter,
      accessToken: widget.accessToken,
    );
  }

  Future<bool> _createCourse(CourseCreateRequest request) {
    return _courseManagementController.createCourse(
      accessToken: widget.accessToken,
      request: request,
    );
  }

  Future<bool> _updateCourse(int courseId, CourseUpdateRequest request) {
    return _courseManagementController.updateCourse(
      accessToken: widget.accessToken,
      courseId: courseId,
      request: request,
    );
  }

  Future<bool> _saveCourseMentorAssignments() {
    return _courseManagementController.saveMentorAssignments(
      accessToken: widget.accessToken,
    );
  }

  Future<void> _startStudentCourseAssignment() async {
    await _studentManagementController.startAssignCourses(
      accessToken: widget.accessToken,
    );
  }

  Future<void> _setStudentCourseStatusFilter(
    StudentCourseStatusFilter statusFilter,
  ) async {
    await _studentManagementController.setCourseStatusFilter(
      value: statusFilter,
      accessToken: widget.accessToken,
    );
  }

  Future<bool> _createStudent(StudentCreateRequest request) {
    return _studentManagementController.createStudent(
      accessToken: widget.accessToken,
      request: request,
    );
  }

  Future<bool> _updateStudent(int studentId, StudentUpdateRequest request) {
    return _studentManagementController.updateStudent(
      accessToken: widget.accessToken,
      studentId: studentId,
      request: request,
    );
  }

  Future<bool> _saveStudentCourseAssignments() async {
    final success = await _studentManagementController.saveCourseAssignments(
      accessToken: widget.accessToken,
    );

    if (!success) {
      return false;
    }

    await _studentManagementController.loadCourses(
      accessToken: widget.accessToken,
    );

    return true;
  }

  Widget _buildPhotoArea() {
    if (_coursePhotoView == CoursePhotoAreaView.courseGallery) {
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
      onHome: _returnToMenu,
      onLogout: widget.onLogout,
    );
  }

  Future<void> _openSessionPhotos() async {
    final sessionLog = _viewSessionLogsController.selectedSessionLog;

    if (sessionLog == null) {
      return;
    }

    _viewSessionLogsController.openPhotos();

    await _photoController.loadSessionPhotos(
      accessToken: widget.accessToken,
      sessionLogId: sessionLog.id,
    );
  }

  void _closeSessionPhotos() {
    _photoController.closeGallery();

    _viewSessionLogsController.closePhotos();
  }

  Future<void> _openSelectedCoursePhotos() async {
    if (!_photoController.canViewCourse) {
      return;
    }

    setState(() {
      _coursePhotoView = CoursePhotoAreaView.courseGallery;
    });

    await _photoController.loadSelectedCoursePhotos(
      accessToken: widget.accessToken,
    );
  }

  void _closeCoursePhotos() {
    _photoController.closeGallery();

    setState(() {
      _coursePhotoView = CoursePhotoAreaView.courseSelection;
    });
  }

  void _finishStoryEdit() {
    _areaController.closeStoryEdit();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Story updated.')));
  }

  void _openStoryWinnerArchive() {
    _areaController.openStoryWinnerArchive();

    _storyWinnerArchiveController.load(accessToken: widget.accessToken);
  }

  void _returnToMenu() {
    _mentorManagementController.cancelTaskScreen();
    _courseManagementController.cancelTaskScreen();
    _studentManagementController.cancelTaskScreen();
    _viewSessionLogsController.reset();
    _areaController.reset();
    _photoController.reset();
    _trackStudentsController.reset();
    _storyController.reset();
    _storyWinnerArchiveController.reset();
    _courseVisitController.reset();

    setState(() {
      _coursePhotoView = CoursePhotoAreaView.courseSelection;
    });
  }

  void _finishCourseVisitSubmission() {
    _areaController.closeCourseVisitForm();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Course visit report submitted.')),
      );
  }
}
