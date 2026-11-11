import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/material.dart';


class KidsDosageScreen extends StatefulWidget {
  const KidsDosageScreen({super.key});

  @override
  State<KidsDosageScreen> createState() => _KidsDosageScreenState();
}

class _KidsDosageScreenState extends State<KidsDosageScreen> {
  final _weightController = TextEditingController();
  String _selectedDrug = 'Paracetamol';
  String _result = '';
  
  final Map<String, dynamic> _drugs = {
    'Paracetamol': {'dose': 15.0, 'interval': 6, 'desc': 'antipyretic'},
    'Ibuprofen': {'dose': 10.0, 'interval': 8, 'desc': 'anti_inflammatory'},
    'Amoxicillin': {'dose': 25.0, 'interval': 8, 'desc': 'antibiotic'},
  };

  void _calculate() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    if (weight > 0) {
      final drug = _drugs[_selectedDrug];
      final dose = (weight * drug['dose']) / 50; 
      setState(() {
        _result = "${getTranslated('dosageResult', context) ?? 'dosageResult'} ${dose.toStringAsFixed(1)} / ${drug['interval']} ${getTranslated('hours', context) ?? 'hours'}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : Colors.blue)),
        title: Text((getTranslated('kidsDosageCalculator', context) ?? 'kidsDosageCalculator'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((getTranslated('calculateDosageHint', context) ?? 'calculateDosageHint'), style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 30),
              Text((getTranslated('childWeightLabel', context) ?? 'childWeightLabel'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: '0.0',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.monitor_weight_outlined, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(height: 25),
              Text((getTranslated('medicationType', context) ?? 'medicationType'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDrug,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
                    items: _drugs.keys.map((String drug) => DropdownMenuItem(value: drug, child: Text(drug))).toList(),
                    onChanged: (v) => setState(() => _selectedDrug = v!),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text((getTranslated('calculateDosage', context) ?? 'calculateDosage'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              if (_result.isNotEmpty) ...[
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: isDark ? 0.15 : 0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.withValues(alpha: 0.2))),
                  child: Column(
                    children: [
                      Text((getTranslated('recommendedDosage', context) ?? 'recommendedDosage'), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(_result, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
