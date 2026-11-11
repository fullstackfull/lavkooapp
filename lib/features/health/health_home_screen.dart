import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scalify/flutter_scalify.dart';
import 'package:intl/intl.dart';
import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:provider/provider.dart';

import 'domain/models/entities/news_model.dart';
import 'domain/models/news_model.dart';
import 'data/health_database_helper.dart';

import 'analysis/drug_interaction_screen.dart';
import 'analysis/medical_analysis_screen.dart';
import 'calculators/bmi_calculator_screen.dart';
import 'calculators/calorie_counter_screen.dart';
import 'calculators/dosage_converter_screen.dart';
import 'calculators/kids_dosage_screen.dart';
import 'misc/first_aid_screen.dart';
import 'misc/health_blog_screen.dart';
import 'misc/health_challenges_screen.dart';
import 'misc/health_records_screen.dart';
import 'misc/mental_health_screen.dart';
import 'news/news_details.dart';
import 'news/news_feed_screen.dart';
import 'reminders/medication_reminder_screen.dart';
import 'reminders/vaccination_screen.dart';
import 'reminders/water_reminder_screen.dart';
import 'trackers/blood_pressure_screen.dart';
import 'trackers/blood_sugar_screen.dart';
import 'trackers/daily_steps_screen.dart';
import 'trackers/period_tracker_screen.dart';
import 'trackers/pregnancy_tracker_screen.dart';
import 'trackers/sleep_tracker_screen.dart';

// ─── Tool Model ────────────────────────────────────────────────────────────
class _ToolItem {
  final String imagePath;
  final String label;
  final Color color;
  final Widget screen;
  const _ToolItem(this.imagePath, this.label, this.color, this.screen);
}

// ─── Main Screen ────────────────────────────────────────────────────────────
class HealthHomeScreen extends StatefulWidget {
  const HealthHomeScreen({super.key});

  @override
  State<HealthHomeScreen> createState() => _HealthHomeScreenState();
}

