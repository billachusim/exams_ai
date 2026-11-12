import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  final int status;
  const ApiException(this.message, {this.code, this.status = 0});

  bool get isLimitReached => code == 'limit_reached';

  @override
  String toString() => message;
}

/// Calls the ExamsAi edge functions with the signed-in user's token.
class ApiClient {
  ApiClient(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> _call(String name, [Map<String, dynamic> body = const {}]) async {
    try {
      final res = await _client.functions.invoke(name, body: body);
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const ApiException('Unexpected reply from the server.');
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map) {
        throw ApiException(
          '${details['error'] ?? 'Something went wrong. Please try again.'}',
          code: details['code']?.toString(),
          status: e.status,
        );
      }
      throw ApiException('Something went wrong. Please try again.', status: e.status);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Network problem. Check your connection and try again.', code: 'network');
    }
  }

  Future<Me> me() async => Me.fromJson(await _call('me'));

  Future<String> askTutor({required String subject, required String message, required String exam}) async {
    final res = await _call('tutor-chat', {'subject': subject, 'message': message, 'exam': exam});
    return '${res['reply'] ?? ''}';
  }

  Future<List<ChatMessage>> tutorHistory(String subject) async {
    final rows = await _client
        .from('tutor_messages')
        .select('role, content, created_at')
        .eq('subject_slug', subject)
        .order('created_at', ascending: false)
        .limit(40);
    return rows.reversed.map((r) => ChatMessage('${r['role']}', '${r['content']}')).toList();
  }

  Future<QuizSession> startPractice({
    required String subject,
    String? topic,
    required int count,
    required String exam,
  }) async =>
      QuizSession.fromJson(await _call('start-practice', {
        'mode': 'practice',
        'subject': subject,
        if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
        'count': count,
        'exam': exam,
      }));

  Future<QuizSession> startMock({required List<String> subjects, required String exam}) async =>
      QuizSession.fromJson(await _call('start-practice', {'mode': 'mock', 'subjects': subjects, 'exam': exam}));

  Future<QuizResult> submitAttempt(String attemptId, Map<String, String> answers) async =>
      QuizResult.fromJson(await _call('submit-attempt', {
        'attemptId': attemptId,
        'answers': answers.entries.map((e) => {'questionId': e.key, 'chosen': e.value}).toList(),
      }));

  Future<void> reportQuestion(String questionId) =>
      _call('report-question', {'questionId': questionId, 'reason': 'student_report_app'});

  Future<List<LeaderboardRow>> leaderboard() async {
    final rows = await _client.rpc('get_leaderboard', params: {'p_limit': 20});
    if (rows is! List) return const [];
    return rows.whereType<Map>().map((r) => LeaderboardRow.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? school,
    String? phone,
    required String examTarget,
  }) async {
    await _client.from('profiles').update({
      'full_name': fullName,
      'school': (school ?? '').trim().isEmpty ? null : school!.trim(),
      'phone': (phone ?? '').trim().isEmpty ? null : phone!.trim(),
      'exam_target': examTarget,
    }).eq('id', userId);
  }

  /// Sends a store purchase to the server, which checks it with Google or
  /// Apple and grants Premium. Returns the new expiry.
  Future<DateTime?> verifyPurchase({
    required String platform,
    required String productId,
    String? purchaseToken,
    String? transactionId,
  }) async {
    final res = await _call('verify-purchase', {
      'platform': platform,
      'productId': productId,
      if (purchaseToken != null) 'purchaseToken': purchaseToken,
      if (transactionId != null) 'transactionId': transactionId,
    });
    final exp = res['expiresAt'];
    return exp == null ? null : DateTime.tryParse('$exp')?.toLocal();
  }

  Future<void> deleteAccount() => _call('delete-account');
}
