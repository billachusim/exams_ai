import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/premium/iap_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  runApp(const ProviderScope(child: ExamsAiApp()));
}

class ExamsAiApp extends ConsumerStatefulWidget {
  const ExamsAiApp({super.key});

  @override
  ConsumerState<ExamsAiApp> createState() => _ExamsAiAppState();
}

class _ExamsAiAppState extends ConsumerState<ExamsAiApp> {
  @override
  void initState() {
    super.initState();
    // Start listening for store purchases early, so a purchase that finished
    // while the app was closed is still sent to the server.
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(iapServiceProvider).init());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'ExamsAi',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