class _HealthHomeScreenState extends State<HealthHomeScreen>
    with SingleTickerProviderStateMixin {
  // News
  final PageController _newsCtrl = PageController();
  int _newsPage = 0;
  Timer? _newsTimer;

  // Tabs
  late TabController _tabCtrl;

  // Health data
  double _score = 0.0;
  double _water = 0.0;
  double _sleep = 0.0;
  double _mood = 0.0;
  double _steps = 0.0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchNews();
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await HealthDatabaseHelper.instance.recalculateHealthScore(date);
    final s = await HealthDatabaseHelper.instance.getDailySummary(date);
    if (mounted) {
      setState(() {
        _score  = (s?['health_score'] as num?)?.toDouble() ?? 0.0;
        _water  = (s?['water_ml']     as num?)?.toDouble() ?? 0.0;
        _sleep  = (s?['sleep_hrs']    as num?)?.toDouble() ?? 0.0;
        _mood   = (s?['mood_score']   as num?)?.toDouble() ?? 0.0;
        _steps  = (s?['steps']        as num?)?.toDouble() ?? 0.0;
      });
    }
  }

  void _startNews(int count) {
    _newsTimer?.cancel();
    if (count <= 1) return;
    _newsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_newsPage + 1) % count;
      _newsCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      setState(() => _newsPage = next);
    });
  }

  @override
  void dispose() {
    _newsTimer?.cancel();
    _newsCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── Score helpers ────────────────────────────────────────────────────────
  Color get _scoreColor {
    if (_score >= 75) return const Color(0xFF00C896);
    if (_score >= 50) return const Color(0xFFFFAB2D);
    return const Color(0xFFFF5E5E);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr   = Localizations.localeOf(context).languageCode == 'ar';
    final pc     = Theme.of(context).primaryColor;
    final bg     = isDark ? const Color(0xFF0D1117) : const Color(0xFFF2F6FC);

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<NewsProvider>().fetchNews();
          await _loadData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Header
            SliverToBoxAdapter(
              child: _Header(
                score: _score,
                scoreColor: _scoreColor,
                isAr: isAr,
                primaryColor: pc,
                onRefresh: () {
                  context.read<NewsProvider>().fetchNews();
                  _loadData();
                },
              ),
            ),

            // 2. Stat chips
            SliverToBoxAdapter(
              child: _StatsRow(
                isAr: isAr, isDark: isDark,
                water: _water, sleep: _sleep,
                steps: _steps, mood: _mood,
              ),
            ),

            // 3. News
            Consumer<NewsProvider>(
              builder: (ctx, prov, _) {
                final items = prov.newsPosts.take(5).toList();
                if (_newsTimer == null && items.isNotEmpty) _startNews(items.length);
                if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: _NewsSection(
                    items: items,
                    ctrl: _newsCtrl,
                    currentPage: _newsPage,
                    isAr: isAr,
                    isDark: isDark,
                    primaryColor: pc,
                    onPageChanged: (i) => setState(() => _newsPage = i),
                    onSeeAll: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider<NewsProvider>.value(
                            value: prov, child: const NewsFeedScreen()),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // 4. Section title
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 22,
                      decoration: BoxDecoration(color: pc, borderRadius: BorderRadius.circular(4)),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      isAr ? 'الأدوات الصحية' : 'Health Tools',
                      style: TextStyle(
                        fontSize: 19.fz, fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Tab bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                child: _PremiumTabBar(ctrl: _tabCtrl, isAr: isAr, isDark: isDark, pc: pc),
              ),
            ),

            // 6. Tool grid (using SliverPadding + SliverGrid)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 32.h),
              sliver: _buildSliverGrid(isAr, isDark),
            ),
          ],
        ),
      ),
    );
  }

  SliverGrid _buildSliverGrid(bool isAr, bool isDark) {
    final List<_ToolItem> items;
    switch (_tabCtrl.index) {
      case 1:  items = _vitals(isAr); break;
      case 2:  items = _calcs(isAr);  break;
      case 3:  items = _guide(isAr);  break;
      default: items = _daily(isAr);
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => Navigator.of(ctx, rootNavigator: true)
                .push(MaterialPageRoute(builder: (_) => item.screen))
                .then((_) => _loadData()),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.1),
                    blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: item.color.withValues(alpha: 0.08)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52.w, height: 52.h,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      item.imagePath, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.health_and_safety_rounded, color: item.color, size: 26),
                    ),
                  ),
                  SizedBox(height: 9.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Text(item.label,
                      style: TextStyle(
                        fontSize: 11.fz, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF1A1F2E),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center, maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: items.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 0.85,
      ),
    );
  }

  List<_ToolItem> _daily(bool a) => [
    _ToolItem('assets/images/health/category/شرب الماء.webp',        a?'شرب الماء':'Water',     const Color(0xFF2196F3), const WaterReminderScreen()),
    _ToolItem('assets/images/health/category/متتبع النوم.webp',      a?'متتبع النوم':'Sleep',    const Color(0xFF7C3AED), const SleepTrackerScreen()),
    _ToolItem('assets/images/health/category/خطواتي.webp',           a?'خطواتي':'Steps',        const Color(0xFF10B981), const DailyStepsScreen()),
    _ToolItem('assets/images/health/category/حاسبة الدوره.webp',     a?'الدورة':'Period',       const Color(0xFFE91E8C), const PeriodTrackerScreen()),
    _ToolItem('assets/images/health/category/متابعة الحمل.webp',     a?'الحمل':'Pregnancy',    const Color(0xFFFF7043), const PregnancyTrackerScreen()),
  ];

  List<_ToolItem> _vitals(bool a) => [
    _ToolItem('assets/images/health/category/الضغط.webp',            a?'ضغط الدم':'Blood Pressure', const Color(0xFFEF4444), const BloodPressureScreen()),
    _ToolItem('assets/images/health/category/السكر.webp',            a?'السكر':'Blood Sugar',        const Color(0xFFFF6B35), const BloodSugarScreen()),
    _ToolItem('assets/images/health/category/السعرات الحرارية.webp', a?'السعرات':'Calories',         const Color(0xFFF59E0B), const CalorieCounterScreen()),
    _ToolItem('assets/images/health/category/16.webp',               a?'الوزن / BMI':'BMI',          const Color(0xFF06B6D4), const BMICalculatorScreen()),
  ];

  List<_ToolItem> _calcs(bool a) => [
    _ToolItem('assets/images/health/category/جرعات الادوية.webp',    a?'جرعات الأدوية':'Dosage',     const Color(0xFF3B82F6), const DosageConverterScreen()),
    _ToolItem('assets/images/health/category/جرعات الاطفال.webp',   a?'جرعات الأطفال':'Kids Dose',  const Color(0xFF8B5CF6), const KidsDosageScreen()),
    _ToolItem('assets/images/health/category/التفاعلات الكيميائية.webp', a?'التفاعلات':'Drug Interact', const Color(0xFFEC4899), const DrugInteractionScreen()),
    _ToolItem('assets/images/health/category/تذكير الادوية.webp',    a?'تذكير الدواء':'Pill Remind', const Color(0xFF14B8A6), const MedicationReminderScreen()),
  ];

  List<_ToolItem> _guide(bool a) => [
    _ToolItem('assets/images/health/category/الإسعافات الأولية.webp', a?'الإسعافات':'First Aid',     const Color(0xFFEF4444), const FirstAidScreen()),
    _ToolItem('assets/images/health/category/18.webp',               a?'سجلاتي الطبية':'Records',    const Color(0xFF3B82F6), const HealthRecordsScreen()),
    _ToolItem('assets/images/health/category/الصحه النفسية.webp',    a?'الصحة النفسية':'Mental',     const Color(0xFF7C3AED), const MentalHealthScreen()),
    _ToolItem('assets/images/health/category/التحاليل الطبية.webp',  a?'التحاليل':'Lab Analysis',   const Color(0xFF06B6D4), const MedicalAnalysisScreen()),
    _ToolItem('assets/images/health/category/التطعيمات.webp',        a?'التطعيمات':'Vaccines',       const Color(0xFF10B981), const VaccinationScreen()),
    _ToolItem('assets/images/health/category/17.webp',               a?'التحديات':'Challenges',      const Color(0xFFF59E0B), const HealthChallengesScreen()),
  ];
}

