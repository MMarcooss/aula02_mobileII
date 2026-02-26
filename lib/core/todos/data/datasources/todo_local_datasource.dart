import 'package:shared_preferences/shared_preferences.dart';

class TodoLocalDataSource {
  static const _kLastSync = 'todos_last_sync_iso';

  Future<void> saveLastSync(DateTime dt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastSync, dt.toIso8601String());
  }

  Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kLastSync);
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}
