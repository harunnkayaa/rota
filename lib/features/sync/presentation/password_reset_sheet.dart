import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../data/auth_gateway.dart';
import 'sign_in_screen.dart';
import 'sync_service.dart';

/// "Şifremi unuttum": asks for the email and sends a reset link. The link
/// opens the web app (on any device), which then asks for a new password
/// ([NewPasswordScreen]); the phone app signs in with it afterwards.
Future<void> showPasswordResetSheet(
  BuildContext context, {
  required String email,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PasswordResetSheet(initialEmail: email),
  );
}

class PasswordResetSheet extends StatefulWidget {
  const PasswordResetSheet({required this.initialEmail, super.key});

  final String initialEmail;

  @override
  State<PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends State<PasswordResetSheet> {
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sent = false;
  bool _busy = false;
  String? _error;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = l.errorEmailInvalid);
      return;
    }
    final sync = SyncScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await sync.sendPasswordReset(email);
      if (mounted) setState(() => _sent = true);
    } on SignInException catch (e) {
      if (mounted) setState(() => _error = authFailureText(l, e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.resetTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.s),
          Text(_sent ? l.resetCodeSent(_email.text.trim()) : l.resetIntro),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _email,
            enabled: !_sent,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            decoration: InputDecoration(labelText: l.emailLabel),
            onSubmitted: (_) => _busy || _sent ? null : _send(),
          ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.m),
              child: Text(
                error,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: AppSpacing.l),
          if (_sent)
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
              onPressed: _busy ? null : _send,
              child: Text(l.resetResend),
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
              onPressed: _busy ? null : _send,
              child: Text(l.resetSendCode),
            ),
        ],
      ),
    );
  }
}

/// Shown instead of the app after opening a reset link.
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  static const _minPasswordLength = 8;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (_password.text.length < _minPasswordLength) {
      setState(() => _error = l.authWeakPassword);
      return;
    }
    final sync = SyncScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await sync.setNewPassword(_password.text);
      messenger.showSnackBar(SnackBar(content: Text(l.resetDone)));
    } on SignInException catch (e) {
      if (mounted) setState(() => _error = authFailureText(l, e.failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth / 1.6,
              ),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.newPasswordTitle, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.s),
                    Text(l.newPasswordBody),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: l.resetNewPasswordLabel,
                      ),
                      onSubmitted: (_) => _busy ? null : _save(),
                    ),
                    if (_error case final error?)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.m),
                        child: Text(
                          error,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.l),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 52),
                      ),
                      onPressed: _busy ? null : _save,
                      child: Text(l.resetConfirm),
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
