import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:glass/glass.dart';
import 'package:hive_ce/hive.dart';

class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen> {
  DateTime _lastPeriod = DateTime.now().subtract(const Duration(days: 12));
  int _cycleLength = 28;
  final int _daysUntilNext = 16;
  int _selectedMood = 0;
  final Set<String> _selectedSymptoms = {};
  late Box _periodBox;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _periodBox = await Hive.openBox('period_tracker');
    _loadData();
  }

  void _loadData() {
    setState(() {
      final lastDateStr = _periodBox.get('last_period', defaultValue: '');
      if (lastDateStr.isNotEmpty) _lastPeriod = DateTime.parse(lastDateStr);
      _cycleLength = _periodBox.get('cycle_length', defaultValue: 28);
      _loading = false;
    });
  }

  void _saveData() {
    _periodBox.put('last_period', _lastPeriod.toIso8601String());
    _periodBox.put('cycle_length', _cycleLength);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A0B16) : const Color(0xFFFFF0F5),
      body: Stack(
        children: [
          _BackgroundGlow(color: Colors.pinkAccent.withValues(alpha: 0.1)),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar( isDark),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildPeriodStatus( isDark),
                        const SizedBox(height: 30),
                        _buildMoodTracker( isDark),
                        const SizedBox(height: 30),
                        _buildSymptomLogger( isDark),
                        const SizedBox(height: 30),
                        _buildInsightCard( isDark),
                        const SizedBox(height: 120),
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

  Widget _buildAppBar( bool isDark) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : Colors.black87)),
      title: Text((getTranslated('smartPeriodAssistant', context) ?? 'smartPeriodAssistant'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.pinkAccent)),
      actions: [
        IconButton(onPressed: () => _showSettings(isDark), icon: Icon(Icons.settings, color: isDark ? Colors.white70 : Colors.black54)),
      ],
    );
  }

  Widget _buildPeriodStatus( bool isDark) {
    return Container(
      width: 250, height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$_daysUntilNext', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          Text((getTranslated('daysLabel', context) ?? 'daysLabel'), style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 5),
          Text((getTranslated('remainingDays', context) ?? 'remainingDays'), style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black45)),
          const SizedBox(height: 25),
          Text((getTranslated('menstrualPhase', context) ?? 'menstrualPhase'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white : Colors.pinkAccent, foregroundColor: isDark ? Colors.pinkAccent : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: Text((getTranslated('startLoggingPeriod', context) ?? 'startLoggingPeriod')),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildMoodTracker( bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text((getTranslated('howDoYouFeelToday', context) ?? 'howDoYouFeelToday'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MoodIcon('😊', (getTranslated('moodHappy', context) ?? 'moodHappy'), _selectedMood == 0, () => setState(() => _selectedMood = 0), isDark),
            _MoodIcon('😐', (getTranslated('moodBalanced', context) ?? 'moodBalanced'), _selectedMood == 1, () => setState(() => _selectedMood = 1), isDark),
            _MoodIcon('😔', (getTranslated('moodSad', context) ?? 'moodSad'), _selectedMood == 2, () => setState(() => _selectedMood = 2), isDark),
            _MoodIcon('😫', (getTranslated('moodTired', context) ?? 'moodTired'), _selectedMood == 3, () => setState(() => _selectedMood = 3), isDark),
            _MoodIcon('😡', (getTranslated('moodAngry', context) ?? 'moodAngry'), _selectedMood == 4, () => setState(() => _selectedMood = 4), isDark),
          ],
        ),
      ],
    );
  }

  Widget _MoodIcon(String emoji, String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isSelected ? Colors.pinkAccent : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)), borderRadius: BorderRadius.circular(16)),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSymptomLogger( bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SymptomChip((getTranslated('symptomCramps', context) ?? 'symptomCramps'), Icons.flash_on, isDark),
        _SymptomChip((getTranslated('symptomHeadache', context) ?? 'symptomHeadache'), Icons.psychology, isDark),
        _SymptomChip((getTranslated('symptomFatigue', context) ?? 'symptomFatigue'), Icons.battery_alert, isDark),
        _SymptomChip((getTranslated('symptomInsomnia', context) ?? 'symptomInsomnia'), Icons.bedtime, isDark),
        _SymptomChip((getTranslated('symptomAppetite', context) ?? 'symptomAppetite'), Icons.restaurant, isDark),
      ],
    );
  }

  Widget _SymptomChip(String label, IconData icon, bool isDark) {
    final isSelected = _selectedSymptoms.contains(label);
    return GestureDetector(
      onTap: () => setState(() => isSelected ? _selectedSymptoms.remove(label) : _selectedSymptoms.add(label)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? Colors.pinkAccent : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.pinkAccent),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard( bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.pinkAccent, size: 20),
              const SizedBox(width: 10),
              Text((getTranslated('cycleInsightTitle', context) ?? 'cycleInsightTitle'), style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text((getTranslated('cycleInsightDesc', context) ?? 'cycleInsightDesc'), style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, height: 1.5)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  void _showSettings(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1B24) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingRow((getTranslated('lastPeriodDateLabel', context) ?? 'lastPeriodDateLabel'), '${_lastPeriod.day}/${_lastPeriod.month}/${_lastPeriod.year}', () async {
              final d = await showDatePicker(context: context, initialDate: _lastPeriod, firstDate: DateTime(2020), lastDate: DateTime.now());
              if (d != null) {
                setState(() => _lastPeriod = d);
                _saveData();
              }
            }, isDark),
            const SizedBox(height: 20),
            _buildSettingRow((getTranslated('cycleLengthLabel', context) ?? 'cycleLengthLabel'), '$_cycleLength ${(getTranslated('daysUnitLabel', context) ?? 'daysUnitLabel')}', () {}, isDark),
            Slider(
              value: _cycleLength.toDouble(), min: 21, max: 35, activeColor: Colors.pinkAccent,
              onChanged: (v) {
                setState(() => _cycleLength = v.toInt());
                _saveData();
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String title, String val, VoidCallback onTap, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        TextButton(onPressed: onTap, child: Text(val, style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold))),
      ],
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  final Color color;
  const _BackgroundGlow({required this.color});
  @override
  Widget build(BuildContext context) {
    return Positioned(top: -100, right: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: color)).asGlass(blurX: 100, blurY: 100));
  }
}
