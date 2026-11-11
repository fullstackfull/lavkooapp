import 'package:syriapharmacy/localization/language_constrants.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  final Map<String, TextEditingController> _controllers = {
    'personal': TextEditingController(),
    'chronic': TextEditingController(),
    'allergy': TextEditingController(),
    'surgeries': TextEditingController(),
    'meds': TextEditingController(),
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('health_records');
    if (data != null) {
      final Map<String, dynamic> decoded = jsonDecode(data);
      decoded.forEach((key, value) {
        if (_controllers.containsKey(key)) {
          _controllers[key]!.text = value;
        }
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, String>{};
    _controllers.forEach((key, controller) {
      data[key] = controller.text;
    });
    await prefs.setString('health_records', jsonEncode(data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((getTranslated('dataSaved', context) ?? 'dataSaved')), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, size: 20)),
        title: Text((getTranslated('medicalRecords', context) ?? 'medicalRecords'), style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          TextButton(onPressed: _saveData, child: Text((getTranslated('save', context) ?? 'save'), style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildRecordField((getTranslated('personalInfoLabel', context) ?? 'personalInfoLabel'), 'personal', Icons.person_outline, isDark),
                _buildRecordField((getTranslated('chronicDiseasesLabel', context) ?? 'chronicDiseasesLabel'), 'chronic', Icons.history_edu, isDark),
                _buildRecordField((getTranslated('allergiesLabel', context) ?? 'allergiesLabel'), 'allergy', Icons.warning_amber_rounded, isDark),
                _buildRecordField((getTranslated('previousSurgeriesLabel', context) ?? 'previousSurgeriesLabel'), 'surgeries', Icons.medical_services_outlined, isDark),
                _buildRecordField((getTranslated('currentMedsLabel', context) ?? 'currentMedsLabel'), 'meds', Icons.medication_liquid, isDark),
                const SizedBox(height: 100),
              ],
            ),
    );
  }

  Widget _buildRecordField(String title, String key, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controllers[key],
            maxLines: null,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: (getTranslated('enterDataHint', context) ?? 'enterDataHint'),
              hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