// ═════════════════════════════════════════════════════════════════════════════
// HEADER WIDGET
// ═════════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final double score;
  final Color scoreColor;
  final bool isAr;
  final Color primaryColor;
  final VoidCallback onRefresh;

  const _Header({
    required this.score,
    required this.scoreColor,
    required this.isAr,
    required this.primaryColor,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            const Color(0xFF1565C0),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Decorative blobs
          Positioned(top: -50, right: -50,
            child: Container(width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(bottom: -30, left: -20,
            child: Container(width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
              child: Column(
                children: [
                  // Top row: title + refresh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'المركز الصحي' : 'Health Hub',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.fz,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'RHZak',
                        ),
                      ),
                      GestureDetector(
                        onTap: onRefresh,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 28.h),

                  // Score ring + labels
                  Row(
                    children: [
                      // Ring
                      SizedBox(
                        width: 100.w,
                        height: 100.h,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100.w, height: 100.h,
                              child: CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 9,
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            SizedBox(
                              width: 100.w, height: 100.h,
                              child: CircularProgressIndicator(
                                value: score / 100,
                                strokeWidth: 9,
                                strokeCap: StrokeCap.round,
                                color: scoreColor,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${score.toInt()}%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22.fz,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isAr ? 'نقاطك' : 'Score',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10.fz,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 20.w),

                      // Info column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'مؤشر الصحة اليومي' : 'Daily Health Index',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12.fz,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              score >= 75
                                  ? (isAr ? 'ممتاز! استمر 🌟' : 'Excellent! Keep it up 🌟')
                                  : score >= 50
                                      ? (isAr ? 'جيد 👍 أكمل يومك' : 'Good! Keep going 👍')
                                      : (isAr ? 'ابدأ رحلتك 💪' : 'Start your journey 💪'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.fz,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Progress bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${score.toInt()}/100',
                                  style: TextStyle(color: Colors.white70, fontSize: 11.fz),
                                ),
                                Text(
                                  isAr ? 'التقدم' : 'Progress',
                                  style: TextStyle(color: Colors.white70, fontSize: 11.fz),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            LayoutBuilder(builder: (_, c) {
                              return Stack(
                                children: [
                                  Container(
                                    height: 7.h,
                                    width: c.maxWidth,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 900),
                                    curve: Curves.easeOutCubic,
                                    height: 7.h,
                                    width: c.maxWidth * (score / 100),
                                    decoration: BoxDecoration(
                                      color: scoreColor,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: scoreColor.withValues(alpha: 0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STATS ROW
// ═════════════════════════════════════════════════════════════════════════════
class _StatsRow extends StatelessWidget {
  final bool isAr, isDark;
  final double water, sleep, steps, mood;

  const _StatsRow({
    required this.isAr,
    required this.isDark,
    required this.water,
    required this.sleep,
    required this.steps,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    final waterStr = water > 0 ? '${(water / 1000).toStringAsFixed(1)}L' : '0L';
    final sleepStr = sleep > 0 ? '${sleep.toStringAsFixed(1)}h' : '--';
    final stepStr  = steps > 0 ? '${steps.toInt()}' : '--';
    final moodStr  = mood >= 7 ? '😊' : (mood >= 4 ? '😐' : (mood > 0 ? '😞' : '--'));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          _chip(waterStr, isAr ? 'الماء'   : 'Water', Icons.water_drop_rounded,    const Color(0xFF2196F3), isDark),
          SizedBox(width: 10.w),
          _chip(sleepStr, isAr ? 'النوم'   : 'Sleep', Icons.nightlight_rounded,    const Color(0xFF7C3AED), isDark),
          SizedBox(width: 10.w),
          _chip(stepStr,  isAr ? 'خطوات'  : 'Steps', Icons.directions_walk_rounded,const Color(0xFF10B981), isDark),
          SizedBox(width: 10.w),
          _chip(moodStr,  isAr ? 'نفسية'  : 'Mood',  Icons.mood_rounded,           const Color(0xFFF59E0B), isDark),
        ],
      ),
    );
  }

  Widget _chip(String val, String label, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16.iz),
            ),
            SizedBox(height: 6.h),
            Text(val, style: TextStyle(
              fontSize: 12.fz,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            )),
            SizedBox(height: 2.h),
            Text(label, style: TextStyle(
              fontSize: 9.fz,
              color: isDark ? Colors.white54 : Colors.black45,
            )),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// NEWS SECTION
// ═════════════════════════════════════════════════════════════════════════════
class _NewsSection extends StatelessWidget {
  final List<NewsModel> items;
  final PageController ctrl;
  final int currentPage;
  final bool isAr, isDark;
  final Color primaryColor;
  final void Function(int) onPageChanged;
  final VoidCallback onSeeAll;

  const _NewsSection({
    required this.items, required this.ctrl, required this.currentPage,
    required this.isAr, required this.isDark, required this.primaryColor,
    required this.onPageChanged, required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(width: 4, height: 20,
                  decoration: BoxDecoration(
                    color: primaryColor, borderRadius: BorderRadius.circular(4))),
                SizedBox(width: 10.w),
                Text(isAr ? 'أحدث الأخبار' : 'Latest News',
                  style: TextStyle(fontSize: 17.fz, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
              ]),
              TextButton(
                onPressed: onSeeAll,
                child: Text(isAr ? 'عرض الكل' : 'See All',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13.fz)),
              ),
            ],
          ),
        ),

        SizedBox(height: 10.h),

        // Slider
        SizedBox(
          height: 180.h,
          child: PageView.builder(
            controller: ctrl,
            itemCount: items.length,
            onPageChanged: onPageChanged,
            itemBuilder: (ctx, i) {
              final item = items[i];
              return GestureDetector(
                onTap: () => Navigator.of(ctx, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => NewsDetailsScreen(post: item))),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                        blurRadius: 14, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(fit: StackFit.expand, children: [
                      Hero(
                        tag: 'news_${item.id}',
                        child: CachedNetworkImage(
                          imageUrl: item.displayImageUrl, fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: isDark ? const Color(0xFF1A1F2E) : Colors.grey[200]),
                          errorWidget: (_, __, ___) => Container(
                            color: isDark ? const Color(0xFF1A1F2E) : Colors.grey[200],
                            child: const Icon(Icons.broken_image_rounded, color: Colors.grey)),
                        ),
                      ),
                      // Gradient overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 14, left: 14, right: 14,
                        child: AutoSizeText(item.displayTitle, maxLines: 2,
                          style: TextStyle(color: Colors.white, fontSize: 13.fz,
                            fontWeight: FontWeight.bold, height: 1.4)),
                      ),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 10.h),

        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: currentPage == i ? 20.0 : 6.0,
            height: 6,
            decoration: BoxDecoration(
              color: currentPage == i ? primaryColor : Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PREMIUM TAB BAR
// ═════════════════════════════════════════════════════════════════════════════
class _PremiumTabBar extends StatelessWidget {
  final TabController ctrl;
  final bool isAr, isDark;
  final Color pc;

  const _PremiumTabBar({required this.ctrl, required this.isAr, required this.isDark, required this.pc});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46.h,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: ctrl,
        indicator: BoxDecoration(
          color: pc,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(color: pc.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.fz),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.fz),
        tabs: [
          Tab(text: isAr ? 'يومي'   : 'Daily'),
          Tab(text: isAr ? 'قياسات' : 'Vitals'),
          Tab(text: isAr ? 'حاسبات' : 'Calcs'),
          Tab(text: isAr ? 'دليل'   : 'Guide'),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TOOL GRID
// ═════════════════════════════════════════════════════════════════════════════
class _ToolGrid extends StatelessWidget {
  final List<_ToolItem> items;
  final bool isDark;
  final VoidCallback onReturn;

  const _ToolGrid({required this.items, required this.isDark, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () => Navigator.of(ctx, rootNavigator: true)
              .push(MaterialPageRoute(builder: (_) => item.screen))
              .then((_) => onReturn()),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: 0.1),
                  blurRadius: 10, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: item.color.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52.w, height: 52.h,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset(
                    item.imagePath, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.health_and_safety_rounded, color: item.color, size: 26),
                  ),
                ),
                SizedBox(height: 9.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Text(item.label,
                    style: TextStyle(
                      fontSize: 11.fz,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF1A1F2E),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
