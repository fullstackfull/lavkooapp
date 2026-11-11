import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:hive_ce/hive.dart';

class HealthChallengesScreen extends StatefulWidget {
  const HealthChallengesScreen({super.key});

  @override
  State<HealthChallengesScreen> createState() => _HealthChallengesScreenState();
}

class _HealthChallengesScreenState extends State<HealthChallengesScreen> {
  late Box _challengeBox;
  bool _loading = true;
  int _userPoints = 1250;
  
  List<Map<String, dynamic>> _getDailyChallenges(bool isAr) => [
    {'id': 'water_master', 'title': isAr ? 'بطل المياه' : 'Hydration Master', 'desc': isAr ? 'اشرب ٣ لتر من المياه يومياً' : 'Drink 3L of water daily', 'points': 500, 'icon': Icons.local_drink, 'color': Colors.blue},
    {'id': 'step_hero', 'title': isAr ? 'بطل الخطوات' : 'Steps Hero', 'desc': isAr ? 'امش ١٠،٠٠٠ خطوة اليوم' : 'Walk 10,000 steps today', 'points': 800, 'icon': Icons.directions_walk, 'color': Colors.orange},
    {'id': 'zen_master', 'title': isAr ? 'بطل الاسترخاء' : 'Zen Master', 'desc': isAr ? 'تدرب على التنفس ٤-٧-٨ مرتين' : 'Practice 4-7-8 breathing twice', 'points': 300, 'icon': Icons.self_improvement, 'color': Colors.purple},
    {'id': 'early_bird', 'title': isAr ? 'الطائر المبكر' : 'Early Bird', 'desc': isAr ? 'استيقظ قبل ٧:٠٠ صباحاً' : 'Wake up before 7:00 AM', 'points': 400, 'icon': Icons.wb_sunny, 'color': Colors.amber},
  ];

  late List<Map<String, dynamic>> _dailyChallenges;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    _dailyChallenges = _getDailyChallenges(isAr);
  }

  Future<void> _initHive() async {
    _challengeBox = await Hive.openBox('health_challenges');
    _loadData();
  }

  void _loadData() {
    setState(() {
      _userPoints = _challengeBox.get('total_points', defaultValue: 1250);
      for (var c in _dailyChallenges) {
        c['progress'] = _challengeBox.get('progress_${c['id']}', defaultValue: 0.0);
        c['isCompleted'] = _challengeBox.get('completed_${c['id']}', defaultValue: false);
      }
      _loading = false;
    });
  }

  void _completeChallenge(int index) {
    final c = _dailyChallenges[index];
    if (c['isCompleted']) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    setState(() {
      c['isCompleted'] = true;
      c['progress'] = 1.0;
      _userPoints += c['points'] as int;
      _challengeBox.put('total_points', _userPoints);
      _challengeBox.put('completed_${c['id']}', true);
      _challengeBox.put('progress_${c['id']}', 1.0);
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1B24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Colors.amber, size: 80).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(isAr ? 'أحسنت!' : 'Well Done!', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(isAr ? 'لقد ربحت النقاط!' : 'You earned points!', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildPointsHeader(),
                        const SizedBox(height: 40),
                        _buildActiveChallenges( isDark),
                        const SizedBox(height: 40),
                        _buildLeaderboardHeader( isDark),
                        const SizedBox(height: 20),
                        _buildLeaderboardPreview( isDark),
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

  Widget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : Colors.black87)),
      title: Text((getTranslated('healthChallenges', context) ?? 'healthChallenges'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orangeAccent)),
    );
  }

  Widget _buildPointsHeader() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 35, backgroundColor: Colors.white24, child: Icon(Icons.bolt, color: Colors.white, size: 40)),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((getTranslated('pointsBalance', context) ?? 'pointsBalance'), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
              Text('$_userPoints HP', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildActiveChallenges( bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text((getTranslated('activeChallenges', context) ?? 'activeChallenges'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 20),
        ..._dailyChallenges.asMap().entries.map((e) => _buildChallengeCard(e.value, e.key, isDark)),
      ],
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> c, int index, bool isDark) {
    final color = c['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(c['title'] as String, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('3 ${(getTranslated('daysRemaining', context) ?? 'daysRemaining')}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text((getTranslated('challengeProgress', context) ?? 'challengeProgress'), style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12)),
              Text("${(c['progress'] * 100).toInt()}%", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: c['progress'] as double, backgroundColor: isDark ? Colors.white10 : Colors.black12, color: color, minHeight: 8),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _completeChallenge(index),
              style: ElevatedButton.styleFrom(backgroundColor: c['isCompleted'] ? Colors.green : color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(c['isCompleted'] ? (getTranslated('vaccineTaken', context) ?? 'vaccineTaken') : (getTranslated('joinChallenge', context) ?? 'joinChallenge'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildLeaderboardHeader( bool isDark) {
    return Row(children: [Text((getTranslated('leaderboardLabel', context) ?? 'leaderboardLabel'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18))]);
  }

  Widget _buildLeaderboardPreview( bool isDark) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final leaderboard = [
      {'name': isAr ? 'أحمد علي' : 'Ahmed Ali', 'points': 2500, 'rank': 1},
      {'name': isAr ? 'سارة محمود' : 'Sara Mahmoud', 'points': 1800, 'rank': 2},
      {'name': (getTranslated('youLabel', context) ?? 'youLabel'), 'points': _userPoints, 'rank': 3},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final f = leaderboard[index];
        return ListTile(
          leading: CircleAvatar(backgroundColor: isDark ? Colors.white10 : Colors.black12, child: Text('${f['rank']}', style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
          title: Text(f['name'] as String, style: TextStyle(fontWeight: f['name'] == (getTranslated('youLabel', context) ?? 'youLabel') ? FontWeight.bold : FontWeight.normal, color: isDark ? Colors.white : Colors.black87)),
          trailing: Text('${f['points']} ${(getTranslated('pointsLabel', context) ?? 'pointsLabel')}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
