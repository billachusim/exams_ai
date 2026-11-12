import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/subjects.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.session});
  final QuizSession session;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _index = 0;
  final Map<String, String> _answers = {};
  bool _submitting = false;
  QuizResult? _result;
  Timer? _timer;
  int? _remaining;

  QuizSession get s => widget.session;

  @override
  void initState() {
    super.initState();
    if (s.timeLimitSeconds != null) {
      final end = s.startedAt.add(Duration(seconds: s.timeLimitSeconds!));
      void tick() {
        final left = end.difference(DateTime.now()).inSeconds;
        if (!mounted) return;
        setState(() => _remaining = left);
        if (left <= 0) {
          _timer?.cancel();
          _submit();
        }
      }

      tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _result != null) return;
    setState(() => _submitting = true);
    try {
      final result = await ref.read(apiProvider).submitAttempt(s.attemptId, _answers);
      _timer?.cancel();
      if (!mounted) return;
      setState(() => _result = result);
      ref.invalidate(meProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _confirmLeave() async {
    if (_result != null) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this session?'),
        content: const Text("Your answers won't be marked."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave')),
        ],
      ),
    );
    return leave == true;
  }

  String _fmt(int secs) {
    final m = secs ~/ 60;
    final r = (secs % 60).clamp(0, 59);
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _ResultsView(result: _result!, mode: s.mode);
    if (s.questions.isEmpty) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('No questions were loaded.')));
    }
    final q = s.questions[_index];
    final last = _index == s.questions.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.mode == 'mock' ? 'Mock exam' : 'Practice'),
          actions: [
            if (_remaining != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Row(children: [
                    Icon(Icons.timer_outlined, size: 18, color: _remaining! < 60 ? AppTheme.danger : null),
                    const SizedBox(width: 4),
                    Text(_fmt(_remaining!.clamp(0, 1 << 30)),
                        style: TextStyle(fontWeight: FontWeight.w700, color: _remaining! < 60 ? AppTheme.danger : null)),
                  ]),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(value: _answers.length / s.questions.length, minHeight: 4),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Question ${_index + 1} of ${s.questions.length} · ${subjectName(q.subject)}'
                      '${q.topic != null ? ' · ${q.topic}' : ''}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Text(q.stem, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.4)),
                    const SizedBox(height: 16),
                    for (final o in q.options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OptionTile(
                          option: o,
                          selected: _answers[q.id] == o.key,
                          onTap: () => setState(() => _answers[q.id] = o.key),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < s.questions.length; i++)
                          InkWell(
                            onTap: () => setState(() => _index = i),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _answers.containsKey(s.questions[i].id) ? AppTheme.primary : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: i == _index ? AppTheme.text : Colors.grey.shade300, width: i == _index ? 2 : 1),
                              ),
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _answers.containsKey(s.questions[i].id) ? Colors.white : AppTheme.text)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _index == 0 ? null : () => setState(() => _index--),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _submitting ? null : (last ? _submit : () => setState(() => _index++)),
                        child: Text(_submitting
                            ? 'Marking...'
                            : last
                                ? 'Submit (${_answers.length}/${s.questions.length})'
                                : 'Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option, required this.selected, required this.onTap});
  final QuestionOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppTheme.primary : Colors.grey.shade300, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${option.key}.', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Expanded(child: Text(option.text, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w400))),
            ],
          ),
        ),
      );
}

class _ResultsView extends ConsumerStatefulWidget {
  const _ResultsView({required this.result, required this.mode});
  final QuizResult result;
  final String mode;

  @override
  ConsumerState<_ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends ConsumerState<_ResultsView> {
  final Set<String> _reported = {};

  String get _message {
    final p = widget.result.percent;
    if (p >= 80) return 'Excellent work!';
    if (p >= 60) return 'Good job. Review the ones you missed.';
    if (p >= 40) return "You're getting there. Read the explanations below.";
    return 'Keep going. Every explanation you read moves your score up.';
  }

  Future<void> _report(String id) async {
    try {
      await ref.read(apiProvider).reportQuestion(id);
      setState(() => _reported.add(id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thanks, we'll review this question.")));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('Your score', style: TextStyle(color: Colors.black54)),
                Text('${r.score}/${r.total}',
                    style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                Text('${r.percent}% · $_message', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (r.late)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text("Time ran out before you submitted, so answers weren't counted.",
                        textAlign: TextAlign.center, style: TextStyle(color: AppTheme.danger)),
                  ),
                if (r.bySubject.length > 1) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                    for (final b in r.bySubject) Chip(label: Text('${b.name}: ${b.correct}/${b.total}')),
                  ]),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => widget.mode == 'mock' ? context.pushReplacement('/mock') : context.pop(),
                  child: const Text('Start another'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < r.results.length; i++) ...[
            _ResultCard(
              index: i,
              item: r.results[i],
              reported: _reported.contains(r.results[i].questionId),
              onReport: () => _report(r.results[i].questionId),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.index, required this.item, required this.reported, required this.onReport});
  final int index;
  final QuestionResult item;
  final bool reported;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(item.isCorrect ? Icons.check_circle : Icons.cancel,
                    color: item.isCorrect ? AppTheme.success : AppTheme.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('${index + 1}. ${item.stem}', style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 10),
              for (final o in item.options)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: o.key == item.answer
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : o.key == item.chosen
                            ? AppTheme.danger.withValues(alpha: 0.1)
                            : null,
                  ),
                  child: Text(
                    '${o.key}. ${o.text}'
                    '${o.key == item.answer ? '  ✓ Correct answer' : o.key == item.chosen ? '  ✗ Your answer' : ''}',
                  ),
                ),
              if (item.chosen == null) const Text('Not answered', style: TextStyle(color: Colors.black54)),
              if (item.explanation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
                  child: Text(cleanAiText(item.explanation)),
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: reported ? null : onReport,
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: Text(reported ? 'Reported' : 'Report a problem', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      );
}
