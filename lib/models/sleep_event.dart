enum SleepEventType {
  normalBreathing,
  snoring,
  pauseEvent,
  recoveryGasp,
}

class SleepEvent {
  final DateTime timestamp;
  final Duration duration;
  final SleepEventType type;

  const SleepEvent({
    required this.timestamp,
    required this.duration,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
      'type': type.index,
    };
  }

  factory SleepEvent.fromMap(Map<String, dynamic> map) {
    return SleepEvent(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      duration: Duration(milliseconds: map['duration'] as int),
      type: SleepEventType.values[map['type'] as int],
    );
  }
}
