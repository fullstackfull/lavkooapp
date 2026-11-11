import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:glass/glass.dart';
import 'package:hive_ce/hive.dart';

import 'package:syriapharmacy/features/health/domain/services/notification_service.dart';


// ─── Medication Model ────────────────────────────────────────────────────────

class Medication {
  final int id;
  final String name;
  final String dose;
  final int hour;
  final int minute;
  final String repeat;
  int takenCount;
  int skippedCount;
  DateTime lastActionDate;

  Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.hour,
    required this.minute,
    required this.repeat,
    this.takenCount = 0,
    this.skippedCount = 0,
    DateTime? lastActionDate,
  }) : lastActionDate = lastActionDate ?? DateTime.now().subtract(const Duration(days: 1));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dose': dose,
        'hour': hour,
        'minute': minute,
        'repeat': repeat,
        'takenCount': takenCount,
        'skippedCount': skippedCount,
        'lastActionDate': lastActionDate.toIso8601String(),
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'],
        name: json['name'],
        dose: json['dose'],
        hour: json['hour'],
        minute: json['minute'],
        repeat: json['repeat'],
        takenCount: json['takenCount'] ?? 0,
        skippedCount: json['skippedCount'] ?? 0,
        lastActionDate: DateTime.parse(json['lastActionDate']),
      );

  double get adherenceScore {
    final total = takenCount + skippedCount;
    if (total == 0) return 0.0;
    return takenCount / total;
  }
}

// ─── Screen Implementation ───────────────────────────────────────────────────

class MedicationReminderScreen extends StatefulWidget {
  const MedicationReminderScreen({super.key});

  @override
  State<MedicationReminderScreen> createState() => _MedicationReminderScreenState();
}

class _MedicationReminderScreenState extends State<MedicationReminderScreen> {
  final List<Medication> _medications = [];
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedRepeat = 'Daily'; // Will be translated in UI
  late Box _medsBox;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _medsBox = await Hive.openBox('medications');
    _loadMeds();
  }

  void _loadMeds() {
    final data = _medsBox.get('list', defaultValue: []);
    setState(() {
      _medications.clear();
      for (var item in data) {
        _medications.add(Medication.fromJson(Map<String, dynamic>.from(item)));
      }
      _loading = false;
    });
  }

  void _saveMeds() {
    final data = _medications.map((e) => e.toJson()).toList();
    _medsBox.put('list', data);
  }

  void _addMedication() async {
    if (_nameController.text.isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);
    if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));

    await NotificationService().scheduleMedicationReminder(
      id: id,
      title: '${(getTranslated('medicationReminderTime', context) ?? 'medicationReminderTime')}${_nameController.text}',
      body: '${(getTranslated('timeForDose', context) ?? 'timeForDose')}${_doseController.text}${(getTranslated('ofMed', context) ?? 'ofMed')}${_nameController.text}',
      scheduledDate: scheduledDate,
    );

    setState(() {
      _medications.add(Medication(
        id: id,
        name: _nameController.text,
        dose: _doseController.text,
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        repeat: _selectedRepeat,
      ));
    });

    _saveMeds();
    _nameController.clear();
    _doseController.clear();
    if (mounted) Navigator.pop(context);
  }

  void _markAction(int index, bool taken) {
    setState(() {
      if (taken) {
        _medications[index].takenCount++;
      } else {
        _medications[index].skippedCount++;
      }
      _medications[index].lastActionDate = DateTime.now();
    });
    _saveMeds();
  }

  void _deleteMedication(int index) {
    setState(() => _medications.removeAt(index));
    _saveMeds();
  }

  double get _overallAdherence {
    if (_medications.isEmpty) return 0.0;
    double sum = 0;
    for (var m in _medications) {
      sum += m.adherenceScore;
    }
    return sum / _medications.length;
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
          // Background Glows
          Positioned(top: -100, right: -100, child: _Glow(color: Colors.pink.withValues(alpha: 0.1))),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildAdherenceDashboard(context),
                      const SizedBox(height: 25),
                      _buildInsightCard(context),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text((getTranslated('yourCurrentMeds', context) ?? 'yourCurrentMeds'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${_medications.length}${(getTranslated('medicationsCount', context) ?? 'medicationsCount')}', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
              _medications.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildMedCard(context, index),
                        childCount: _medications.length,
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(context),
          backgroundColor: Colors.pinkAccent,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text((getTranslated('addMedication', context) ?? 'addMedication'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ).animate().scale(duration: 400.ms),
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
      title: Text((getTranslated('medication_reminder', context) ?? 'medication_reminder'), style: const TextStyle(fontWeight: FontWeight.w900)),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(CupertinoIcons.chart_bar_alt_fill, color: Colors.pinkAccent)),
      ],
    );
  }

  Widget _buildAdherenceDashboard(BuildContext context) {
    final score = _overallAdherence;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade700]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.pink.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(
                  value: score,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text('${(score * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((getTranslated('adherenceRate', context) ?? 'adherenceRate'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text((getTranslated('adherenceAdvice', context) ?? 'adherenceAdvice'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildInsightCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.sparkles, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              (getTranslated('medicationInsight', context) ?? 'medicationInsight'),
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildMedCard(BuildContext context, int index) {
    final med = _medications[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canAction = med.lastActionDate.day != DateTime.now().day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.pink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                  child: const Icon(CupertinoIcons.capsule_fill, color: Colors.pink),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${med.dose} • ${TimeOfDay(hour: med.hour, minute: med.minute).format(context)}', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => _deleteMedication(index), icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
              ],
            ),
            if (canAction) ...[
              const Divider(height: 24, thickness: 0.5),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _markAction(index, false),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text((getTranslated('missed', context) ?? 'missed'), style: const TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _markAction(index, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text((getTranslated('taken', context) ?? 'taken'), style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ] else 
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Text((getTranslated('todayStatusUpdated', context) ?? 'todayStatusUpdated'), style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.alarm, size: 80, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text((getTranslated('startAddingMeds', context) ?? 'startAddingMeds'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 24, right: 24),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: SizedBox(width: 40, child: Divider(thickness: 4))),
              const SizedBox(height: 20),
              Text((getTranslated('addNewMedication', context) ?? 'addNewMedication'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              TextField(controller: _nameController, decoration: _inputStyle((getTranslated('medName', context) ?? 'medName'), CupertinoIcons.capsule)),
              const SizedBox(height: 16),
              TextField(controller: _doseController, decoration: _inputStyle((getTranslated('doseExample', context) ?? 'doseExample'), Icons.medication_outlined)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text((getTranslated('reminderTime', context) ?? 'reminderTime'), style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.pink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(_selectedTime.format(context), style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                ),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: _selectedTime);
                  if (time != null) setState(() => _selectedTime = time);
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _addMedication,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 4),
                  child: Text((getTranslated('saveSmartReminder', context) ?? 'saveSmartReminder'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  const _Glow({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: color)).asGlass(blurX: 80, blurY: 80);
  }
}
