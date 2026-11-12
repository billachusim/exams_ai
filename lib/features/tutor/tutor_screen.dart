import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/subjects.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  String _subject = 'english';
  final List<ChatMessage> _messages = [];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _messages.clear();
    });
    try {
      final history = await ref.read(apiProvider).tutorHistory(_subject);
      if (!mounted) return;
      setState(() => _messages.addAll(history));
    } catch (_) {
      // History is a nice-to-have; the chat still works without it.
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final exam = ref.read(meProvider).value?.examTarget ?? 'JAMB';
    setState(() {
      _messages.add(ChatMessage('user', text));
      _sending = true;
      _input.clear();
    });
    _scrollToEnd();
    try {
      final reply = await ref.read(apiProvider).askTutor(subject: _subject, message: text, exam: exam);
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage('assistant', reply)));
      ref.invalidate(meProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _input.text = text;
      });
      handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider).value;
    final left = me?.premium.active == true ? null : me?.usage.tutorLeft;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        actions: [
          if (left != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(label: Text('$left free left'), visualDensity: VisualDensity.compact),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: subjects.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = subjects[i];
                return ChoiceChip(
                  label: Text(s.name),
                  selected: s.slug == _subject,
                  onSelected: (_) {
                    if (s.slug == _subject) return;
                    setState(() => _subject = s.slug);
                    _loadHistory();
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _Bubble(
                        message: ChatMessage('assistant',
                            "Hi! I'm your ${subjectName(_subject)} tutor. Ask me any topic or type a past question, and I'll explain it step by step."),
                      ),
                      for (final m in _messages) _Bubble(message: m),
                      if (_sending)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                          ),
                        ),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Ask about ${subjectName(_subject)}...',
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.role == 'user';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: mine ? AppTheme.primary : Colors.white,
          border: mine ? null : Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: SelectableText(
          mine ? message.content : cleanAiText(message.content),
          style: TextStyle(color: mine ? Colors.white : AppTheme.text, fontSize: 15, height: 1.4),
        ),
      ),
    );
  }
}
