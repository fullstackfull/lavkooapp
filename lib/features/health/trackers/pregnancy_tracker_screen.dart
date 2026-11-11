import 'package:syriapharmacy/localization/language_constrants.dart';
import 'dart:convert';

import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter/services.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class PregnancyWeek {
  final int week;
  final String title;
  final String babySize;
  final String babyDevelopment;
  final String motherChanges;
  final String tips;
  final List<String> foodRecommended;
  final List<String> foodAvoid;
  final String medical;
  final String warnings;
  final String notificationTitle;
  final String notificationBody;
  final String image;

  PregnancyWeek({
    required this.week,
    required this.title,
    required this.babySize,
    required this.babyDevelopment,
    required this.motherChanges,
    required this.tips,
    required this.foodRecommended,
    required this.foodAvoid,
    required this.medical,
    required this.warnings,
    required this.notificationTitle,
    required this.notificationBody,
    required this.image,
  });

  factory PregnancyWeek.fromJson(Map<String, dynamic> json) {
    return PregnancyWeek(
      week: json['week'] ?? 0,
      title: json['title']?.toString() ?? '',
      babySize: json['baby_size']?.toString() ?? '',
      babyDevelopment: json['baby_development']?.toString() ?? '',
      motherChanges: json['mother_changes']?.toString() ?? '',
      tips: json['tips']?.toString() ?? '',
      foodRecommended: List<String>.from(
          (json['food_recommended'] as List?)?.map((e) => e.toString()) ?? []),
      foodAvoid: List<String>.from(
          (json['food_avoid'] as List?)?.map((e) => e.toString()) ?? []),
      medical: json['medical']?.toString() ?? '',
      warnings: json['warnings']?.toString() ?? '',
      notificationTitle:
          (json['notification'] as Map?)?['title']?.toString() ?? '',
      notificationBody:
          (json['notification'] as Map?)?['body']?.toString() ?? '',
      image: json['image']?.toString() ??
          'assets/images/health/pregnancy/week_1_4.webp',
    );
  }
  String get backgroundImage {
    if (week <= 4) return 'assets/images/health/pregnancy/bg_week_1_4.webp';
    if (week <= 8) return 'assets/images/health/pregnancy/bg_week_5_8.webp';
    if (week <= 12) return 'assets/images/health/pregnancy/bg_week_9_12.webp';
    if (week <= 16) return 'assets/images/health/pregnancy/bg_week_13_16.webp';
    if (week <= 20) return 'assets/images/health/pregnancy/bg_week_17_20.webp';
    if (week <= 24) return 'assets/images/health/pregnancy/bg_week_21_24.webp';
    if (week <= 28) return 'assets/images/health/pregnancy/bg_week_25_28.webp';
    if (week <= 32) return 'assets/images/health/pregnancy/bg_week_29_32.webp';
    if (week <= 36) return 'assets/images/health/pregnancy/bg_week_33_40.webp';
    return 'assets/images/health/pregnancy/bg_week_37_40.webp';
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class PregnancyTrackerScreen extends StatefulWidget {
  const PregnancyTrackerScreen({super.key});

  @override
  State<PregnancyTrackerScreen> createState() =>
      _PregnancyTrackerScreenState();
}

class _PregnancyTrackerScreenState
    extends State<PregnancyTrackerScreen> {
  List<PregnancyWeek> _weeks = [];
  bool _loading = true;
  String? _errorMessage;

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded || _errorMessage != null) {
      _loadData().then((_) {
        if (_weeks.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showWeekSelector();
          });
        }
      });
      _isDataLoaded = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final asset = locale == 'ar'
          ? 'assets/json/pregnancy_data/pregnancy_tracker_ar.json'
          : 'assets/json/pregnancy_data/pregnancy_tracker_en.json';

      String raw;
      try {
        raw = await rootBundle.loadString(asset);
      } catch (e) {
        raw = await rootBundle
            .loadString('assets/json/pregnancy_data/pregnancy_tracker_en.json');
      }

      final decoded = json.decode(raw) as Map<String, dynamic>;
      final list = (decoded['pregnancy_weeks'] as List)
          .map((e) => PregnancyWeek.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _weeks = list;
          _loading = false;
          _errorMessage = list.isEmpty
              ? (getTranslated('noDataFound', context) ?? 'noDataFound')
              : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage =
              "${getTranslated('loadingDataFailed', context) ?? 'loadingDataFailed'} ${e.toString()}";
        });
      }
    }
  }

  void _showWeekSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1030) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          height: 350,
          child: Column(
            children: [
              Text(
                (getTranslated('whichWeekNow', context) ?? 'whichWeekNow'),
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _weeks.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        "${getTranslated('weekLabel', context) ?? 'weekLabel'} ${index + 1}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _currentIndex == index
                              ? Colors.pinkAccent
                              : (isDark ? Colors.white70 : Colors.black54),
                          fontWeight: _currentIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _carouselController.animateToPage(index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFFFF0F5),
        body: const Center(
            child: CircularProgressIndicator(color: Colors.pinkAccent)),
      );
    }

    if (_errorMessage != null || _weeks.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFFFF0F5),
        body: Center(
          child: Text(
              _errorMessage ??
                  (getTranslated('noDataFound', context) ?? 'noDataFound'),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFFFF0F5),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: _weeks.length,
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
                      children: [
                        Image.asset(
                          _weeks[index].backgroundImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Container(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            CarouselSlider(
              controller: _carouselController,
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height,
                viewportFraction: 0.68,
                enlargeCenterPage: true,
                enableInfiniteScroll: false,
                onScrolled: (double? offset) {
                  if (offset != null) {
                    _scrollController.jumpTo(
                      offset * MediaQuery.of(context).size.width,
                    );
                  }
                },
                onPageChanged: (index, _) {
                  setState(() => _currentIndex = index);
                },
              ),
              items:
                  _weeks.map((item) => _MovieCardWidget(week: item)).toList(),
            ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new,
                          color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: Icon(Icons.calendar_month,
                          color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => _showWeekSelector(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            backgroundColor: Colors.pinkAccent,
            minimumSize: const Size(double.infinity, 60),
            elevation: 8,
            shadowColor: Colors.black45,
          ),
          onPressed: () => _showWeekDetailSheet(_weeks[_currentIndex]),
          child: Text(
            (getTranslated('pregnancyDetails', context) ?? 'pregnancyDetails')
                .toUpperCase(),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.1),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showWeekDetailSheet(PregnancyWeek w) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WeekDetailSheet(week: w),
    );
  }
}

class _MovieCardWidget extends StatelessWidget {
  final PregnancyWeek week;
  const _MovieCardWidget({required this.week});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trimester = week.week <= 13
        ? (getTranslated('trimester1', context) ?? 'trimester1')
        : (week.week <= 26
            ? (getTranslated('trimester2', context) ?? 'trimester2')
            : (getTranslated('trimester3', context) ?? 'trimester3'));
    return Column(
      children: <Widget>[
        const SizedBox(height: 100),
        Container(
          height: 350,
          width: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
            child: Image.asset(week.image, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          "${getTranslated('weekLabel', context) ?? 'weekLabel'} ${week.week}",
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                "${getTranslated('trimesterStage', context) ?? 'trimesterStage'} $trimester",
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w400,
                    fontSize: 14),
              ),
              Icon(Icons.brightness_1,
                  color: isDark ? Colors.white70 : Colors.black54, size: 4),
              Text(
                week.babySize,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w400,
                    fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekDetailSheet extends StatelessWidget {
  final PregnancyWeek week;
  const _WeekDetailSheet({required this.week});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1030) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(week.title,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildInfoSection(
                  context,
                  (getTranslated('babyGrowth', context) ?? 'babyGrowth'),
                  week.babyDevelopment,
                  Icons.child_care,
                  isDark),
              _buildInfoSection(
                  context,
                  (getTranslated('motherChanges', context) ?? 'motherChanges'),
                  week.motherChanges,
                  Icons.pregnant_woman,
                  isDark),
              _buildInfoSection(
                  context,
                  (getTranslated('importantTips', context) ?? 'importantTips'),
                  week.tips,
                  Icons.lightbulb_outline,
                  isDark),
              _buildInfoSection(
                  context,
                  (getTranslated('recommendedFoods', context) ??
                      'recommendedFoods'),
                  week.foodRecommended.join(', '),
                  Icons.restaurant,
                  isDark),
              _buildInfoSection(
                  context,
                  (getTranslated('foodsToAvoid', context) ?? 'foodsToAvoid'),
                  week.foodAvoid.join(', '),
                  Icons.no_meals,
                  isDark),
              _buildInfoSection(
                  context,
                  (getTranslated('medicalAdvice', context) ?? 'medicalAdvice'),
                  week.medical,
                  Icons.medical_services,
                  isDark),
              _buildInfoSection(
                  context,
                  (getTranslated('warningsLabel', context) ?? 'warningsLabel'),
                  week.warnings,
                  Icons.warning_amber,
                  isDark),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, String content,
      IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.pinkAccent, size: 20),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    color: Colors.pinkAccent, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 8),
          Text(content,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 15,
                  height: 1.5)),
        ],
      ),
    );
  }
}

