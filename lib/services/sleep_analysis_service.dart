import 'dart:math';
import '../models/sleep_event.dart';
import '../models/sleep_session.dart';

class SleepAnalysisService {
  final _random = Random(42);

  SleepSession generateDemoSession({DateTime? date}) {
    final sessionDate = date ?? DateTime.now().subtract(const Duration(hours: 8));
    final events = _generateEvents(sessionDate);
    final totalDuration = const Duration(hours: 7, minutes: 42);

    final pauseEvents =
        events.where((e) => e.type == SleepEventType.pauseEvent).toList();
    final snoreEventsList =
        events.where((e) => e.type == SleepEventType.snoring).toList();
    final gaspEvents =
        events.where((e) => e.type == SleepEventType.recoveryGasp).toList();

    final breathingInterruptions = pauseEvents.length;
    final snoreCount = snoreEventsList.length;
    final gaspCount = gaspEvents.length;

    final totalSnoringDuration = snoreEventsList.fold<Duration>(
      Duration.zero,
      (sum, e) => sum + e.duration,
    );

    final longestPause = pauseEvents.isEmpty
        ? Duration.zero
        : pauseEvents
            .map((e) => e.duration)
            .reduce((a, b) => a > b ? a : b);

    final avgPause = pauseEvents.isEmpty
        ? Duration.zero
        : Duration(
            milliseconds: pauseEvents
                    .map((e) => e.duration.inMilliseconds)
                    .reduce((a, b) => a + b) ~/
                pauseEvents.length);

    final pauseFrequency =
        breathingInterruptions / (totalDuration.inMinutes / 60.0);

    final breathingScore = _computeScore(
      breathingInterruptions: breathingInterruptions,
      longestPause: longestPause,
      avgPauseDuration: avgPause,
      totalSnoringDuration: totalSnoringDuration,
      gaspCount: gaspCount,
      totalDuration: totalDuration,
    );

    final riskLevel = _riskLevel(breathingScore);
    final snoreIntensity = min(1.0, snoreCount / 30.0);

    return SleepSession(
      id: 'session_${sessionDate.millisecondsSinceEpoch}',
      date: sessionDate,
      fileName: 'sleep_recording_${sessionDate.month}_${sessionDate.day}.wav',
      totalDuration: totalDuration,
      breathingScore: breathingScore,
      riskLevel: riskLevel,
      breathingInterruptions: breathingInterruptions,
      longestPause: longestPause,
      snoreEvents: snoreCount,
      avgPauseDuration: avgPause,
      pauseFrequency: pauseFrequency,
      snoreIntensity: snoreIntensity,
      aiInsights: _generateInsights(
        score: breathingScore,
        pauseRate: pauseFrequency,
        pauseCount: breathingInterruptions,
        avgPauseDuration: avgPause,
        longestPause: longestPause,
        totalSnoringDuration: totalSnoringDuration,
        totalDuration: totalDuration,
        gaspCount: gaspCount,
        snoreCount: snoreCount,
      ),
      events: events,
      totalSnoringDuration: totalSnoringDuration,
      recoveryGaspEvents: gaspCount,
    );
  }

  List<SleepEvent> _generateEvents(DateTime start) {
    final events = <SleepEvent>[];
    var current = start;
    final end = start.add(const Duration(hours: 7, minutes: 42));

    while (current.isBefore(end)) {
      final roll = _random.nextDouble();
      SleepEventType type;
      Duration duration;

      if (roll < 0.65) {
        type = SleepEventType.normalBreathing;
        duration = Duration(minutes: 3 + _random.nextInt(8));
      } else if (roll < 0.82) {
        type = SleepEventType.snoring;
        duration = Duration(seconds: 30 + _random.nextInt(120));
      } else if (roll < 0.95) {
        type = SleepEventType.pauseEvent;
        duration = Duration(seconds: 8 + _random.nextInt(25));
      } else {
        type = SleepEventType.recoveryGasp;
        duration = Duration(seconds: 2 + _random.nextInt(5));
      }

      events.add(SleepEvent(
        timestamp: current,
        duration: duration,
        type: type,
      ));

      current = current.add(duration);
    }

    return events;
  }

