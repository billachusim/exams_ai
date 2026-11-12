import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config.dart';
import '../../core/subjects.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: me.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(meProvider)),
        data: (me) => _ProfileBody(me: me),
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.me});
  final Me me;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  late final _name = TextEditingController(text: widget.me.profile?.fullName ?? '');
  late final _school = TextEditingController(text: widget.me.profile?.school ?? '');
  late final _phone = TextEditingController(text: widget.me.profile?.phone ?? '');
  late String _exam = widget.me.examTarget;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _school.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).updateProfile(
            userId: widget.me.userId,
            fullName: _name.text.trim(),
            school: _school.text,
            phone: _phone.text,
            examTarget: _exam,
          );
      ref.invalidate(meProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(supabaseProvider).auth.signOut();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
            "This permanently removes your account, chats, scores and any remaining Premium time. It can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(apiProvider).deleteAccount();
      await ref.read(supabaseProvider).auth.signOut();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Text(me.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            title: Text(me.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text([me.email ?? '', if (me.profile?.facultyId != null) 'ID ${me.profile!.facultyId}'].join(' · ')),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(Icons.workspace_premium, color: me.premium.active ? AppTheme.primary : Colors.grey),
            title: Text(me.premium.active ? 'Premium' : 'Free plan'),
            subtitle: Text(me.premium.active && me.premium.expiresAt != null
                ? 'Until ${DateFormat.yMMMMd().format(me.premium.expiresAt!)}'
                : '3 tutor questions, 20 practice questions a day'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/premium'),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Your details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
        const SizedBox(height: 12),
        TextField(controller: _school, decoration: const InputDecoration(labelText: 'School')),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'WhatsApp number (optional)'),
        ),
        const SizedBox(height: 12),
        const Text('Main exam'),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [for (final e in exams) ButtonSegment(value: e, label: Text(e))],
          selected: {_exam},
          onSelectionChanged: (s) => setState(() => _exam = s.first),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving...' : 'Save changes')),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy Policy'),
          onTap: () => launchUrl(Uri.parse(AppConfig.privacyUrl), mode: LaunchMode.externalApplication),
        ),
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: const Text('Contact support'),
          onTap: () => launchUrl(Uri.parse('mailto:${AppConfig.supportEmail}?subject=ExamsAi%20app')),
        ),
        ListTile(leading: const Icon(Icons.logout), title: const Text('Sign out'), onTap: _signOut),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: AppTheme.danger),
          title: const Text('Delete my account', style: TextStyle(color: AppTheme.danger)),
          onTap: _delete,
        ),
      ],
    );
  }
}
