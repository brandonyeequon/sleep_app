import '../models/sleep_event.dart';

class AudioAnalysisService {
  Future<void> init() async {}

  void dispose() {}

  Future<List<SleepEvent>> analyzeFile(
    String filePath, {
    void Function(double progress, String message)? onProgress,
  }) async {
    // TFLite inference is not available on web — fall back to demo data
    return [];
  }
}
