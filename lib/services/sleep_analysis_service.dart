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

    final breathingInterruptions = pauseEvents.length;
    final snoreCount = snoreEventsList.length;

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
      snoreCount: snoreCount,
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
      aiInsights: _generateInsights(breathingScore, pauseFrequency, snoreCount),
      events: events,
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
    required int snoreCount,
    required Duration totalDuration,
  }) {
    var score = 100.0;
    score -= breathingInterruptions * 1.5;
    score -= longestPause.inSeconds * 0.3;
    score -= snoreCount * 0.5;
    return max(0, min(100, score)).roundToDouble();
  }

  String _riskLevel(double score) {
    if (score >= 80) return 'Low Risk';
    if (score >= 60) return 'Moderate';
    if (score >= 40) return 'Elevated';
    return 'High Risk';
  }

  List<String> _generateInsights(
      double score, double pauseFrequency, int snoreCount) {
    final insights = <String>[];

    if (score >= 80) {
      insights.add(
          'Your breathing pattern was relatively stable throughout the night.');
    } else if (score >= 60) {
      insights.add(
          'Some irregular breathing patterns detected. Consider monitoring over multiple nights.');
    } else {
      insights.add(
          'Significant breathing irregularities detected. Consider consulting a sleep specialist.');
    }

    if (pauseFrequency > 5) {
      insights.add(
          'Breathing pause frequency of ${pauseFrequency.toStringAsFixed(1)}/hr exceeds normal range (< 5/hr).');
    }

    if (snoreCount > 15) {
      insights.add(
          'Elevated snoring episodes detected ($snoreCount events). Positional therapy may help.');
    }

    insights.add(
        'Recording quality was good. Consistent recording environment improves analysis accuracy.');

    return insights;
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
