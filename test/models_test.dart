import 'package:flutter_test/flutter_test.dart';
import 'package:examsai/data/models.dart';

void main() {
  test('parses the me response', () {
    final me = Me.fromJson({
      'user': {'id': 'u1', 'email': 'a@b.com'},
      'profile': {'id': 'u1', 'faculty_id': 'FAC-00001', 'full_name': 'Ada Obi', 'exam_target': 'WAEC'},
      'premium': {'active': false, 'plan': null, 'expiresAt': null},
      'usage': {'tutorUsed': 2, 'practiceUsed': 25, 'tutorLimit': 3, 'practiceLimit': 20},
      'progress': [
        {'subject': 'mathematics', 'name': 'Mathematics', 'answered': 10, 'correct': 6, 'accuracy': 60, 'weakTopics': []},
      ],
    });
    expect(me.displayName, 'Ada Obi');
    expect(me.examTarget, 'WAEC');
    expect(me.usage.tutorLeft, 1);
    expect(me.usage.practiceLeft, 0);
    expect(me.accuracy, 60);
  });

  test('premium users have no limits', () {
    final usage = Usage.fromJson({'tutorUsed': 50, 'practiceUsed': 0, 'tutorLimit': null, 'practiceLimit': null});
    expect(usage.tutorLeft, isNull);
  });

  test('parses a quiz session without answers', () {
    final s = QuizSession.fromJson({
      'attemptId': 'a1',
      'mode': 'mock',
      'startedAt': '2026-11-12T10:00:00Z',
      'timeLimitSeconds': 450,
      'questions': [
        {
          'id': 'q1',
          'subject': 'english',
          'stem': 'Choose the word nearest in meaning to BENEVOLENT.',
          'options': [
            {'key': 'A', 'text': 'kind'},
            {'key': 'B', 'text': 'cruel'},
          ],
        },
      ],
    });
    expect(s.questions.single.options.first.text, 'kind');
    expect(s.timeLimitSeconds, 450);
  });

  test('parses results', () {
    final r = QuizResult.fromJson({
      'score': 1,
      'total': 2,
      'late': false,
      'bySubject': [
        {'name': 'English', 'correct': 1, 'total': 2},
      ],
      'results': [],
    });
    expect(r.percent, 50);
  });
}
