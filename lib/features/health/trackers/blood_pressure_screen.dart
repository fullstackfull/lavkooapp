import 'package:intl/intl.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/health_database_helper.dart';

class BloodPressureScreen extends StatefulWidget {
  const BloodPressureScreen({super.key});

  @override
  State<BloodPressureScreen> createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await HealthDatabaseHelper.instance.getRecordsByType('blood_pressure');
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
      });
    }
  }

  Future<void> _saveData(double sys, double dia) async {
    await HealthDatabaseHelper.instance.insertRecord('blood_pressure', sys, val2: dia);
    
    // Also update health score metric to give points for tracking BP
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await HealthDatabaseHelper.instance.updateDailyMetric(date, 'blood_pressure', sys);
    
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((getTranslated('readingSaved', context) ?? 'readingSaved'))));
    }
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
                  _buildHistoryList(isDark),
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
      title: Text((getTranslated('bloodPressure', context) ?? 'bloodPressure'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent)),
    );
  }

  Widget _buildMainCard() {
    String latestBP = '--/--';
    String status = '--';
    if (_records.isNotEmpty) {
      final last = _records.first;
      int sys = (last['value1'] as num).toInt();
      int dia = (last['value2'] as num).toInt();
      latestBP = '$sys/$dia';
      
      if (sys < 90 || dia < 60) status = getTranslated('low', context) ?? 'Low';
      else if (sys > 120 || dia > 80) status = getTranslated('high', context) ?? 'High';
      else status = getTranslated('normal', context) ?? 'Normal';
    }

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.redAccent, Colors.orangeAccent]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text(latestBP, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
          Text((getTranslated('mmHg', context) ?? 'mmHg'), style: const TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 20),
          Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
    );
  }

  Widget _buildHistoryList(bool isDark) {
    if (_records.isEmpty) {
      return Center(child: Text(getTranslated('no_data', context) ?? 'No Data', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text((getTranslated('todayLogs', context) ?? 'todayLogs'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _records.length,
          itemBuilder: (context, index) {
            final rec = _records[index];
            final sys = (rec['value1'] as num).toInt();
            final dia = (rec['value2'] as num).toInt();
            final time = DateFormat('hh:mm a').format(DateTime.parse(rec['timestamp']));
            return _buildHistoryItem('$sys/$dia ${(getTranslated('mmHg', context) ?? 'mmHg')}', time, isDark);
          },
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
          const Icon(Icons.circle, size: 10, color: Colors.redAccent),
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
    final sysCtrl = TextEditingController();
    final diaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F1B24) : Colors.white,
        title: Text((getTranslated('enterBPReading', context) ?? 'enterBPReading'), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sysCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: (getTranslated('systolic', context) ?? 'systolic'), hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38))),
            TextField(controller: diaCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: (getTranslated('diastolic', context) ?? 'diastolic'), hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text((getTranslated('cancel', context) ?? 'cancel'))),
          ElevatedButton(
            onPressed: () {
              final sys = double.tryParse(sysCtrl.text);
              final dia = double.tryParse(diaCtrl.text);
              if (sys != null && dia != null) {
                _saveData(sys, dia);
              }
              Navigator.pop(context);
            },
            child: Text((getTranslated('save', context) ?? 'save')),
          ),
        ],
      ),
    );
  }
}
