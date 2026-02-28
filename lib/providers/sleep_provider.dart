import 'package:flutter/foundation.dart';
import '../models/sleep_session.dart';
import '../services/storage_service.dart';
import '../services/sleep_analysis_service.dart';

class SleepProvider extends ChangeNotifier {
  final StorageService _storageService;
  final SleepAnalysisService _analysisService;

  List<SleepSession> _sessions = [];
  SleepSession? _currentSession;
  int _selectedNavIndex = 0;
  bool _isLoading = false;

  SleepProvider({
    required StorageService storageService,
    required SleepAnalysisService analysisService,
  })  : _storageService = storageService,
        _analysisService = analysisService;

  List<SleepSession> get sessions => _sessions;
  SleepSession? get currentSession => _currentSession;
  int get selectedNavIndex => _selectedNavIndex;
  bool get isLoading => _isLoading;

  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    _sessions = _storageService.getAllSessions();

    if (_sessions.isEmpty) {
      await _loadDemoData();
    }

    _currentSession = _sessions.isNotEmpty ? _sessions.first : null;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadDemoData() async {
    final demoSessions = _analysisService.generateSessionHistory(7);
    for (final session in demoSessions) {
      await _storageService.saveSession(session);
    }
    _sessions = _storageService.getAllSessions();
  }

  void selectSession(SleepSession session) {
    _currentSession = session;
    _selectedNavIndex = 0;
    notifyListeners();
  }

  Future<void> handleUpload(String fileName) async {
    _isLoading = true;
    notifyListeners();

    // Simulate analysis delay
    await Future.delayed(const Duration(seconds: 1));

    final newSession = _analysisService.generateDemoSession();
    await _storageService.saveSession(newSession);

    _sessions = _storageService.getAllSessions();
    _currentSession = newSession;
    _selectedNavIndex = 0;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await _storageService.deleteSession(id);
    _sessions = _storageService.getAllSessions();
    if (_currentSession?.id == id) {
      _currentSession = _sessions.isNotEmpty ? _sessions.first : null;
    }
    notifyListeners();
  }
}