  double _computeScore({
    required int breathingInterruptions,
    required Duration longestPause,
    required Duration avgPauseDuration,
    required Duration totalSnoringDuration,
    required int gaspCount,
    required Duration totalDuration,
  }) {
    var score = 100.0;
    final totalHours = max(0.01, totalDuration.inMinutes / 60.0);

    // AHI-inspired: pause rate per hour (15/hr = max 30-point penalty)
    final pauseRate = breathingInterruptions / totalHours;
    score -= min(30, pauseRate * 2);

    // Longest pause severity (30s+ = max 15-point penalty)
    score -= min(15, longestPause.inSeconds * 0.5);

    // Average pause duration (15s+ avg = max 15-point penalty)
    score -= min(15, avgPauseDuration.inSeconds * 1.0);

    // Snoring as percentage of total recording
    final snorePercent = totalDuration.inSeconds > 0
        ? totalSnoringDuration.inSeconds / totalDuration.inSeconds
        : 0.0;
    score -= min(25, snorePercent * 50);

    // Recovery gasps = apnea signal
    score -= min(10, gaspCount * 1.5);

    return max(0, min(100, score)).roundToDouble();
  }

  String _riskLevel(double score) {
    if (score >= 80) return 'Low Risk';
    if (score >= 60) return 'Moderate';
    if (score >= 40) return 'Elevated';
    return 'High Risk';
  }

  List<String> _generateInsights({
    required double score,
    required double pauseRate,
    required int pauseCount,
    required Duration avgPauseDuration,
    required Duration longestPause,
    required Duration totalSnoringDuration,
    required Duration totalDuration,
    required int gaspCount,
    required int snoreCount,
  }) {
    final insights = <String>[];
    final totalHours = max(0.01, totalDuration.inMinutes / 60.0);
    final snoreMinutes = totalSnoringDuration.inSeconds ~/ 60;
    final snoreSeconds = totalSnoringDuration.inSeconds % 60;
    final snorePercent = totalDuration.inSeconds > 0
        ? (totalSnoringDuration.inSeconds / totalDuration.inSeconds * 100)
        : 0.0;

    // AHI-like insight
    if (pauseCount > 0) {
      String severity;
      if (pauseRate < 5) {
        severity = 'normal range';
      } else if (pauseRate < 15) {
        severity = 'mild sleep-disordered breathing';
      } else if (pauseRate < 30) {
        severity = 'moderate sleep-disordered breathing';
      } else {
        severity = 'severe sleep-disordered breathing';
      }
      insights.add(
          'Your pause rate of ${pauseRate.toStringAsFixed(1)}/hr suggests $severity (clinical threshold: 5/hr).');
    }

    // Snoring analysis with temporal pattern
    if (totalSnoringDuration.inSeconds > 0) {
      insights.add(
          'Snoring detected for ${snoreMinutes}m ${snoreSeconds}s (${snorePercent.toStringAsFixed(0)}% of recording) across $snoreCount episodes.');
    }

    // Apnea pattern detection
    if (pauseCount > 0 && gaspCount > 0) {
      insights.add(
          'Detected $pauseCount breathing pauses averaging ${avgPauseDuration.inSeconds}s each, with $gaspCount recovery gasps \u2014 a pattern consistent with obstructive sleep apnea.');
    } else if (pauseCount > 0) {
      insights.add(
          'Detected $pauseCount breathing pauses averaging ${avgPauseDuration.inSeconds}s each.');
    }

    // Longest pause warning
    if (longestPause.inSeconds >= 10) {
      insights.add(
          'Longest breathing pause was ${longestPause.inSeconds}s \u2014 pauses over 10s warrant medical attention.');
    }

    // Severity-specific recommendation
    if (score >= 80) {
      insights.add(
          'Your breathing was mostly stable. Continue monitoring to track patterns over time.');
    } else if (score >= 60) {
      insights.add(
          'Moderate breathing irregularities detected. Consider recording multiple nights to confirm patterns.');
    } else if (score >= 40) {
      insights.add(
          'Significant breathing disruptions detected. A sleep study (polysomnography) could provide clinical-grade assessment.');
    } else {
      insights.add(
          'Severe breathing disruptions detected. Strongly consider consulting a sleep specialist for evaluation.');
    }

    return insights;
  }

