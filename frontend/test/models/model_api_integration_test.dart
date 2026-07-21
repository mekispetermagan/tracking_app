import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/api/api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('unknown model enum response is reported as invalidData', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode([
          {
            'id': 11,
            'submitted_by_mentor_profile_id': 5,
            'course_id': 8,
            'date': '2026-07-20',
            'project_title': 'Future project',
            'project_type': 'future_type',
            'other_project_type': null,
            'games_played': null,
            'completion_status': 'completed',
            'what_worked': null,
            'challenges': null,
            'next_step': null,
            'teaching_mentor_ids': [5],
            'supporting_mentor_ids': <int>[],
            'student_ids': [7],
            'created_at': '2026-07-20T12:00:00Z',
          },
        ]),
        200,
      ),
    );

    final result = await MentorSessionLogApi(
      client: client,
    ).fetchAvailableSessionLogs(accessToken: 'token');

    expect(result.failure, MentorSessionLogFailure.invalidData);
  });
}
