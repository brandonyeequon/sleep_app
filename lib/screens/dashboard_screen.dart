import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/breathing_score_card.dart';
import '../widgets/event_breakdown_card.dart';
import '../widgets/timeline_chart.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/upload_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SleepProvider>();
    final session = provider.currentSession;

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentTeal),
      );
    }

    if (session == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.nightlight_round,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No sleep recordings yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 24),
            const UploadButton(),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sleep Dashboard',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Night of ${DateFormat('EEEE, MMMM d, yyyy').format(session.date)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const UploadButton(),
            ],
          ),
          const SizedBox(height: 28),

          // Top row: Score card + Event breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: BreathingScoreCard(session: session),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: EventBreakdownCard(session: session),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Timeline chart
          TimelineChart(session: session),
          const SizedBox(height: 20),

          // AI Insights
          AiInsightsCard(insights: session.aiInsights),
        ],
      ),
    );
  }
}
