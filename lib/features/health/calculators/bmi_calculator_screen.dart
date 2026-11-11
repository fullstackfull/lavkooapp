import 'package:syriapharmacy/localization/language_constrants.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:glass/glass.dart';
import 'package:hive_ce/hive.dart';

class BMICalculatorScreen extends StatefulWidget {
  const BMICalculatorScreen({super.key});

  @override
  State<BMICalculatorScreen> createState() => _BMICalculatorScreenState();
}
class _BMICalculatorScreenState extends State<BMICalculatorScreen> {
  double _height = 170;
  double _weight = 75;
  double _targetWeight = 70;
  late Box _bmiBox;
  bool _loading = true;
  List<Map<String, dynamic>> _weightHistory = [];

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _bmiBox = await Hive.openBox('bmi');
    _loadData();
  }

  void _loadData() {
    setState(() {
      _height = _bmiBox.get('height', defaultValue: 170.0);
      _weight = _bmiBox.get('weight', defaultValue: 75.0);
      _targetWeight = _bmiBox.get('target_weight', defaultValue: 70.0);
      final history = _bmiBox.get('history', defaultValue: []);
      _weightHistory = List<Map<String, dynamic>>.from(history);
      _loading = false;
    });
  }

  void _saveData() {
    _bmiBox.put('height', _height);
    _bmiBox.put('weight', _weight);
    _bmiBox.put('target_weight', _targetWeight);
    
    // Add to history if today's entry doesn't exist
    final today = DateTime.now().toIso8601String().substring(0, 10);
    _weightHistory.removeWhere((element) => element['date'] == today);
    _weightHistory.add({'date': today, 'weight': _weight});
    if (_weightHistory.length > 7) _weightHistory.removeAt(0); // Keep last 7 entries
    
    _bmiBox.put('history', _weightHistory);
  }

  double get _bmi => _weight / ((_height / 100) * (_height / 100));

  String _getBMIStatus() {
    if (_bmi < 18.5) return (getTranslated('underweight', context) ?? 'underweight');
    if (_bmi < 25) return (getTranslated('normalWeight', context) ?? 'normalWeight');
    if (_bmi < 30) return (getTranslated('overweight', context) ?? 'overweight');
    return (getTranslated('obese', context) ?? 'obese');
  }

  String _getCoachAdvice() {
    if (_bmi < 18.5) return (getTranslated('bmiAdviceUnderweight', context) ?? 'bmiAdviceUnderweight');
    if (_bmi < 25) return (getTranslated('bmiAdviceNormal', context) ?? 'bmiAdviceNormal');
    if (_bmi < 30) return (getTranslated('bmiAdviceOverweight', context) ?? 'bmiAdviceOverweight');
    return (getTranslated('bmiAdviceObese', context) ?? 'bmiAdviceObese');
  }

  Color _getStatusColor() {
    if (_bmi < 18.5) return Colors.blueAccent;
    if (_bmi < 25) return Colors.greenAccent;
    if (_bmi < 30) return Colors.orangeAccent;
    return Colors.redAccent;
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
          _BackgroundGlow(color: _getStatusColor().withValues(alpha: 0.1)),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildBMIGauge(context),
                        const SizedBox(height: 30),
                        _buildCoachCard(),
                        const SizedBox(height: 30),
                        _buildGoalTracker(),
                        const SizedBox(height: 30),
                        _buildWeightChart(),
                        const SizedBox(height: 30),
                        _buildInputs(isDark),
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

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
      ),
      title: Text((getTranslated('bmiCoach', context) ?? 'bmiCoach'), style: const TextStyle(fontWeight: FontWeight.w900)),
      actions: [
        IconButton(onPressed: _saveData, icon: const Icon(Icons.save_outlined, color: Colors.greenAccent)),
      ],
    );
  }

  Widget _buildBMIGauge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            _bmi.toStringAsFixed(1),
            style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: _getStatusColor()),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          Text(
            _getBMIStatus(),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _getStatusColor()),
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(colors: [Colors.blue, Colors.green, Colors.orange, Colors.red]),
                ),
              ),
              AnimatedPositioned(
                duration: 1.seconds,
                left: MediaQuery.of(context).size.width * (_bmi / 40).clamp(0.0, 0.8),
                child: const Icon(Icons.arrow_drop_up, color: Colors.white, size: 30),
              ),
            ],
          ),
        ],
      ),
    ).asGlass(blurX: 10, blurY: 10);
  }

  Widget _buildCoachCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Colors.blueAccent, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((getTranslated('coachAdvice', context) ?? 'coachAdvice'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(_getCoachAdvice(), style: const TextStyle(fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildGoalTracker() {
    final diff = _weight - _targetWeight;
    final progress = (1 - (diff.abs() / 20)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text((getTranslated('goalTracker', context) ?? 'goalTracker'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${(getTranslated('targetWeightLabel', context) ?? 'targetWeightLabel')}${_targetWeight.toInt()} kg', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 15),
        LinearProgressIndicator(
          value: progress,
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
          backgroundColor: Colors.white10,
          color: Colors.greenAccent,
        ),
        const SizedBox(height: 10),
        Text(
          diff > 0 ? '${(getTranslated('needToLose', context) ?? 'needToLose')}${diff.toStringAsFixed(1)} kg${(getTranslated('toReachGoal', context) ?? 'toReachGoal')}' : '${(getTranslated('needToGain', context) ?? 'needToGain')}${diff.abs().toStringAsFixed(1)} kg${(getTranslated('toReachGoal', context) ?? 'toReachGoal')}',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildWeightChart() {
    if (_weightHistory.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text((getTranslated('weightHistory', context) ?? 'weightHistory'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _weightHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['weight'].toDouble())).toList(),
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withValues(alpha: 0.1)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputs(bool isDark) {
    return Column(
      children: [
        _buildSlider((getTranslated('height', context) ?? 'height'), _height, 'cm', 100, 220, (v) => setState(() => _height = v)),
        const SizedBox(height: 20),
        _buildSlider((getTranslated('currentWeight', context) ?? 'currentWeight'), _weight, 'kg', 30, 200, (v) => setState(() => _weight = v)),
        const SizedBox(height: 20),
        _buildSlider((getTranslated('targetWeight', context) ?? 'targetWeight'), _targetWeight, 'kg', 30, 200, (v) => setState(() => _targetWeight = v)),
      ],
    );
  }

  Widget _buildSlider(String title, double value, String unit, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${value.toInt()} $unit', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent)),
          ],
        ),
        Slider(
          value: value, min: min, max: max,
          activeColor: Colors.blueAccent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  final Color color;
  const _BackgroundGlow({required this.color});
  @override
  Widget build(BuildContext context) {
    return Positioned(top: -100, left: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: color)).asGlass(blurX: 100, blurY: 100));
  }
}
