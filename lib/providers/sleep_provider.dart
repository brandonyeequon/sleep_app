import 'package:flutter/foundation.dart';
import '../models/sleep_session.dart';
import '../services/audio_analysis_service.dart';
import '../services/storage_service.dart';
import '../services/sleep_analysis_service.dart';

class SleepProvider extends ChangeNotifier {
  final StorageService _storageService;
  final SleepAnalysisService _analysisService;
  final AudioAnalysisService _audioAnalysisService;

  List<SleepSession> _sessions = [];
  SleepSession? _currentSession;
  int _selectedNavIndex = 0;
  bool _isLoading = false;

  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  String _analysisMessage = '';
  String? _lastError;

  SleepProvider({
    required StorageService storageService,
    required SleepAnalysisService analysisService,
    required AudioAnalysisService audioAnalysisService,
  })  : _storageService = storageService,
        _analysisService = analysisService,
        _audioAnalysisService = audioAnalysisService;

  List<SleepSession> get sessions => _sessions;
  SleepSession? get currentSession => _currentSession;
  int get selectedNavIndex => _selectedNavIndex;
  bool get isLoading => _isLoading;

  bool get isAnalyzing => _isAnalyzing;
  double get analysisProgress => _analysisProgress;
  String get analysisMessage => _analysisMessage;
  String? get lastError => _lastError;

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

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

  Future<void> handleUpload(String fileName, {String? filePath}) async {
    if (filePath != null) {
      // Real audio analysis
      _isAnalyzing = true;
      _analysisProgress = 0.0;
      _analysisMessage = 'Preparing analysis...';
      notifyListeners();

      try {
        final events = await _audioAnalysisService.analyzeFile(
          filePath,
          onProgress: (progress, message) {
            _analysisProgress = progress;
            _analysisMessage = message;
            notifyListeners();
          },
        );

        debugPrint('SleepProvider: Analysis returned ${events.length} events');

        final newSession = _analysisService.buildSessionFromEvents(
          events: events,
          fileName: fileName,
        );

        await _storageService.saveSession(newSession);
        _sessions = _storageService.getAllSessions();
        _currentSession = newSession;
        _selectedNavIndex = 0;
        _lastError = null;
      } catch (e, stackTrace) {
        debugPrint('Audio analysis failed: $e');
        debugPrint('Stack trace: $stackTrace');
        _lastError = 'Analysis failed: $e';
        final newSession = _analysisService.generateDemoSession();
        await _storageService.saveSession(newSession);
        _sessions = _storageService.getAllSessions();
        _currentSession = newSession;
        _selectedNavIndex = 0;
      } finally {
        _isAnalyzing = false;
        _analysisProgress = 0.0;
        _analysisMessage = '';
        notifyListeners();
      }
    } else {
      // No file path — generate demo data
      _isLoading = true;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1));

      final newSession = _analysisService.generateDemoSession();
      await _storageService.saveSession(newSession);

      _sessions = _storageService.getAllSessions();
      _currentSession = newSession;
      _selectedNavIndex = 0;

      _isLoading = false;
      notifyListeners();
    }
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
