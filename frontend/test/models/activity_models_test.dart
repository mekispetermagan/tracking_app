import 'package:flutter_test/flutter_test.dart';
import 'package:agu_frontend/models/models.dart';

void main() {
  const sessionJson = <String, dynamic>{
    'id': 11,
    'submitted_by_mentor_profile_id': 5,
    'course_id': 8,
    'date': '2026-07-20',
    'project_title': 'Robot arm',
    'project_type': 'robotics',
    'other_project_type': null,
    'games_played': 'Typing',
    'completion_status': 'partly_completed',
    'what_worked': 'Teamwork',
    'challenges': null,
    'next_step': 'Finish wiring',
    'teaching_mentor_ids': [5],
    'supporting_mentor_ids': [6],
    'student_ids': [7, 9],
    'created_at': '2026-07-20T12:30:00Z',
  };

  group('Session models', () {
    test('enums map every declared API value', () {
      for (final value in ProjectType.values) {
        expect(ProjectType.fromApiValue(value.apiValue), value);
      }
      for (final value in CompletionStatus.values) {
        expect(CompletionStatus.fromApiValue(value.apiValue), value);
      }
    });

    test('SessionLog parses nested enum, date, null, and list fields', () {
      final log = SessionLog.fromJson(sessionJson);

      expect(log.id, 11);
      expect(log.submittedByMentorProfileId, 5);
      expect(log.courseId, 8);
      expect(log.date, DateTime(2026, 7, 20));
      expect(log.projectTitle, 'Robot arm');
      expect(log.projectType, ProjectType.robotics);
      expect(log.otherProjectType, isNull);
      expect(log.gamesPlayed, 'Typing');
      expect(log.completionStatus, CompletionStatus.partlyCompleted);
      expect(log.whatWorked, 'Teamwork');
      expect(log.challenges, isNull);
      expect(log.nextStep, 'Finish wiring');
      expect(log.teachingMentorIds, [5]);
      expect(log.supportingMentorIds, [6]);
      expect(log.studentIds, [7, 9]);
      expect(log.createdAt, DateTime.utc(2026, 7, 20, 12, 30));
    });

    test('SessionLogCreateRequest emits literal enum and date values', () {
      final request = SessionLogCreateRequest(
        courseId: 8,
        date: DateTime(2026, 7, 20, 18, 45),
        projectTitle: 'Robot arm',
        projectType: ProjectType.other,
        otherProjectType: 'Electronics',
        completionStatus: CompletionStatus.completed,
        teachingMentorIds: const [5],
        studentIds: const [7],
      );

      expect(request.toJson(), {
        'course_id': 8,
        'date': '2026-07-20',
        'project_title': 'Robot arm',
        'project_type': 'other',
        'other_project_type': 'Electronics',
        'games_played': null,
        'completion_status': 'completed',
        'what_worked': null,
        'challenges': null,
        'next_step': null,
        'teaching_mentor_ids': [5],
        'supporting_mentor_ids': <int>[],
        'student_ids': [7],
      });
    });

    test('SessionPhoto parses dates, identity, order, and URL', () {
      final photo = SessionPhoto.fromJson({
        'id': 30,
        'session_log_id': 11,
        'mentor_profile_id': 5,
        'mentor_name': 'Grace Hopper',
        'session_date': '2026-07-20',
        'photo_number': 2,
        'url': 'https://example.test/photo.jpg',
        'uploaded_at': '2026-07-20T13:00:00Z',
      });

      expect(photo.id, 30);
      expect(photo.sessionLogId, 11);
      expect(photo.mentorProfileId, 5);
      expect(photo.mentorName, 'Grace Hopper');
      expect(photo.sessionDate, DateTime(2026, 7, 20));
      expect(photo.photoNumber, 2);
      expect(photo.url, 'https://example.test/photo.jpg');
      expect(photo.uploadedAt, DateTime.utc(2026, 7, 20, 13));
    });
  });

  const storyJson = <String, dynamic>{
    'id': 12,
    'text': 'A student built a robot.',
    'course_id': 8,
    'course_name': 'Robotics',
    'submitted_by_mentor_profile_id': 5,
    'submitter_first_name': 'Grace',
    'submitter_last_name': 'Hopper',
    'submission_month': '2026-07-01',
    'photo': {
      'id': 31,
      'url': 'https://example.test/story.jpg',
      'uploaded_at': '2026-07-20T13:00:00Z',
    },
    'is_winner': false,
    'created_at': '2026-07-20T12:00:00Z',
    'updated_at': '2026-07-21T12:00:00Z',
  };

  group('Story models', () {
    test('Story parses common response fields and nested photo', () {
      final story = Story.fromJson(storyJson);

      expect(story.id, 12);
      expect(story.text, 'A student built a robot.');
      expect(story.courseId, 8);
      expect(story.courseName, 'Robotics');
      expect(story.submittedByMentorProfileId, 5);
      expect(story.submitterName, 'Grace Hopper');
      expect(story.submissionMonth, DateTime(2026, 7));
      expect(story.photo.id, 31);
      expect(story.photo.url, 'https://example.test/story.jpg');
      expect(story.isWinner, isFalse);
      expect(story.createdAt, DateTime.utc(2026, 7, 20, 12));
      expect(story.updatedAt, DateTime.utc(2026, 7, 21, 12));
    });

    test('MentorStory adds nullable rating and rate permission', () {
      final story = MentorStory.fromJson({
        ...storyJson,
        'my_rating': null,
        'can_rate': true,
      });

      expect(story.id, 12);
      expect(story.myRating, isNull);
      expect(story.canRate, isTrue);
    });

    test('AdminStory accepts integer average as double', () {
      final story = AdminStory.fromJson({
        ...storyJson,
        'active': true,
        'rating_count': 3,
        'average_rating': 4,
      });

      expect(story.active, isTrue);
      expect(story.ratingCount, 3);
      expect(story.averageRating, 4.0);
    });

    test('AdminStory accepts null average', () {
      final story = AdminStory.fromJson({
        ...storyJson,
        'active': true,
        'rating_count': 0,
        'average_rating': null,
      });

      expect(story.averageRating, isNull);
    });

    test('StoryWinner parses dates and nested base story', () {
      final winner = StoryWinner.fromJson({
        'month': '2026-07-01',
        'selected_at': '2026-08-01T09:00:00Z',
        'story': {...storyJson, 'is_winner': true},
      });

      expect(winner.month, DateTime(2026, 7));
      expect(winner.selectedAt, DateTime.utc(2026, 8, 1, 9));
      expect(winner.story.id, 12);
      expect(winner.story.isWinner, isTrue);
    });

    test('story request DTOs preserve literal JSON and multipart fields', () {
      expect(
        const StoryCreateRequest(
          courseId: 8,
          text: 'Story',
          photoPath: '/tmp/photo.jpg',
        ).toFields(),
        {'course_id': '8', 'text': 'Story'},
      );
      expect(const StoryUpdateRequest(text: 'Edited').toJson(), {
        'text': 'Edited',
      });
      expect(const StoryRatingRequest(rating: 4).toJson(), {'rating': 4});
      expect(const StoryWinnerRequest(storyId: 12).toJson(), {'story_id': 12});
    });
  });

  group('Student record models', () {
    test('parses scores, enum groups, projects, and skill games', () {
      final record = StudentRecord.fromJson({
        'student_id': 7,
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'attended_sessions': 5,
        'overall_activity_score': 7,
        'project_groups': [
          {
            'project_type': 'robotics',
            'completed_count': 1,
            'partly_completed_count': 1,
            'not_completed_count': 0,
            'activity_score': 3.5,
            'projects': [
              {
                'project_title': 'Robot arm',
                'date': '2026-07-20',
                'completion_status': 'completed',
              },
            ],
          },
        ],
        'skill_games': [
          {'name': 'Typing', 'practice_count': 4},
        ],
      });

      expect(record.studentId, 7);
      expect(record.fullName, 'Ada Lovelace');
      expect(record.attendedSessions, 5);
      expect(record.overallActivityScore, 7.0);
      expect(record.projectGroups.single.projectType, ProjectType.robotics);
      expect(record.projectGroups.single.activityScore, 3.5);
      expect(
        record.projectGroups.single.projects.single.date,
        DateTime(2026, 7, 20),
      );
      expect(
        record.projectGroups.single.projects.single.completionStatus,
        CompletionStatus.completed,
      );
      expect(record.skillGames.single.name, 'Typing');
      expect(record.skillGames.single.practiceCount, 4);
    });
  });
}
