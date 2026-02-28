import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/sleep_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SleepProvider>();
    final sessions = provider.sessions;

    // Build a set of dates that have sessions
    final sessionDates = <DateTime>{};
    for (final s in sessions) {
      sessionDates.add(DateTime(s.date.year, s.date.month, s.date.day));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sleep History',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          const Text(
            'Review your past sleep recordings',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TableCalendar(
                firstDay: DateTime(2024, 1, 1),
                lastDay: DateTime.now().add(const Duration(days: 1)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final normalized =
                        DateTime(date.year, date.month, date.day);
                    if (sessionDates.contains(normalized)) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.accentTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                calendarStyle: const CalendarStyle(
                  defaultTextStyle: TextStyle(color: AppColors.textPrimary),
                  weekendTextStyle: TextStyle(color: AppColors.textSecondary),
                  outsideTextStyle: TextStyle(color: AppColors.textMuted),
                  todayDecoration: BoxDecoration(
                    color: AppColors.sidebarActive,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.accentTeal,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: AppColors.textPrimary),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: AppColors.textSecondary,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                  weekendStyle: TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Past Sessions',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          ...sessions.map((session) => _SessionTile(
                date: session.date,
                score: session.breathingScore,
                riskLevel: session.riskLevel,
                duration: session.totalDuration,
                onTap: () => provider.selectSession(session),
              )),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final DateTime date;
  final double score;
  final String riskLevel;
  final Duration duration;
  final VoidCallback onTap;

  const _SessionTile({
    required this.date,
    required this.score,
    required this.riskLevel,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppTheme.scoreColor(score);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      score.toInt().toString(),
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d').format(date),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${hours}h ${minutes}m · $riskLevel',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
