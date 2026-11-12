import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Progress'),
          bottom: const TabBar(tabs: [Tab(text: 'My subjects'), Tab(text: 'Leaderboard')]),
        ),
        body: const TabBarView(children: [_MyProgress(), _Leaderboard()]),
      ),
    );
  }
}

class _MyProgress extends ConsumerWidget {
  const _MyProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return me.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(meProvider)),
      data: (me) {
        if (me.progress.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.insights, size: 48, color: AppTheme.primary),
                const SizedBox(height: 12),
                const Text('No practice yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 4),
                const Text('Answer some questions to see your scores and weak topics here.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => context.go('/practice'), child: const Text('Start practising')),
              ]),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(meProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(child: _Stat(label: 'Answered', value: '${me.totalAnswered}')),
                const SizedBox(width: 12),
                Expanded(child: _Stat(label: 'Accuracy', value: '${me.accuracy}%')),
              ]),
              const SizedBox(height: 16),
              for (final p in me.progress)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                          Text('${p.correct}/${p.answered} · ${p.accuracy}%'),
                        ]),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(value: p.accuracy / 100, minHeight: 8),
                        ),
                        if (p.weakTopics.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Work on: ${p.weakTopics.map((t) => '${t.topic} (${t.accuracy}%)').join(', ')}',
                              style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        ],
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

class _Leaderboard extends ConsumerWidget {
  const _Leaderboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(leaderboardProvider);
    return rows.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(leaderboardProvider)),
      data: (rows) => RefreshIndicator(
        onRefresh: () async => ref.refresh(leaderboardProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Top students in the last 30 days (minimum 10 answered).', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            if (rows.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No rankings yet. Be the first!'))),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  shape: r.isMe
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.primary, width: 2))
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: r.rank <= 3 ? AppTheme.secondary : Colors.grey.shade100,
                      child: Text('${r.rank}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.text)),
                    ),
                    title: Text(r.isMe ? '${r.firstName} (you)' : r.firstName),
                    subtitle: r.school.isEmpty ? null : Text(r.school),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${r.correct} correct', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      Text('${r.accuracy}% of ${r.answered}', style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
