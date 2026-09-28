import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../data/auth_gateway.dart';
import 'sync_service.dart';

/// The first screen when the build has a server and nobody is signed in.
/// One form, two modes: sign in (default) or create an account.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _createAccount = false;
  String? _error;
  String? _info;
  bool _busy = false;

  static const _minPasswordLength = 8;
  static const _logoSize = 72.0;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode() => setState(() {
    _createAccount = !_createAccount;
    _error = null;
    _info = null;
  });

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final sync = SyncScope.of(context);
    final email = _email.text.trim();
    final password = _password.text;
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = l.errorEmailInvalid);
      return;
    }
    if (password.length < _minPasswordLength) {
      setState(() => _error = l.authWeakPassword);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      if (_createAccount) {
        final signedIn = await sync.signUp(email: email, password: password);
        if (!signedIn && mounted) {
          // Confirm by email first; then sign in with the same details.
          setState(() {
            _info = l.authConfirmationSent(email);
            _createAccount = false;
          });
        }
      } else {
        await sync.signIn(email: email, password: password);
      }
      _password.clear();
    } on SignInException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = switch (e.failure) {
          AuthFailure.invalidCredentials => l.authInvalidCredentials,
          AuthFailure.emailTaken => l.authEmailTaken,
          AuthFailure.weakPassword => l.authWeakPassword,
          AuthFailure.emailNotConfirmed => l.authEmailNotConfirmed,
          AuthFailure.network => l.authNetwork,
          AuthFailure.unknown => l.authUnknown,
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                    Center(
                      child: Container(
                        width: _logoSize,
                        height: _logoSize,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppLayout.cardRadius,
                          ),
                        ),
                        child: Icon(
                          Icons.route,
                          size: _logoSize / 2,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      l.appTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      l.signInTagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      _createAccount ? l.signUpAction : l.signInAction,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: l.emailLabel),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: [
                        _createAccount
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(labelText: l.passwordLabel),
                      onSubmitted: (_) => _busy ? null : _submit(),
                    ),
                    if (_info case final info?)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.m),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.mark_email_read_outlined,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(child: Text(info)),
                          ],
                        ),
                      ),
                    if (_error case final error?)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.m),
                        child: Text(
                          error,
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.l),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 52),
                      ),
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? SizedBox.square(
                              dimension: AppSpacing.l - AppSpacing.xs,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                semanticsLabel: l.loadingLabel,
                              ),
                            )
                          : Text(
                              _createAccount ? l.signUpAction : l.signInAction,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    TextButton(
                      onPressed: _busy ? null : _switchMode,
                      child: Text(
                        _createAccount
                            ? l.signInSwitchToSignIn
                            : l.signInSwitchToSignUp,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      l.signInSyncHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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
