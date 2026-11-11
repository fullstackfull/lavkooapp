import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';


class MedicalAnalysisScreen extends StatefulWidget {
  const MedicalAnalysisScreen({super.key});

  @override
  State<MedicalAnalysisScreen> createState() =>
      _MedicalAnalysisScreenState();
}

class _MedicalAnalysisScreenState
    extends State<MedicalAnalysisScreen> {
  List<Map<String, dynamic>> _getTestCategories() => [
    {
      'name': (getTranslated('cbcTest', context) ?? 'cbcTest'),
      'icon': Icons.bloodtype,
      'params': [
        {
          'name': (getTranslated('hemoglobin', context) ?? 'hemoglobin'),
          'min': 12.0,
          'max': 17.5,
          'unit': 'g/dL',
        },
        {
          'name': (getTranslated('whiteBloodCells', context) ?? 'whiteBloodCells'),
          'min': 4.0,
          'max': 11.0,
          'unit': 'x10³/μL',
        },
        {
          'name': (getTranslated('platelets', context) ?? 'platelets'),
          'min': 150.0,
          'max': 450.0,
          'unit': 'x10³/μL',
        },
      ],
    },
    {
      'name': (getTranslated('lipidProfile', context) ?? 'lipidProfile'),
      'icon': Icons.opacity,
      'params': [
        {
          'name': (getTranslated('totalCholesterol', context) ?? 'totalCholesterol'),
          'min': 0.0,
          'max': 200.0,
          'unit': 'mg/dL',
        },
        {'name': (getTranslated('triglycerides', context) ?? 'triglycerides'), 'min': 0.0, 'max': 150.0, 'unit': 'mg/dL'},
        {
          'name': (getTranslated('ldlCholesterol', context) ?? 'ldlCholesterol'),
          'min': 0.0,
          'max': 100.0,
          'unit': 'mg/dL',
        },
      ],
    },
    {
      'name': (getTranslated('kidneyFunctions', context) ?? 'kidneyFunctions'),
      'icon': Icons.health_and_safety,
      'params': [
        {'name': (getTranslated('creatinine', context) ?? 'creatinine'), 'min': 0.6, 'max': 1.3, 'unit': 'mg/dL'},
        {'name': (getTranslated('ureaBun', context) ?? 'ureaBun'), 'min': 7.0, 'max': 20.0, 'unit': 'mg/dL'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (getTranslated('medical_analysis', context) ?? 'medical_analysis'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _getTestCategories().length,
                itemBuilder: (context, index) {
                  final cat = _getTestCategories()[index];
                  return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ExpansionTile(
                          leading: Icon(cat['icon'], color: theme.primaryColor),
                          title: Text(
                            cat['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                children: (cat['params'] as List).map((p) {
                                  return _buildParamRow(p, isDark);
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (index * 100).ms)
                      .slideX(begin: 0.1);
                },
              ),
            ),

            _buildWarning(),
          ],
        ),
      ),
    );
  }

  Widget _buildParamRow(Map<String, dynamic> p, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                p['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                '${p['min']} - ${p['max']} ${p['unit']}',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: (getTranslated('enterResult', context) ?? 'enterResult'),
              isDense: true,
              filled: true,
              fillColor: isDark ? Colors.black26 : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null) {
                // Future: add visual feedback if value is out of range
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          (getTranslated('medicalAnalysisWarning', context) ?? 'medicalAnalysisWarning'),
          style: const TextStyle(color: Colors.red, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
