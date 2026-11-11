import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class DosageConverterScreen extends StatefulWidget {
  const DosageConverterScreen({super.key});

  @override
  State<DosageConverterScreen> createState() => _DosageConverterScreenState();
}

class _DosageConverterScreenState extends State<DosageConverterScreen> {
  final _val1Controller = TextEditingController();
  final _val2Controller = TextEditingController();
  double _result = 0.0;
  String _safetyStatus = '';

  @override
  void initState() {
    super.initState();
    _val1Controller.addListener(_calculate);
    _val2Controller.addListener(_calculate);
  }

  void _calculate() {
    final v1 = double.tryParse(_val1Controller.text) ?? 0;
    final v2 = double.tryParse(_val2Controller.text) ?? 0;

    setState(() {
      _result = v1 * v2;
      if (_result > 500) {
        _safetyStatus = (getTranslated('dosageWarningHigh', context) ?? 'dosageWarningHigh');
      } else if (_result <= 0) {
        _safetyStatus = (getTranslated('enterCorrectValues', context) ?? 'enterCorrectValues');
      } else {
        _safetyStatus = (getTranslated('dosageSafeConfirmed', context) ?? 'dosageSafeConfirmed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFEBE9),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : Colors.brown)),
          title: Text((getTranslated('dosageSafetyTool', context) ?? 'dosageSafetyTool'), style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.brown)),
          bottom: TabBar(
            labelColor: isDark ? Colors.white : Colors.brown,
            unselectedLabelColor: isDark ? Colors.white70 : Colors.brown.withValues(alpha: 0.5),
            indicatorColor: isDark ? Colors.white : Colors.brown,
            tabs: [Tab(text: (getTranslated('concentrationDosageTab', context) ?? 'concentrationDosageTab')), Tab(text: (getTranslated('weightDosageTab', context) ?? 'weightDosageTab'))],
          ),
        ),
        body: TabBarView(
          children: [_buildConverterView(0, isDark), _buildConverterView(1, isDark)],
        ),
      ),
    );
  }

  Widget _buildConverterView(int type, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildInputCard(type == 0 ? (getTranslated('quantityToGive', context) ?? 'quantityToGive') : (getTranslated('patientWeightLabel', context) ?? 'patientWeightLabel'), _val1Controller, type == 0 ? CupertinoIcons.drop_fill : Icons.monitor_weight_outlined, isDark),
          const SizedBox(height: 15),
          _buildInputCard(type == 0 ? (getTranslated('medicationConcentration', context) ?? 'medicationConcentration') : (getTranslated('requiredDosageLabel', context) ?? 'requiredDosageLabel'), _val2Controller, type == 0 ? Icons.science_outlined : Icons.medical_services_outlined, isDark),
          const SizedBox(height: 30),
          _buildResultCard(type == 0 ? (getTranslated('totalDosageMg', context) ?? 'totalDosageMg') : (getTranslated('totalRequiredDosage', context) ?? 'totalRequiredDosage'), '${_result.toStringAsFixed(1)} mg'),
          const SizedBox(height: 30),
          _buildSafetyStatus(isDark),
          const SizedBox(height: 30),
          _buildSuggestions(type, isDark),
          const SizedBox(height: 40),
          _buildWarningBox(isDark),
        ],
      ),
    );
  }

  Widget _buildInputCard(String label, TextEditingController controller, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.brown.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.brown, size: 20),
              border: InputBorder.none,
              hintText: '0.0',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.brown, Color(0xFF8D6E63)]), borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSafetyStatus(bool isDark) {
    final isWarning = _safetyStatus.contains('Warning') || _safetyStatus.contains('تحذير');
    final bgColor = isWarning
        ? (isDark ? Colors.orange[900]!.withOpacity(0.3) : Colors.orange[100])
        : (isDark ? Colors.green[900]!.withOpacity(0.3) : Colors.green[100]);
    final textColor = isWarning
        ? (isDark ? Colors.orange[300]! : Colors.orange[900]!)
        : (isDark ? Colors.green[300]! : Colors.green[900]!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(_safetyStatus, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSuggestions(int type, bool isDark) {
    final suggestions = type == 0 ? ['120/5', '250/5', '100/1'] : ['15 mg/kg', '10 mg/kg', '45 mg/kg'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text((getTranslated('commonSuggestions', context) ?? 'commonSuggestions'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.brown)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: suggestions.map((e) => ActionChip(
            label: Text(e, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
            onPressed: () {},
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildWarningBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Colors.red[900]!.withOpacity(0.2) : Colors.red[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.red[900]! : Colors.red[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 15),
          Expanded(child: Text((getTranslated('safetyWarningDesc', context) ?? 'safetyWarningDesc'), style: TextStyle(color: isDark ? Colors.red[200] : Colors.red, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
