import 'package:flutter/material.dart';

import '../models/sleep_event.dart';
import '../models/sleep_session.dart';
import '../theme/app_theme.dart';

/// A lightweight timeline chart that avoids heavy chart dependencies.
///
/// It renders a series of vertical bars (one per [SleepEvent]) and adds a few
/// time labels along the bottom.
class TimelineChart extends StatelessWidget {
  final SleepSession session;

  const TimelineChart({super.key, required this.session});

  static const double _mobileBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;
    final cardPadding = isMobile ? 16.0 : 24.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.timeline_rounded,
                  color: AppColors.accentTeal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Breathing Timeline',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!isMobile) ...[
                  const Spacer(),
                  const _Legend(),
                ],
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: 12),
              const _Legend(),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: isMobile ? 150 : 180,
              child: _TimelineCanvas(session: session),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCanvas extends StatelessWidget {
  final SleepSession session;

  const _TimelineCanvas({required this.session});

  @override
  Widget build(BuildContext context) {
    final events = session.events;
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No events yet',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final labels = _buildTimeLabels(constraints.maxWidth);

        return Stack(
          children: [
            // The painted bars
            Positioned.fill(
              child: CustomPaint(
                painter: _TimelinePainter(session: session),
              ),
            ),

            // Bottom labels
            ...labels,
          ],
        );
      },
    );
  }

  List<Widget> _buildTimeLabels(double width) {
    final events = session.events;
    final count = events.length;

    // ~8 labels across, but never less than 1.
    final step = (count / 8).ceil().clamp(1, count);

    final widgets = <Widget>[];
    for (int i = 0; i < count; i += step) {
      final e = events[i];
      final hour = e.timestamp.hour;
      final minute = e.timestamp.minute.toString().padLeft(2, '0');

      final x = (i / (count - 1)) * width;
      widgets.add(
        Positioned(
          left: (x - 18).clamp(0, width - 36),
          bottom: 0,
          child: Text(
            '$hour:$minute',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _TimelinePainter extends CustomPainter {
  final SleepSession session;

  const _TimelinePainter({required this.session});

  @override
  void paint(Canvas canvas, Size size) {
    final events = session.events;
    if (events.isEmpty) return;

    // Apple Watch-ish look:
    // - Group adjacent events of the same type into rounded "pills"
    // - Place pills on discrete vertical lanes
    // - Add subtle glow + faint grid

    final chartHeight = size.height - 20; // leave room for labels
    final lanes = _lanes(chartHeight);
    final segments = _buildSegments(events);

    _paintGrid(canvas, Size(size.width, chartHeight));

    // Convert event indices -> x positions
    double xForIndex(int idx) {
      if (events.length <= 1) return 0;
      return (idx / (events.length - 1)) * size.width;
    }

    // Connection stroke between lanes (thin vertical "link")
    final linkPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    // Draw segments
    for (int s = 0; s < segments.length; s++) {
      final seg = segments[s];
      final type = seg.type;
      final lane = lanes[type]!;

      // Pad a bit so pills don't touch edge-to-edge
      final left = xForIndex(seg.start) + 1;
      final right = xForIndex(seg.end) - 1;
      final width = (right - left).clamp(6.0, size.width);

      final rect = Rect.fromLTWH(
        left,
        lane.centerY - (lane.height / 2),
        width,
        lane.height,
      );
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(lane.height));

      final color = _eventColor(type);

      // Soft glow
      final glow = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(rrect, glow);

      // Solid pill
      final fill = Paint()..color = color;
      canvas.drawRRect(rrect, fill);

      // Link to next segment (vertical connector like Apple stages)
      if (s < segments.length - 1) {
        final next = segments[s + 1];
        final x = xForIndex(seg.end);
        final y1 = lane.centerY;
        final y2 = lanes[next.type]!.centerY;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), linkPaint);
      }
    }

    // Baseline
    final baselinePaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      baselinePaint,
    );
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    // Vertical grid ~10 columns
    const cols = 10;
    for (int i = 1; i < cols; i++) {
      final x = (i / cols) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal grid (faint)
    const rows = 4;
    for (int i = 1; i < rows; i++) {
      final y = (i / rows) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  List<_Segment> _buildSegments(List<SleepEvent> events) {
    final segments = <_Segment>[];
    if (events.isEmpty) return segments;

    int start = 0;
    var current = events.first.type;

    for (int i = 1; i < events.length; i++) {
      final t = events[i].type;
      if (t != current) {
        segments.add(_Segment(start: start, end: i, type: current));
        start = i;
        current = t;
      }
    }
    segments.add(_Segment(start: start, end: events.length - 1, type: current));
    return segments;
  }

  Map<SleepEventType, _Lane> _lanes(double chartHeight) {
    // Four lanes stacked like Apple stages.
    final paddingTop = 10.0;
    final paddingBottom = 10.0;
    final usable = (chartHeight - paddingTop - paddingBottom).clamp(1.0, chartHeight);
    final step = usable / 4;

    // Lane pill heights (slightly varying for visual interest)
    final hNormal = (step * 0.55).clamp(10.0, 22.0);
    final hSnore = (step * 0.65).clamp(12.0, 24.0);
    final hPause = (step * 0.70).clamp(12.0, 26.0);
    final hRecovery = (step * 0.75).clamp(14.0, 28.0);

    double centerForLane(int laneIndex) {
      // laneIndex: 0 bottom, 3 top
      final yTop = paddingTop + (3 - laneIndex) * step;
      return yTop + step / 2;
    }

    return {
      SleepEventType.normalBreathing: _Lane(centerY: centerForLane(0), height: hNormal),
      SleepEventType.snoring: _Lane(centerY: centerForLane(1), height: hSnore),
      SleepEventType.pauseEvent: _Lane(centerY: centerForLane(2), height: hPause),
      SleepEventType.recoveryGasp: _Lane(centerY: centerForLane(3), height: hRecovery),
    };
  }

  Color _eventColor(SleepEventType type) {
    switch (type) {
      case SleepEventType.normalBreathing:
        return AppColors.accentTeal;
      case SleepEventType.snoring:
        return AppColors.accentBlue;
      case SleepEventType.pauseEvent:
        return AppColors.accentRed;
      case SleepEventType.recoveryGasp:
        return AppColors.accentPurple;
    }
  }

  double _eventHeight(SleepEvent event) {
    // Normalized 0..1-ish signal for “intensity”.
    switch (event.type) {
      case SleepEventType.normalBreathing:
        return 0.25 + (event.duration.inSeconds / 600) * 0.25;
      case SleepEventType.snoring:
        return 0.45 + (event.duration.inSeconds / 120) * 0.25;
      case SleepEventType.pauseEvent:
        return 0.65 + (event.duration.inSeconds / 30) * 0.25;
      case SleepEventType.recoveryGasp:
        return 0.9;
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.session != session;
  }
}

class _Lane {
  final double centerY;
  final double height;

  const _Lane({required this.centerY, required this.height});
}

class _Segment {
  final int start;
  final int end;
  final SleepEventType type;

  const _Segment({required this.start, required this.end, required this.type});
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _LegendDot(color: AppColors.accentTeal, label: 'Normal'),
        SizedBox(width: 12),
        _LegendDot(color: AppColors.accentBlue, label: 'Snoring'),
        SizedBox(width: 12),
        _LegendDot(color: AppColors.accentRed, label: 'Pause'),
        SizedBox(width: 12),
        _LegendDot(color: AppColors.accentPurple, label: 'Recovery'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
