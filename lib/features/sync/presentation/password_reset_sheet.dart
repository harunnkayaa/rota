import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../data/auth_gateway.dart';
import 'sign_in_screen.dart';
import 'sync_service.dart';

/// "Şifremi unuttum": email → one-time code by mail → code + new password.
/// A code instead of a link, so it works the same in the iPhone app (where
/// a link would open Safari, not the app) and on the web.
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

  static const emailFieldKey = Key('reset.email');
  static const codeFieldKey = Key('reset.code');
  static const passwordFieldKey = Key('reset.password');

  @override
  State<PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends State<PasswordResetSheet> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  static const _minPasswordLength = 8;
  static const _maxCodeLength = 10;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _codePattern = RegExp(r'^\d{6,10}$');

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on SignInException catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = authFailureText(AppLocalizations.of(context), e.failure),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    final l = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = l.errorEmailInvalid);
      return;
    }
    final sync = SyncScope.of(context);
    await _run(() async {
      await sync.sendPasswordReset(email);
      if (mounted) setState(() => _codeSent = true);
    });
  }

  Future<void> _reset() async {
    final l = AppLocalizations.of(context);
    final code = _code.text.trim();
    if (!_codePattern.hasMatch(code)) {
      setState(() => _error = l.authCodeInvalid);
      return;
    }
    if (_password.text.length < _minPasswordLength) {
      setState(() => _error = l.authWeakPassword);
      return;
    }
    final sync = SyncScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await _run(() async {
      await sync.resetPassword(
        email: _email.text.trim(),
        code: code,
        newPassword: _password.text,
      );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.resetDone)));
    });
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
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.resetTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s),
            Text(
              _codeSent ? l.resetCodeSent(_email.text.trim()) : l.resetIntro,
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              key: PasswordResetSheet.emailFieldKey,
              controller: _email,
              enabled: !_codeSent,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              decoration: InputDecoration(labelText: l.emailLabel),
            ),
            if (_codeSent) ...[
              const SizedBox(height: AppSpacing.s),
              TextField(
                key: PasswordResetSheet.codeFieldKey,
                controller: _code,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_maxCodeLength),
                ],
                decoration: InputDecoration(labelText: l.resetCodeLabel),
              ),
              const SizedBox(height: AppSpacing.s),
              TextField(
                key: PasswordResetSheet.passwordFieldKey,
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(labelText: l.resetNewPasswordLabel),
                onSubmitted: (_) => _busy ? null : _reset(),
              ),
            ],
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
              style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
              onPressed: _busy ? null : (_codeSent ? _reset : _sendCode),
              child: Text(_codeSent ? l.resetConfirm : l.resetSendCode),
            ),
            if (_codeSent)
              TextButton(
                onPressed: _busy ? null : _sendCode,
                child: Text(l.resetResend),
              ),
          ],
        ),
      ),
    );
  }
}
