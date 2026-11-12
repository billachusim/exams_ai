import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/subjects.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  String _subject = 'english';
  int _count = 10;
  final _topic = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      final exam = ref.read(meProvider).value?.examTarget ?? 'JAMB';
      final session = await ref.read(apiProvider).startPractice(
            subject: _subject,
            topic: _topic.text,
            count: _count,
            exam: exam,
          );
      ref.invalidate(meProvider);
      if (mounted) context.push('/quiz', extra: session);
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider).value;
    final left = me?.premium.active == true ? null : me?.usage.practiceLeft;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Practise with instant marking', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'See the correct answer and an explanation for every question.'
            '${left != null ? ' $left free questions left today.' : ''}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          const Text('Subject', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in subjects)
                ChoiceChip(label: Text(s.name), selected: s.slug == _subject, onSelected: (_) => setState(() => _subject = s.slug)),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _topic,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Topic (optional)',
              hintText: 'e.g. Quadratic equations, Lexis and structure',
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),
          const Text('Number of questions', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 5, label: Text('5')),
              ButtonSegment(value: 10, label: Text('10')),
              ButtonSegment(value: 20, label: Text('20')),
            ],
            selected: {_count},
            onSelectionChanged: (s) => setState(() => _count = s.first),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _busy ? null : _start,
            child: _busy
                ? const Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Preparing your questions...'),
                  ])
                : const Text('Start practice'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/mock'),
            icon: const Icon(Icons.timer_outlined),
            label: const Text('Take a timed CBT mock exam instead'),
          ),
        ],
      ),
    );
  }
}
