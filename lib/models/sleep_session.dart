import 'sleep_event.dart';

class SleepSession {
  final String id;
  final DateTime date;
  final String fileName;
  final Duration totalDuration;
  final double breathingScore;
  final String riskLevel;
  final int breathingInterruptions;
  final Duration longestPause;
  final int snoreEvents;
  final Duration avgPauseDuration;
  final double pauseFrequency; // per hour
  final double snoreIntensity; // 0.0 - 1.0
  final List<String> aiInsights;
  final List<SleepEvent> events;
  final Duration totalSnoringDuration;
  final int recoveryGaspEvents;

  const SleepSession({
    required this.id,
    required this.date,
    required this.fileName,
    required this.totalDuration,
    required this.breathingScore,
    required this.riskLevel,
    required this.breathingInterruptions,
    required this.longestPause,
    required this.snoreEvents,
    required this.avgPauseDuration,
    required this.pauseFrequency,
    required this.snoreIntensity,
    required this.aiInsights,
    required this.events,
    this.totalSnoringDuration = Duration.zero,
    this.recoveryGaspEvents = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'fileName': fileName,
      'totalDuration': totalDuration.inMilliseconds,
      'breathingScore': breathingScore,
      'riskLevel': riskLevel,
      'breathingInterruptions': breathingInterruptions,
      'longestPause': longestPause.inMilliseconds,
      'snoreEvents': snoreEvents,
      'avgPauseDuration': avgPauseDuration.inMilliseconds,
      'pauseFrequency': pauseFrequency,
      'snoreIntensity': snoreIntensity,
      'aiInsights': aiInsights,
      'events': events.map((e) => e.toMap()).toList(),
      'totalSnoringDuration': totalSnoringDuration.inMilliseconds,
      'recoveryGaspEvents': recoveryGaspEvents,
    };
  }

  factory SleepSession.fromMap(Map<String, dynamic> map) {
    return SleepSession(
      id: map['id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      fileName: map['fileName'] as String,
      totalDuration: Duration(milliseconds: map['totalDuration'] as int),
      breathingScore: (map['breathingScore'] as num).toDouble(),
      riskLevel: map['riskLevel'] as String,
      breathingInterruptions: map['breathingInterruptions'] as int,
      longestPause: Duration(milliseconds: map['longestPause'] as int),
      snoreEvents: map['snoreEvents'] as int,
      avgPauseDuration: Duration(milliseconds: map['avgPauseDuration'] as int),
      pauseFrequency: (map['pauseFrequency'] as num).toDouble(),
      snoreIntensity: (map['snoreIntensity'] as num).toDouble(),
      aiInsights: List<String>.from(map['aiInsights'] as List),
      events: (map['events'] as List)
          .map((e) => SleepEvent.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalSnoringDuration: Duration(
          milliseconds: (map['totalSnoringDuration'] as int?) ?? 0),
      recoveryGaspEvents: (map['recoveryGaspEvents'] as int?) ?? 0,
    );
  }
}
