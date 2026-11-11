import 'package:intl/intl.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:glass/glass.dart';
import 'package:hive_ce/hive.dart';
import '../data/health_database_helper.dart';

class WaterReminderScreen extends StatefulWidget {
  const WaterReminderScreen({super.key});

  @override
  State<WaterReminderScreen> createState() => _WaterReminderScreenState();
}

class _WaterReminderScreenState extends State<WaterReminderScreen> {
  int _currentIntake = 0; // In ml
  int _dailyGoal = 2500; // Default in ml
  int _streak = 0;
  late Box _waterBox;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _waterBox = await Hive.openBox('water');
    
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final summary = await HealthDatabaseHelper.instance.getDailySummary(date);
    
    setState(() {
      _currentIntake = summary != null ? ((summary['water_ml'] as num?)?.toInt() ?? 0) : 0;
      _dailyGoal = _waterBox.get('goal', defaultValue: 2500);
      _streak = _waterBox.get('streak', defaultValue: 0);
      _loading = false;
    });
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return 'intake_${now.year}_${now.month}_${now.day}';
  }

  Future<void> _addWater(int amount) async {
    setState(() {
      _currentIntake += amount;
    });
    
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await HealthDatabaseHelper.instance.updateDailyMetric(date, 'water_ml', _currentIntake);
    
    _checkGoalReached();
  }

  void _checkGoalReached() {
    if (_currentIntake >= _dailyGoal) {
      final lastGoalDate = _waterBox.get('last_goal_date', defaultValue: '');
      final todayStr = _getTodayKey();
      if (lastGoalDate != todayStr) {
        setState(() => _streak++);
        _waterBox.put('streak', _streak);
        _waterBox.put('last_goal_date', todayStr);
      }
    }
  }

  void _showGoalDialog() {
    final controller = TextEditingController(text: _dailyGoal.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text((getTranslated('editDailyGoal', context) ?? 'editDailyGoal')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: (getTranslated('mlUnit', context) ?? 'mlUnit')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text((getTranslated('cancel', context) ?? 'cancel'))),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) {
                setState(() => _dailyGoal = val);
                _waterBox.put('goal', _dailyGoal);
              }
              Navigator.pop(ctx);
            },
            child: Text((getTranslated('save', context) ?? 'save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = (_currentIntake / _dailyGoal).clamp(0.0, 1.0);

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F7FF),
      body: Stack(
        children: [
          // 🌊 Animated Liquid Background
          _LiquidBackground(progress: progress),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                const SizedBox(height: 20),
                _buildStreakBadge(),
                const Spacer(),
                _buildProgressIndicator(progress),
                const Spacer(),
                _buildActionButtons(),
                const SizedBox(height: 40),
                _buildInsightCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          Expanded(
            child: Text(
              (getTranslated('hydrationIntelligence', context) ?? 'hydrationIntelligence'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () => _showGoalDialog(),
            icon: const Icon(CupertinoIcons.settings, color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Text(
            '${(getTranslated('streakLabel', context) ?? 'streakLabel')}: $_streak ${(getTranslated('daysUnitLabel', context) ?? 'daysUnitLabel')}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildProgressIndicator(double progress) {
    return Column(
      children: [
        Text(
          '${(_currentIntake / 1000).toStringAsFixed(1)} L',
          style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.blueAccent),
        ),
        Text(
          '${(getTranslated('goalLabel', context) ?? 'goalLabel')}: ${(_dailyGoal / 1000).toStringAsFixed(1)} ${(getTranslated('literUnit', context) ?? 'literUnit')}',
          style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _QuickAddButton(amount: 200, label: '200ml', onTap: () => _addWater(200)),
        const SizedBox(width: 15),
        _QuickAddButton(amount: 330, label: '330ml', onTap: () => _addWater(330), isLarge: true),
        const SizedBox(width: 15),
        _QuickAddButton(amount: 500, label: '500ml', onTap: () => _addWater(500)),
      ],
    );
  }

  Widget _buildInsightCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.info_circle_fill, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                (getTranslated('waterInsightDesc', context) ?? 'waterInsightDesc'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ).asGlass(blurX: 10, blurY: 10).animate().fadeIn(delay: 500.ms),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final int amount;
  final String label;
  final VoidCallback onTap;
  final bool isLarge;

  const _QuickAddButton({required this.amount, required this.label, required this.onTap, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: isLarge ? 80 : 65,
            height: isLarge ? 80 : 65,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: isLarge ? 1.0 : 0.2),
              shape: BoxShape.circle,
              boxShadow: isLarge ? [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))] : null,
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.add, color: isLarge ? Colors.white : Colors.blueAccent, size: isLarge ? 30 : 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().scale();
  }
}

class _LiquidBackground extends StatelessWidget {
  final double progress;
  const _LiquidBackground({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
        height: MediaQuery.of(context).size.height * (progress * 0.85),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withValues(alpha: 0.3),
              Colors.blue.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: CustomPaint(painter: _WavePainter()),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Simple wave effect can be added here with more complex paths
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
