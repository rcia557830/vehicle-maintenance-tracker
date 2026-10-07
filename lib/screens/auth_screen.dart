import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/workspace.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.client,
    this.recovery = false,
    this.onRecovered,
  });
  final SupabaseClient client;
  final bool recovery;
  final VoidCallback? onRecovered;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool signup = false, busy = false, obscure = true;
  String? message;
  bool failed = false;
  String get redirect =>
      kIsWeb ? '${Uri.base.origin}/' : 'io.motorcare.app://login-callback/';

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit({bool reset = false}) async {
    if (busy) return;
    if (reset) {
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim())) {
        setState(() {
          failed = true;
          message = 'Enter your email address first.';
        });
        return;
      }
    } else if (!form.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
      message = null;
      failed = false;
    });
    try {
      if (reset) {
        await widget.client.auth.resetPasswordForEmail(
          email.text.trim(),
          redirectTo: redirect,
        );
        message = 'If this email has an account, a password reset link has been sent.';
      } else if (widget.recovery) {
        await widget.client.auth.updateUser(
          UserAttributes(password: password.text),
        );
        widget.onRecovered?.call();
      } else if (signup) {
        final response = await widget.client.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          emailRedirectTo: redirect,
        );
        if (response.session == null) {
          message = 'Check your email to confirm your account, then sign in.';
          signup = false;
        }
      } else {
        await widget.client.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on AuthException catch (e) {
      failed = true;
      message = e.message;
    } catch (_) {
      failed = true;
      message =
          'Unable to connect. Check your internet connection and try again.';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.recovery
        ? 'Choose a new password'
        : signup
        ? 'Start your garage'
        : 'Welcome back';
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, size) => Row(
          children: [
            if (size.maxWidth >= 960)
              Expanded(
                child: Container(
                  color: AppColors.sidebar,
                  padding: const EdgeInsets.all(64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_car_filled_rounded,
                        color: Color(0xff52dcc4),
                        size: 64,
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'MOTORCARE',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 4,
                          color: Color(0xff52dcc4),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'A clearer view\nof every journey.',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontSize: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Your garage, service history and tire replacement plans. Together, wherever you sign in.',
                        style: TextStyle(
                          color: Color(0xffb8c6da),
                          fontSize: 16,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          Chip(label: Text('Multiple vehicles')),
                          Chip(label: Text('Tire age tracking')),
                          Chip(label: Text('Cloud storage')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 410),
                    child: AutofillGroup(
                      child: Form(
                        key: form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: IconBadge(Icons.garage_outlined, size: 52),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.recovery ? 'Use at least 8 characters.' : 'Sign in to your personal vehicle workspace.',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 32),
                            if (!widget.recovery) ...[
                              TextFormField(
                                controller: email,
                                enabled: !busy,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Email address',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: (value) =>
                                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(value?.trim() ?? '')
                                    ? null
                                    : 'Enter a valid email address.',
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: password,
                              enabled: !busy,
                              obscureText: obscure,
                              autofillHints: [
                                signup || widget.recovery
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: obscure
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () =>
                                      setState(() => obscure = !obscure),
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  (value?.length ?? 0) <
                                      (signup || widget.recovery ? 8 : 1)
                                  ? 'Enter ${signup || widget.recovery ? 'at least 8 characters' : 'your password'}.'
                                  : null,
                              onFieldSubmitted: (_) => submit(),
                            ),
                            if (!widget.recovery && !signup)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => submit(reset: true),
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                            const SizedBox(height: 20),
                            if (message != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  message!,
                                  style: TextStyle(
                                    color: failed
                                        ? Theme.of(context).colorScheme.error
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            FilledButton(
                              onPressed: busy ? null : submit,
                              child: busy
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      widget.recovery
                                          ? 'Save password'
                                          : signup
                                          ? 'Create account'
                                          : 'Sign in',
                                    ),
                            ),
                            const SizedBox(height: 16),
                            if (!widget.recovery)
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => setState(() {
                                        signup = !signup;
                                        message = null;
                                        form.currentState?.reset();
                                      }),
                                child: Text(
                                  signup
                                      ? 'Already have an account? Sign in'
                                      : 'New to Motorcare? Create an account',
                                ),
                              ),
                            const SizedBox(height: 24),
                            const Text(
                              'Your records are private to your account.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
