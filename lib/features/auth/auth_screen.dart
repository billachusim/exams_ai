import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';

enum _Mode { signIn, signUp, forgot }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _Mode _mode = _Mode.signUp;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _school = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _school.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = ref.read(supabaseProvider).auth;
    setState(() => _busy = true);
    try {
      switch (_mode) {
        case _Mode.signIn:
          await auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
        case _Mode.signUp:
          final res = await auth.signUp(
            email: _email.text.trim(),
            password: _password.text,
            data: {'full_name': _name.text.trim(), 'school': _school.text.trim()},
          );
          if (res.session == null && mounted) {
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Confirm your email'),
                content: Text('We sent a link to ${_email.text.trim()}. Open it, then come back and sign in.'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
              ),
            );
            setState(() => _mode = _Mode.signIn);
          }
        case _Mode.forgot:
          await auth.resetPasswordForEmail(_email.text.trim(), redirectTo: '${AppConfig.websiteUrl}/reset-password');
          _snack('Check your email for a link to set a new password.');
          setState(() => _mode = _Mode.signIn);
      }
    } on AuthException catch (e) {
      _snack(e.message.contains('Invalid login') ? 'Wrong email or password.' : e.message);
    } catch (_) {
      _snack('Network problem. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final title = switch (_mode) {
      _Mode.signUp => 'Pass JAMB with your own AI tutor',
      _Mode.signIn => 'Welcome back',
      _Mode.forgot => 'Reset your password',
    };
    final subtitle = switch (_mode) {
      _Mode.signUp => 'Free every day: 3 tutor questions, 20 practice questions and a weekly CBT mock.',
      _Mode.signIn => 'Sign in to keep practising.',
      _Mode.forgot => "Enter your email and we'll send you a reset link.",
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset('assets/app_icon.png', height: 72, width: 72),
                    ),
                    const SizedBox(height: 20),
                    Text(title, textAlign: TextAlign.center, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(subtitle, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: Colors.black54)),
                    const SizedBox(height: 28),
                    if (_mode == _Mode.signUp) ...[
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                      validator: (v) => RegExp(r'^\S+@\S+\.\S+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email',
                    ),
                    if (_mode != _Mode.forgot) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: [_mode == _Mode.signUp ? AutofillHints.newPassword : AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => _mode == _Mode.signUp && (v ?? '').length < 8
                            ? 'Use at least 8 characters'
                            : (v ?? '').isEmpty
                                ? 'Enter your password'
                                : null,
                      ),
                    ],
                    if (_mode == _Mode.signUp) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _school,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'School (optional)', prefixIcon: Icon(Icons.school_outlined)),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(switch (_mode) {
                              _Mode.signUp => 'Create free account',
                              _Mode.signIn => 'Sign in',
                              _Mode.forgot => 'Send reset link',
                            }),
                    ),
                    const SizedBox(height: 8),
                    if (_mode == _Mode.signIn)
                      TextButton(onPressed: () => setState(() => _mode = _Mode.forgot), child: const Text('Forgot password?')),
                    TextButton(
                      onPressed: () => setState(() => _mode = _mode == _Mode.signUp ? _Mode.signIn : _Mode.signUp),
                      child: Text(_mode == _Mode.signUp ? 'Already have an account? Sign in' : 'New here? Create a free account'),
                    ),
                    if (_mode == _Mode.signUp)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text('By continuing you agree to our ', style: t.bodySmall),
                            GestureDetector(
                              onTap: () => launchUrl(Uri.parse(AppConfig.privacyUrl), mode: LaunchMode.externalApplication),
                              child: Text('Privacy Policy',
                                  style: t.bodySmall?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
