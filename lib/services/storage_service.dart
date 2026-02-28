import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sleep_session.dart';

class StorageService {
  static const String _sessionsBox = 'sleep_sessions';
  static const String _settingsBox = 'settings';

  late Box<String> _sessions;
  late Box<dynamic> _settings;

  Future<void> init() async {
    await Hive.initFlutter();
    _sessions = await Hive.openBox<String>(_sessionsBox);
    _settings = await Hive.openBox<dynamic>(_settingsBox);
  }

  Future<void> saveSession(SleepSession session) async {
    final json = jsonEncode(session.toMap());
    await _sessions.put(session.id, json);
  }

  List<SleepSession> getAllSessions() {
    return _sessions.values.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return SleepSession.fromMap(map);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  SleepSession? getSession(String id) {
    final json = _sessions.get(id);
    if (json == null) return null;
    return SleepSession.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> deleteSession(String id) async {
    await _sessions.delete(id);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settings.get(key, defaultValue: defaultValue);
  }
}
