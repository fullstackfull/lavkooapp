import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_ce/hive.dart';
import '../data/health_database_helper.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  late Box _sleepBox;
  bool _loading = true;
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  int _sleepScore = 85;
  List<Map<String, dynamic>> _sleepHistory = [];

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _sleepBox = await Hive.openBox('sleep_tracker');
    _loadData();
  }

  void _loadData() {
    setState(() {
      final bedH = _sleepBox.get('bed_h', defaultValue: 22);
      final bedM = _sleepBox.get('bed_m', defaultValue: 30);
      _bedTime = TimeOfDay(hour: bedH, minute: bedM);
      
      final wakeH = _sleepBox.get('wake_h', defaultValue: 6);
      final wakeM = _sleepBox.get('wake_m', defaultValue: 30);
      _wakeTime = TimeOfDay(hour: wakeH, minute: wakeM);
      
      final historyData = _sleepBox.get('history', defaultValue: []) as List;
      _sleepHistory = historyData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _calculateScore();
      _loading = false;
    });
  }

  void _calculateScore() {
    // Basic logic: 8 hours is 100%, earlier bedtime is better
    final duration = _getSleepDuration();
    var score = (duration / 8.0) * 100;
    if (_bedTime.hour < 23) score += 10;
    _sleepScore = score.clamp(0, 100).toInt();
  }

  double _getSleepDuration() {
    var bed = _bedTime.hour + (_bedTime.minute / 60.0);
    var wake = _wakeTime.hour + (_wakeTime.minute / 60.0);
    if (wake < bed) wake += 24;
    return wake - bed;
  }

  void _saveData() async {
    _sleepBox.put('bed_h', _bedTime.hour);
    _sleepBox.put('bed_m', _bedTime.minute);
    _sleepBox.put('wake_h', _wakeTime.hour);
    _sleepBox.put('wake_m', _wakeTime.minute);
    
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    _sleepHistory.removeWhere((e) => e['date'] == todayStr);
    _sleepHistory.add({'date': todayStr, 'duration': _getSleepDuration(), 'score': _sleepScore});
    if (_sleepHistory.length > 7) _sleepHistory.removeAt(0);
    _sleepBox.put('history', _sleepHistory);
    
    // Save to SQL Database for Central Hub
    await HealthDatabaseHelper.instance.updateDailyMetric(todayStr, 'sleep_hrs', _getSleepDuration());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((getTranslated('dailySleepSaved', context) ?? 'dailySleepSaved'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          if (isDark) _BackgroundStars(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, isDark),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildSleepScoreHeader(),
                        const SizedBox(height: 30),
                        _buildSleepSchedulePicker(context, isDark),
                        const SizedBox(height: 30),
                        _buildSleepInsightCard(isDark),
                        const SizedBox(height: 30),
                        _buildSleepTrendChart(isDark),
                        const SizedBox(height: 30),
                        _buildActionButtons(),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : Colors.black87)),
      title: Text((getTranslated('smartSleepCoach', context) ?? 'smartSleepCoach'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigoAccent)),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.nights_stay, color: Colors.amberAccent)),
      ],
    );
  }

  Widget _buildSleepScoreHeader() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF312E81), Color(0xFF1E1B4B)]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120, height: 120,
                child: CircularProgressIndicator(value: _sleepScore / 100, strokeWidth: 10, backgroundColor: Colors.white10, color: Colors.amberAccent, strokeCap: StrokeCap.round),
              ),
               Column(
                children: [
                  Text('$_sleepScore', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text((getTranslated('sleepQuality', context) ?? 'sleepQuality'), style: const TextStyle(fontSize: 10, color: Colors.white70)),
                ],
               ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "${getTranslated('hoursOfRest', context) ?? 'hoursOfRest'} ${_getSleepDuration().toStringAsFixed(1)}",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildSleepSchedulePicker(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(child: _TimeCard((getTranslated('bedtime', context) ?? 'bedtime'), _bedTime, Colors.indigoAccent, isDark, () async {
          final t = await showTimePicker(context: context, initialTime: _bedTime);
          if (t != null) setState(() { _bedTime = t; _calculateScore(); });
        })),
        const SizedBox(width: 15),
        Expanded(child: _TimeCard((getTranslated('wakeUp', context) ?? 'wakeUp'), _wakeTime, Colors.orangeAccent, isDark, () async {
          final t = await showTimePicker(context: context, initialTime: _wakeTime);
          if (t != null) setState(() { _wakeTime = t; _calculateScore(); });
        })),
      ],
    );
  }

  Widget _TimeCard(String title, TimeOfDay time, Color color, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 8),
            Text(time.format(context), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

   Widget _buildSleepInsightCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigoAccent.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.indigoAccent),
          const SizedBox(width: 15),
          Expanded(child: Text((getTranslated('sleepInsightSmart', context) ?? 'sleepInsightSmart'), style: TextStyle(color: isDark ? Colors.white70 : Colors.indigo[900], fontSize: 12, height: 1.4))),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSleepTrendChart(bool isDark) {
    if (_sleepHistory.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text((getTranslated('weeklySleepAnalysis', context) ?? 'weeklySleepAnalysis'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: LineChart(LineChartData(
            gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false),
            lineBarsData: [LineChartBarData(spots: _sleepHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['duration'].toDouble())).toList(), isCurved: true, color: Colors.indigoAccent, barWidth: 4, dotData: const FlDotData(show: true), belowBarData: BarAreaData(show: true, color: Colors.indigoAccent.withValues(alpha: 0.1)))]
          )),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        onPressed: _saveData,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: Text((getTranslated('saveTonightLog', context) ?? 'saveTonightLog'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _BackgroundStars extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(20, (i) => Positioned(
        top: (i * 50.0) % 800, left: (i * 80.0) % 400,
        child: const Icon(Icons.star, color: Colors.white10, size: 10).animate(onPlay: (c) => c.repeat()).scale(duration: 2.seconds, begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5)),
      )),
    );
  }
}
