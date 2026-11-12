import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api.dart';
import 'models.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final apiProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(supabaseProvider)));

/// Emits whenever the user signs in or out.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final sessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseProvider).auth.currentSession;
});

/// Profile, Premium, today's usage and progress. Refresh with ref.invalidate(meProvider).
final meProvider = FutureProvider<Me>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) throw const ApiException('Please sign in.', code: 'unauthenticated');
  return ref.watch(apiProvider).me();
});

final leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardRow>>((ref) {
  return ref.watch(apiProvider).leaderboard();
});

/// Lets go_router re-check its redirect when auth changes.
class AuthRefresh extends ChangeNotifier {
  AuthRefresh(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
