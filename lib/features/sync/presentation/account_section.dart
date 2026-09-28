import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../data/auth_gateway.dart';
import 'sync_service.dart';

/// "Hesap ve eşitleme" in Settings: sign in / up, sync status, sign out,
/// delete account.
class AccountSection extends StatefulWidget {
  const AccountSection({super.key});

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  String? _info;
  bool _busy = false;

  static const _minPasswordLength = 8;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool createAccount}) async {
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
      if (createAccount) {
        final signedIn = await sync.signUp(email: email, password: password);
        if (!signedIn) setState(() => _info = l.authConfirmationSent(email));
      } else {
        await sync.signIn(email: email, password: password);
      }
      _password.clear();
    } on SignInException catch (e) {
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

  Future<void> _deleteAccount() async {
    final l = AppLocalizations.of(context);
    final sync = SyncScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteAccountConfirmTitle),
        content: Text(l.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await sync.deleteAccount();
      messenger.showSnackBar(SnackBar(content: Text(l.accountDeleted)));
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l.authNetwork)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sync = SyncScope.of(context);

    if (sync.status == SyncStatus.disabled) return Text(l.accountDisabled);

    if (!sync.isSignedIn) {
      return AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              decoration: InputDecoration(labelText: l.emailLabel),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(labelText: l.passwordLabel),
              onSubmitted: (_) => _submit(createAccount: false),
            ),
            if (_info case final info?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s),
                child: Text(info),
              ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s),
                child: Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 52),
                    ),
                    onPressed: _busy
                        ? null
                        : () => _submit(createAccount: true),
                    child: Text(l.signUpAction),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _submit(createAccount: false),
                    child: Text(l.signInAction),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final time = sync.lastSyncedAt == null
        ? '–'
        : TimeOfDay.fromDateTime(sync.lastSyncedAt!.toLocal()).format(context);
    final (IconData icon, String statusText) = switch (sync.status) {
      SyncStatus.syncing => (Icons.sync, l.syncStatusSyncing),
      SyncStatus.synced => (
        Icons.cloud_done_outlined,
        l.syncStatusSynced(time),
      ),
      SyncStatus.offline => (Icons.cloud_off_outlined, l.syncStatusOffline),
      SyncStatus.error => (Icons.sync_problem, l.syncStatusError),
      SyncStatus.conflict => (Icons.call_split, l.syncStatusConflict),
      SyncStatus.signedOut || SyncStatus.disabled => (Icons.cloud_outlined, ''),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.signedInAs(sync.email ?? ''), style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.s),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.s),
            Expanded(child: Text(statusText)),
          ],
        ),
        if (sync.status == SyncStatus.conflict) ...[
          const SizedBox(height: AppSpacing.s),
          FilledButton(
            onPressed: () => showConflictDialog(context),
            child: Text(l.chooseAction),
          ),
        ],
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          children: [
            TextButton.icon(
              onPressed: sync.status == SyncStatus.syncing ? null : sync.sync,
              icon: const Icon(Icons.sync),
              label: Text(l.syncNow),
            ),
            TextButton.icon(
              onPressed: sync.signOut,
              icon: const Icon(Icons.logout),
              label: Text(l.signOut),
            ),
          ],
        ),
        Text(
          l.signOutHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: _deleteAccount,
            icon: const Icon(Icons.person_remove_outlined),
            label: Text(l.deleteAccount),
          ),
        ),
      ],
    );
  }
}

/// Asks which side wins. Progress from both sides is kept either way.
Future<void> showConflictDialog(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final sync = SyncScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final keepThisDevice = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.conflictTitle),
      content: Text(l.conflictBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.conflictKeepAccount),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.conflictKeepDevice),
        ),
      ],
    ),
  );
  if (keepThisDevice == null) return;
  final unmatched = await sync.chooseSide(keepThisDevice: keepThisDevice);
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        unmatched == 0 ? l.conflictResolved : l.conflictUnmatched('$unmatched'),
      ),
    ),
  );
}

/// On Today, so a conflict is never missed.
class SyncConflictBanner extends StatelessWidget {
  const SyncConflictBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(Icons.call_split, color: scheme.onTertiaryContainer),
        title: Text(
          l.syncConflictBanner,
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
        trailing: TextButton(
          onPressed: () => showConflictDialog(context),
          child: Text(l.chooseAction),
        ),
      ),
    );
  }
}