  SleepSession buildSessionFromEvents({
    required List<SleepEvent> events,
    required String fileName,
    DateTime? date,
  }) {
    if (events.isEmpty) {
      return generateDemoSession(date: date);
    }

    final sessionDate = date ?? DateTime.now().subtract(const Duration(hours: 8));

    final pauseEvents =
        events.where((e) => e.type == SleepEventType.pauseEvent).toList();
    final snoreEventsList =
        events.where((e) => e.type == SleepEventType.snoring).toList();
    final gaspEvents =
        events.where((e) => e.type == SleepEventType.recoveryGasp).toList();

    // Use first-to-last event timestamp span for total duration
    final totalDuration = events.length >= 2
        ? events.last.timestamp
            .add(events.last.duration)
            .difference(events.first.timestamp)
        : events.first.duration;

    final breathingInterruptions = pauseEvents.length;
    final snoreCount = snoreEventsList.length;
    final gaspCount = gaspEvents.length;

    final totalSnoringDuration = snoreEventsList.fold<Duration>(
      Duration.zero,
      (sum, e) => sum + e.duration,
    );

    final longestPause = pauseEvents.isEmpty
        ? Duration.zero
        : pauseEvents
            .map((e) => e.duration)
            .reduce((a, b) => a > b ? a : b);

    final avgPause = pauseEvents.isEmpty
        ? Duration.zero
        : Duration(
            milliseconds: pauseEvents
                    .map((e) => e.duration.inMilliseconds)
                    .reduce((a, b) => a + b) ~/
                pauseEvents.length);

    final totalHours = totalDuration.inMinutes / 60.0;
    final pauseFrequency =
        totalHours > 0 ? breathingInterruptions / totalHours : 0.0;

    final breathingScore = _computeScore(
      breathingInterruptions: breathingInterruptions,
      longestPause: longestPause,
      avgPauseDuration: avgPause,
      totalSnoringDuration: totalSnoringDuration,
      gaspCount: gaspCount,
      totalDuration: totalDuration,
    );

    final riskLevel = _riskLevel(breathingScore);
    final snoreIntensity = min(1.0, snoreCount / 30.0);

    return SleepSession(
      id: 'session_${sessionDate.millisecondsSinceEpoch}',
      date: sessionDate,
      fileName: fileName,
      totalDuration: totalDuration,
      breathingScore: breathingScore,
      riskLevel: riskLevel,
      breathingInterruptions: breathingInterruptions,
      longestPause: longestPause,
      snoreEvents: snoreCount,
      avgPauseDuration: avgPause,
      pauseFrequency: pauseFrequency,
      snoreIntensity: snoreIntensity,
      aiInsights: _generateInsights(
        score: breathingScore,
        pauseRate: pauseFrequency,
        pauseCount: breathingInterruptions,
        avgPauseDuration: avgPause,
        longestPause: longestPause,
        totalSnoringDuration: totalSnoringDuration,
        totalDuration: totalDuration,
        gaspCount: gaspCount,
        snoreCount: snoreCount,
      ),
      events: events,
      totalSnoringDuration: totalSnoringDuration,
      recoveryGaspEvents: gaspCount,
    );
  }

  List<SleepSession> generateSessionHistory(int count) {
    final sessions = <SleepSession>[];
    for (var i = 0; i < count; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      sessions
          .add(generateDemoSession(date: date.copyWith(hour: 22, minute: 30)));
    }
    return sessions;
  }
}
