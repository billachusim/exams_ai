// Plain models for the ExamsAi backend responses (see docs/BACKEND.md in
// billachusim/examsai). Parsing is defensive: unknown or missing fields fall
// back to safe defaults so a backend change can't crash the app.

int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
int? _intOrNull(dynamic v) => v == null ? null : _int(v);
String _str(dynamic v) => v == null ? '' : '$v';
String? _strOrNull(dynamic v) => v == null ? null : '$v';
List<Map<String, dynamic>> _list(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

class Profile {
  final String id;
  final String facultyId;
  final String fullName;
  final String? phone;
  final String? school;
  final String examTarget;

  const Profile({
    required this.id,
    required this.facultyId,
    required this.fullName,
    this.phone,
    this.school,
    required this.examTarget,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: _str(j['id']),
        facultyId: _str(j['faculty_id']),
        fullName: _str(j['full_name']),
        phone: _strOrNull(j['phone']),
        school: _strOrNull(j['school']),
        examTarget: _strOrNull(j['exam_target']) ?? 'JAMB',
      );
}

class PremiumStatus {
  final bool active;
  final String? plan;
  final DateTime? expiresAt;
  const PremiumStatus({required this.active, this.plan, this.expiresAt});

  factory PremiumStatus.fromJson(Map<String, dynamic> j) => PremiumStatus(
        active: j['active'] == true,
        plan: _strOrNull(j['plan']),
        expiresAt: j['expiresAt'] == null ? null : DateTime.tryParse('${j['expiresAt']}')?.toLocal(),
      );
}

class Usage {
  final int tutorUsed;
  final int practiceUsed;
  final int? tutorLimit;
  final int? practiceLimit;
  const Usage({required this.tutorUsed, required this.practiceUsed, this.tutorLimit, this.practiceLimit});

  int? get tutorLeft => tutorLimit == null ? null : (tutorLimit! - tutorUsed).clamp(0, tutorLimit!);
  int? get practiceLeft => practiceLimit == null ? null : (practiceLimit! - practiceUsed).clamp(0, practiceLimit!);

  factory Usage.fromJson(Map<String, dynamic> j) => Usage(
        tutorUsed: _int(j['tutorUsed']),
        practiceUsed: _int(j['practiceUsed']),
        tutorLimit: _intOrNull(j['tutorLimit']),
        practiceLimit: _intOrNull(j['practiceLimit']),
      );
}

class WeakTopic {
  final String topic;
  final int accuracy;
  const WeakTopic(this.topic, this.accuracy);
}

class SubjectProgress {
  final String subject;
  final String name;
  final int answered;
  final int correct;
  final int accuracy;
  final List<WeakTopic> weakTopics;
  const SubjectProgress({
    required this.subject,
    required this.name,
    required this.answered,
    required this.correct,
    required this.accuracy,
    required this.weakTopics,
  });

  factory SubjectProgress.fromJson(Map<String, dynamic> j) => SubjectProgress(
        subject: _str(j['subject']),
        name: _str(j['name']),
        answered: _int(j['answered']),
        correct: _int(j['correct']),
        accuracy: _int(j['accuracy']),
        weakTopics: _list(j['weakTopics']).map((t) => WeakTopic(_str(t['topic']), _int(t['accuracy']))).toList(),
      );
}

class Me {
  final String userId;
  final String? email;
  final Profile? profile;
  final PremiumStatus premium;
  final Usage usage;
  final List<SubjectProgress> progress;

  const Me({
    required this.userId,
    this.email,
    this.profile,
    required this.premium,
    required this.usage,
    required this.progress,
  });

  int get totalAnswered => progress.fold(0, (n, p) => n + p.answered);
  int get totalCorrect => progress.fold(0, (n, p) => n + p.correct);
  int get accuracy => totalAnswered == 0 ? 0 : (100 * totalCorrect / totalAnswered).round();
  String get examTarget => profile?.examTarget ?? 'JAMB';
  String get displayName {
    final name = profile?.fullName.trim() ?? '';
    return name.isNotEmpty ? name : (email ?? 'Student');
  }

  factory Me.fromJson(Map<String, dynamic> j) {
    final user = j['user'] is Map ? Map<String, dynamic>.from(j['user']) : <String, dynamic>{};
    return Me(
      userId: _str(user['id']),
      email: _strOrNull(user['email']),
      profile: j['profile'] is Map ? Profile.fromJson(Map<String, dynamic>.from(j['profile'])) : null,
      premium: PremiumStatus.fromJson(j['premium'] is Map ? Map<String, dynamic>.from(j['premium']) : {}),
      usage: Usage.fromJson(j['usage'] is Map ? Map<String, dynamic>.from(j['usage']) : {}),
      progress: _list(j['progress']).map(SubjectProgress.fromJson).toList(),
    );
  }
}

class QuestionOption {
  final String key;
  final String text;
  const QuestionOption(this.key, this.text);
}

List<QuestionOption> _options(dynamic v) =>
    _list(v).map((o) => QuestionOption(_str(o['key']), _str(o['text']))).toList();

class Question {
  final String id;
  final String subject;
  final String? topic;
  final String stem;
  final List<QuestionOption> options;
  const Question({required this.id, required this.subject, this.topic, required this.stem, required this.options});

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: _str(j['id']),
        subject: _str(j['subject']),
        topic: _strOrNull(j['topic']),
        stem: _str(j['stem']),
        options: _options(j['options']),
      );
}

class QuizSession {
  final String attemptId;
  final String mode;
  final DateTime startedAt;
  final int? timeLimitSeconds;
  final List<Question> questions;
  const QuizSession({
    required this.attemptId,
    required this.mode,
    required this.startedAt,
    this.timeLimitSeconds,
    required this.questions,
  });

  factory QuizSession.fromJson(Map<String, dynamic> j) => QuizSession(
        attemptId: _str(j['attemptId']),
        mode: _str(j['mode']),
        startedAt: DateTime.tryParse(_str(j['startedAt']))?.toLocal() ?? DateTime.now(),
        timeLimitSeconds: _intOrNull(j['timeLimitSeconds']),
        questions: _list(j['questions']).map(Question.fromJson).toList(),
      );
}

class QuestionResult {
  final String questionId;
  final String subject;
  final String stem;
  final List<QuestionOption> options;
  final String? chosen;
  final String answer;
  final bool isCorrect;
  final String explanation;
  const QuestionResult({
    required this.questionId,
    required this.subject,
    required this.stem,
    required this.options,
    this.chosen,
    required this.answer,
    required this.isCorrect,
    required this.explanation,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> j) => QuestionResult(
        questionId: _str(j['questionId']),
        subject: _str(j['subject']),
        stem: _str(j['stem']),
        options: _options(j['options']),
        chosen: _strOrNull(j['chosen']),
        answer: _str(j['answer']),
        isCorrect: j['isCorrect'] == true,
        explanation: _str(j['explanation']),
      );
}

class SubjectScore {
  final String name;
  final int correct;
  final int total;
  const SubjectScore(this.name, this.correct, this.total);
}

class QuizResult {
  final int score;
  final int total;
  final bool late;
  final List<SubjectScore> bySubject;
  final List<QuestionResult> results;
  const QuizResult({
    required this.score,
    required this.total,
    required this.late,
    required this.bySubject,
    required this.results,
  });

  int get percent => total == 0 ? 0 : (100 * score / total).round();

  factory QuizResult.fromJson(Map<String, dynamic> j) => QuizResult(
        score: _int(j['score']),
        total: _int(j['total']),
        late: j['late'] == true,
        bySubject: _list(j['bySubject']).map((s) => SubjectScore(_str(s['name']), _int(s['correct']), _int(s['total']))).toList(),
        results: _list(j['results']).map(QuestionResult.fromJson).toList(),
      );
}

class LeaderboardRow {
  final int rank;
  final String firstName;
  final String school;
  final int correct;
  final int answered;
  final int accuracy;
  final bool isMe;
  const LeaderboardRow({
    required this.rank,
    required this.firstName,
    required this.school,
    required this.correct,
    required this.answered,
    required this.accuracy,
    required this.isMe,
  });

  factory LeaderboardRow.fromJson(Map<String, dynamic> j) => LeaderboardRow(
        rank: _int(j['rank']),
        firstName: _str(j['first_name']),
        school: _str(j['school']),
        correct: _int(j['correct']),
        answered: _int(j['answered']),
        accuracy: _int(j['accuracy']),
        isMe: j['is_me'] == true,
      );
}

class ChatMessage {
  final String role; // user | assistant
  final String content;
  const ChatMessage(this.role, this.content);
}
