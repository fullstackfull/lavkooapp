import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/material.dart';


class VaccinationScreen extends StatefulWidget {
  const VaccinationScreen({super.key});

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 30),
                  _buildVaccineList(isDark),
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
      title: Text((getTranslated('vaccinationSchedule', context) ?? 'vaccinationSchedule'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.teal)),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.child_care, color: Colors.white)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((getTranslated('youLabel', context) ?? 'youLabel'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text('6 ${(getTranslated('monthsUnit', context) ?? 'monthsUnit')} - ${(getTranslated('nextVaccinationDate', context) ?? 'nextVaccinationDate')}: 12 June', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineList(bool isDark) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildVaccineGroup((getTranslated('birth', context) ?? 'birth'), [
          _VaccineItem((getTranslated('bcg', context) ?? 'bcg'), (getTranslated('vaccineTaken', context) ?? 'vaccineTaken')),
          _VaccineItem((getTranslated('hbv', context) ?? 'hbv'), (getTranslated('vaccineTaken', context) ?? 'vaccineTaken')),
        ], isDark),
        _buildVaccineGroup((getTranslated('twoMonths', context) ?? 'twoMonths'), [
          _VaccineItem((getTranslated('polio', context) ?? 'polio'), (getTranslated('vaccineTaken', context) ?? 'vaccineTaken')),
          _VaccineItem((getTranslated('dtap', context) ?? 'dtap'), (getTranslated('vaccineTaken', context) ?? 'vaccineTaken')),
          _VaccineItem((getTranslated('hib', context) ?? 'hib'), (getTranslated('vaccineTaken', context) ?? 'vaccineTaken')),
        ], isDark),
        _buildVaccineGroup((getTranslated('fourMonths', context) ?? 'fourMonths'), [
          _VaccineItem((getTranslated('polio', context) ?? 'polio'), (getTranslated('vaccinePending', context) ?? 'vaccinePending')),
          _VaccineItem((getTranslated('dtap', context) ?? 'dtap'), (getTranslated('vaccinePending', context) ?? 'vaccinePending')),
        ], isDark),
      ],
    );
  }

  Widget _buildVaccineGroup(String age, List<_VaccineItem> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(age, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        ),
        ...items.map((item) => _buildVaccineCard(item, isDark)),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildVaccineCard(_VaccineItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        border: isDark ? null : Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.vaccines, color: Colors.teal, size: 20),
          const SizedBox(width: 15),
          Text(item.name, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            item.status,
            style: TextStyle(color: item.status == (getTranslated('vaccineTaken', context) ?? 'vaccineTaken') ? Colors.teal : Colors.orangeAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _VaccineItem {
  final String name;
  final String status;
  _VaccineItem(this.name, this.status);
}
