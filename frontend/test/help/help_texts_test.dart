import 'package:flutter_test/flutter_test.dart';
import 'package:agu_frontend/help/help_texts.dart';

void main() {
  test('every mentor view has concise built-in guidance', () {
    const texts = [
      HelpTexts.mentorLogin,
      HelpTexts.mentorSetupPin,
      HelpTexts.mentorMenu,
      HelpTexts.mentorProfile,
      HelpTexts.mentorChangePin,
      HelpTexts.mentorCourses,
      HelpTexts.mentorCourseForm,
      HelpTexts.mentorStudents,
      HelpTexts.mentorStudentForm,
      HelpTexts.mentorSessionLog,
      HelpTexts.mentorSessionLogs,
      HelpTexts.mentorSessionLogDetail,
      HelpTexts.mentorSessionPhotos,
      HelpTexts.mentorPhotoCourses,
      HelpTexts.mentorCoursePhotos,
      HelpTexts.mentorTrackStudents,
      HelpTexts.mentorStudentRecord,
      HelpTexts.mentorStories,
      HelpTexts.mentorStoryForm,
      HelpTexts.mentorStoryArchive,
      HelpTexts.mentorInvoice,
      HelpTexts.mentorCurriculum,
      HelpTexts.mentorCurriculumChapter,
    ];

    expect(texts, hasLength(23));
    expect(texts.every((text) => text.trim().isNotEmpty), isTrue);
    expect(texts.every((text) => text.length < 700), isTrue);
    expect(texts.toSet(), hasLength(texts.length));
  });
}
