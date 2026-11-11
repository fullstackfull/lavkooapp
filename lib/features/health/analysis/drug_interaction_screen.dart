import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';


class DrugInteractionScreen extends StatefulWidget {
  const DrugInteractionScreen({super.key});

  @override
  State<DrugInteractionScreen> createState() => _DrugInteractionScreenState();
}

class _DrugInteractionScreenState extends State<DrugInteractionScreen> {
  String? _drug1;
  String? _drug2;
  Map<String, String>? _result;

  final List<String> _drugs = [
    'Warfarin', 'Aspirin', 'Metformin', 'Paracetamol', 'Ibuprofen', 
    'Amoxicillin', 'Alcohol', 'Atorvastatin', 'Lisinopril', 'Levothyroxine'
  ];

  final Map<String, Map<String, String>> _interactions = {
    'Warfarin+Aspirin': {'level': 'danger', 'desc': 'interactionDanger'},
    'Metformin+Alcohol': {'level': 'warning', 'desc': 'interactionWarningLactic'},
    'Paracetamol+Alcohol': {'level': 'warning', 'desc': 'interactionWarningLiver'},
    'Aspirin+Ibuprofen': {'level': 'warning', 'desc': 'interactionWarningAspirin'},
  };

  void _checkInteraction() {
    if (_drug1 == null || _drug2 == null) return;
    
    final key1 = '${_drug1!}+${_drug2!}';
    final key2 = '${_drug2!}+${_drug1!}';
    
    setState(() {
      _result = _interactions[key1] ?? _interactions[key2] ?? {'level': 'safe', 'desc': 'noKnownInteractions'};
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple.withValues(alpha: 0.1),
              ),
            ),
          ),
          SafeArea(
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
                          child: Icon(Icons.arrow_back_ios_new, size: 18, color: theme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          (getTranslated('drug_interaction', context) ?? 'drug_interaction'),
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 22),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((getTranslated('chooseDrugsForInteraction', context) ?? 'chooseDrugsForInteraction'), style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 30),

                        _buildDrugSelector((getTranslated('drug1Label', context) ?? 'drug1Label'), _drug1, (v) => setState(() => _drug1 = v)),
                        const SizedBox(height: 20),
                        _buildDrugSelector((getTranslated('drug2Label', context) ?? 'drug2Label'), _drug2, (v) => setState(() => _drug2 = v)),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () => _checkInteraction(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text((getTranslated('checkInteraction', context) ?? 'checkInteraction'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        if (_result != null) ...[
                          const SizedBox(height: 40),
                          _buildResultCard(),
                        ],

                        const SizedBox(height: 50),
                        _buildWarning(),
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

  Widget _buildDrugSelector(String label, String? value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text((getTranslated('selectFromList', context) ?? 'selectFromList')),
              items: _drugs.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final level = _result!['level'];
    final color = level == 'danger' ? Colors.red : (level == 'warning' ? Colors.orange : Colors.green);
    final icon = level == 'danger' ? Icons.error_outline : (level == 'warning' ? Icons.warning_amber_rounded : Icons.check_circle_outline);
    final statusText = level == 'danger' ? (getTranslated('danger', context) ?? 'danger') : (level == 'warning' ? (getTranslated('warningTitle', context) ?? 'warningTitle') : (getTranslated('safe', context) ?? 'safe'));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 15),
          Text(
            statusText,
            style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _getTranslatedDesc(_result!['desc']!),
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  String _getTranslatedDesc(String key) {
    switch (key) {
      case 'interactionDanger': return (getTranslated('interactionDanger', context) ?? 'interactionDanger');
      case 'interactionWarningLactic': return (getTranslated('interactionWarningLactic', context) ?? 'interactionWarningLactic');
      case 'interactionWarningLiver': return (getTranslated('interactionWarningLiver', context) ?? 'interactionWarningLiver');
      case 'interactionWarningAspirin': return (getTranslated('interactionWarningAspirin', context) ?? 'interactionWarningAspirin');
      case 'noKnownInteractions': return (getTranslated('noKnownInteractions', context) ?? 'noKnownInteractions');
      default: return key;
    }
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        (getTranslated('drugWarningDisclaimer', context) ?? 'drugWarningDisclaimer'),
        style: const TextStyle(color: Colors.red, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}
