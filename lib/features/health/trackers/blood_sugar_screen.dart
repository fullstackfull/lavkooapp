import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:hive_ce/hive.dart';

class BloodSugarScreen extends StatefulWidget {
  const BloodSugarScreen({super.key});

  @override
  State<BloodSugarScreen> createState() => _BloodSugarScreenState();
}

class _BloodSugarScreenState extends State<BloodSugarScreen> {
  bool _loading = true;
  late Box _readingBox;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _readingBox = await Hive.openBox('health_readings');
    setState(() => _loading = false);
  }

  void _saveData() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((getTranslated('readingSaved', context) ?? 'readingSaved'))));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: const Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildMainCard(),
                  const SizedBox(height: 30),
                  _buildQuickAddButtons(),
                  const SizedBox(height: 30),
                  _buildHistoryList( isDark),
                  const SizedBox(height: 120),
                ],
              ),
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
      title: Text((getTranslated('bloodSugar', context) ?? 'bloodSugar'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.cyanAccent)),
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text('105', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
          Text((getTranslated('mgDl', context) ?? 'mgDl'), style: const TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 20),
          Text((getTranslated('normal', context) ?? 'normal'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildQuickAddButtons() {
    return SizedBox(
      width: double.infinity, height: 60,
      child: ElevatedButton.icon(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text((getTranslated('addReading', context) ?? 'addReading'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
    );
  }

  Widget _buildHistoryList( bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text((getTranslated('todayLogs', context) ?? 'todayLogs'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 2,
          itemBuilder: (context, index) => _buildHistoryItem('105 ${(getTranslated('mgDl', context) ?? 'mgDl')}', '08:00 AM', isDark),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(String val, String time, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 10, color: Colors.cyanAccent),
          const SizedBox(width: 15),
          Text(val, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(time, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F1B24) : Colors.white,
        title: Text((getTranslated('enterSugarReading', context) ?? 'enterSugarReading'), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(keyboardType: TextInputType.number, decoration: InputDecoration(hintText: (getTranslated('readingValue', context) ?? 'readingValue'), hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text((getTranslated('cancel', context) ?? 'cancel'))),
          ElevatedButton(onPressed: () { _saveData(); Navigator.pop(context); }, child: Text((getTranslated('save', context) ?? 'save'))),
        ],
      ),
    );
  }
}
