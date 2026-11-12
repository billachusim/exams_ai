import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ExamsAi')),
      body: me.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(meProvider)),
        data: (me) => RefreshIndicator(
          onRefresh: () async => ref.refresh(meProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Hi ${me.displayName.split(' ').first} 👋',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Preparing for ${me.examTarget}', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              _AllowanceCard(me: me),
              const SizedBox(height: 16),
              _ActionCard(
                icon: Icons.chat_bubble,
                title: 'Ask the AI tutor',
                subtitle: 'Any topic, step-by-step explanations',
                onTap: () => context.go('/tutor'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.fact_check,
                title: 'Practise questions',
                subtitle: 'Instant marking and explanations',
                onTap: () => context.go('/practice'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.timer,
                title: 'Take a CBT mock exam',
                subtitle: 'Timed, up to 4 subjects, full breakdown',
                onTap: () => context.push('/mock'),
              ),
              if (me.progress.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Your progress', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: Text('${me.totalAnswered} questions answered'),
                    subtitle: Text('${me.accuracy}% correct overall'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/progress'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AllowanceCard extends StatelessWidget {
  const _AllowanceCard({required this.me});
  final Me me;

  @override
  Widget build(BuildContext context) {
    if (me.premium.active) {
      return Card(
        color: AppTheme.primary.withValues(alpha: 0.08),
        child: const ListTile(
          leading: Icon(Icons.workspace_premium, color: AppTheme.primary),
          title: Text('Premium'),
          subtitle: Text('Unlimited tutor, practice and mock exams'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Free today', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('${me.usage.tutorLeft ?? 0} tutor questions and ${me.usage.practiceLeft ?? 0} practice questions left'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/premium'),
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Go Premium for unlimited'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
            child: Icon(icon, color: AppTheme.primary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
