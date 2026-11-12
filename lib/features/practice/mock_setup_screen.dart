import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/subjects.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class MockSetupScreen extends ConsumerStatefulWidget {
  const MockSetupScreen({super.key});

  @override
  ConsumerState<MockSetupScreen> createState() => _MockSetupScreenState();
}

class _MockSetupScreenState extends ConsumerState<MockSetupScreen> {
  final List<String> _selected = ['english'];
  bool _busy = false;

  void _toggle(String slug, String exam) {
    if (exam == 'JAMB' && slug == 'english') return; // compulsory in UTME
    setState(() {
      if (_selected.contains(slug)) {
        _selected.remove(slug);
      } else if (_selected.length < 4) {
        _selected.add(slug);
      }
    });
  }

  Future<void> _start(String exam) async {
    setState(() => _busy = true);
    try {
      final session = await ref.read(apiProvider).startMock(subjects: _selected, exam: exam);
      if (mounted) context.pushReplacement('/quiz', extra: session);
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider).value;
    final exam = me?.examTarget ?? 'JAMB';
    final questions = _selected.length * 10;
    final minutes = (questions * 45 / 60).round();

    return Scaffold(
      appBar: AppBar(title: const Text('CBT mock exam')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pick up to 4 subjects${exam == 'JAMB' ? ' (Use of English is compulsory for UTME)' : ''}. '
            'You get 10 questions per subject and 45 seconds per question.'
            '${me?.premium.active == true ? '' : ' Free accounts get 1 mock a week.'}',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in subjects)
                FilterChip(label: Text(s.name), selected: _selected.contains(s.slug), onSelected: (_) => _toggle(s.slug, exam)),
            ],
          ),
          const SizedBox(height: 16),
          Text('${_selected.length}/4 subjects · $questions questions · $minutes minutes',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy || _selected.isEmpty ? null : () => _start(exam),
            child: _busy
                ? const Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Setting your paper...'),
                  ])
                : const Text('Start mock exam'),
          ),
        ],
      ),
    );
  }
}
