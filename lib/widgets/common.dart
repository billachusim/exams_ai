import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/api.dart';

void showError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Shown when the free daily allowance is used up.
Future<void> showPaywall(BuildContext context, String message) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.workspace_premium, size: 48, color: Color(0xFF00B893)),
            const SizedBox(height: 12),
            Text("You've used today's free questions",
                textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/premium');
              },
              child: const Text('See Premium'),
            ),
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Maybe later')),
          ],
        ),
      ),
    ),
  );
}

void handleApiError(BuildContext context, Object error) {
  if (error is ApiException && error.isLimitReached) {
    showPaywall(context, error.message);
  } else {
    showError(context, error);
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off, size: 40),
            const SizedBox(height: 12),
            Text(error is ApiException ? (error as ApiException).message : "Couldn't load. Check your connection.",
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ]),
        ),
      );
}

/// Strips the light Markdown the AI sometimes adds (bold, headings).
String cleanAiText(String s) =>
    s.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!).replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
