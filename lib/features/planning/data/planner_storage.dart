import 'package:shared_preferences/shared_preferences.dart';

/// Where the planner's saved state lives on this device.
///
/// Two implementations: the real device store and an in-memory one for
/// tests. Phase 2 adds Supabase on top; this stays as the local cache.
abstract interface class PlannerStorage {
  /// Null when nothing was saved yet.
  Future<String?> read();

  Future<void> write(String data);
}

/// iOS: NSUserDefaults. Web: the browser's localStorage for this site.
///
/// Neither is encrypted; acceptable for the local phase, revisited before
/// sensitive (health/worship) data is synced (CLAUDE.md §17).
class SharedPreferencesPlannerStorage implements PlannerStorage {
  SharedPreferencesPlannerStorage({
    SharedPreferencesAsync? preferences,
    this.key = plannerKey,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  /// The planner's own data.
  static const plannerKey = 'rota.planner.v1';

  /// Sync bookkeeping (last server marker, unsent changes).
  static const syncStateKey = 'rota.sync.v1';

  final String key;
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(key);

  @override
  Future<void> write(String data) => _preferences.setString(key, data);
}

class InMemoryPlannerStorage implements PlannerStorage {
  InMemoryPlannerStorage([this.data]);

  String? data;

  @override
  Future<String?> read() async => data;

  @override
  Future<void> write(String data) async => this.data = data;
}
