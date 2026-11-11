import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';


class DailyStepsScreen extends StatefulWidget {
  const DailyStepsScreen({super.key});

  @override
  State<DailyStepsScreen> createState() => _DailyStepsScreenState();
}

class _DailyStepsScreenState extends State<DailyStepsScreen> {
  final int _stepGoal = 10000;
  final int _currentSteps = 7432;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = _currentSteps / _stepGoal;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProgressCircle(theme, progress),
                    const SizedBox(height: 30),
                    _buildStatsRow(theme),
                    const SizedBox(height: 30),
                    _buildHistoryChart(theme, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.orange),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              (getTranslated('daily_steps', context) ?? 'daily_steps'),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildProgressCircle(ThemeData theme, double progress) {
    return Container(
      height: 250,
      width: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.primaryColor.withValues(alpha: 0.05),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 220,
            width: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 15,
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              color: Colors.orange,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.flame_fill, color: Colors.orange, size: 40),
              const SizedBox(height: 8),
              Text(
                '$_currentSteps',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                children: [
                  Text(
                    '$_currentSteps / $_stepGoal ',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                  Text(
                    getTranslated('stepsOfGoal', context) ?? (Localizations.localeOf(context).languageCode == 'ar' ? 'خطوة' : 'steps'),
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(CupertinoIcons.placemark_fill, '5.2', (getTranslated('kmUnit', context) ?? 'kmUnit'), Colors.blue),
        _buildStatItem(CupertinoIcons.bolt_fill, '342', (getTranslated('caloriesUnit', context) ?? 'caloriesUnit'), Colors.red),
        _buildStatItem(CupertinoIcons.clock_fill, '45', (getTranslated('minutesUnit', context) ?? 'minutesUnit'), Colors.green),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String unit, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(unit, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Widget _buildHistoryChart(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((getTranslated('weeklyActivity', context) ?? 'weeklyActivity'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = [(getTranslated('monShort', context) ?? 'monShort'), (getTranslated('tueShort', context) ?? 'tueShort'), (getTranslated('wedShort', context) ?? 'wedShort'), (getTranslated('thuShort', context) ?? 'thuShort'), (getTranslated('friShort', context) ?? 'friShort'), (getTranslated('satShort', context) ?? 'satShort'), (getTranslated('sunShort', context) ?? 'sunShort')];
                        return Text(days[value.toInt() % 7], style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeGroupData(0, 5000),
                  _makeGroupData(1, 8000),
                  _makeGroupData(2, 6500),
                  _makeGroupData(3, 10000),
                  _makeGroupData(4, 7432),
                  _makeGroupData(5, 9000),
                  _makeGroupData(6, 11000),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.orange,
          width: 15,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 12000,
            color: Colors.orange.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

}
