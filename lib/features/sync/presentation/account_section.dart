import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import 'sync_service.dart';

/// "Hesap ve eşitleme" in Settings: sync status, sign out, delete account.
class AccountSection extends StatefulWidget {
  const AccountSection({super.key});

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  /// Sends what is still on this device first; if that fails, asks, since
  /// signing in with another account afterwards would drop those changes.
  Future<void> _signOut() async {
    final l = AppLocalizations.of(context);
    final sync = SyncScope.of(context);
    if (sync.hasUnsentChanges) await sync.sync();
    if (!mounted) return;
    if (sync.hasUnsentChanges) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.signOutUnsentTitle),
          content: Text(l.signOutUnsentBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.signOutAnyway),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await sync.signOut();
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

    // Signed out: the app shows the sign-in screen instead.
    if (!sync.isSignedIn) return const SizedBox.shrink();

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
              onPressed: _signOut,
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
