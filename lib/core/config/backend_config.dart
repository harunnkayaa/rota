/// Where the Supabase backend is. Values come from the build, never from
/// the source code:
///
///   flutter run --dart-define-from-file=env/local.json
///
/// `env/local.json` is git-ignored; `env/local.example.json` shows the
/// shape. Only the *publishable* key belongs here — it is safe in a client
/// because Row Level Security decides what it can reach. The secret
/// (service-role) key must never be in the app.
abstract final class BackendConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Without both values the app runs local-only, with sync turned off.
  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
