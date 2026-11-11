import 'package:syriapharmacy/localization/language_constrants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:audioplayers/audioplayers.dart';
import '../data/health_database_helper.dart';

class MentalHealthScreen extends StatefulWidget {
  const MentalHealthScreen({super.key});

  @override
  State<MentalHealthScreen> createState() => _MentalHealthScreenState();
}

class _MentalHealthScreenState extends State<MentalHealthScreen> {
  int _selectedMood = 1;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentPlayingTitle;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleAudio(String title) async {
    if (_currentPlayingTitle == title && _isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.play(AssetSource('music/calm-ocean-waves(chosic.com).mp3'));
      setState(() {
        _isPlaying = true;
        _currentPlayingTitle = title;
      });
    }
  }

  void _startBreathingExercise() async {
    // Stop currently playing audio if any
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
      _currentPlayingTitle = null;
    });

    await _audioPlayer.play(AssetSource('music/calm-ocean-waves(chosic.com).mp3'));
    
    if (!mounted) return;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return _BreathingExerciseOverlay(
          onClose: () {
            _audioPlayer.pause();
            Navigator.pop(context);
          },
        );
      },
    );
  }

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
                  _buildDailyAffirmation(),
                  const SizedBox(height: 30),
                  _buildMoodTracker(isDark),
                  const SizedBox(height: 40),
                  _buildStressLevel(isDark),
                  const SizedBox(height: 40),
                  _buildSessionsList(isDark),
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
      title: Text((getTranslated('mentalHealthCoach', context) ?? 'mentalHealthCoach'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.purpleAccent)),
    );
  }

  Widget _buildDailyAffirmation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple[700]!, Colors.purple[400]!]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text((getTranslated('dailyAffirmationTitle', context) ?? 'dailyAffirmationTitle'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            (getTranslated('dailyAffirmationDesc', context) ?? 'dailyAffirmationDesc'),
            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildMoodTracker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text((getTranslated('howAreYouFeeling', context) ?? 'howAreYouFeeling'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMoodIcon('😌', (getTranslated('moodRelaxed', context) ?? 'moodRelaxed'), _selectedMood == 0, isDark, () => _saveMood(0, 9)),
            _buildMoodIcon('😊', (getTranslated('moodGood', context) ?? 'moodGood'), _selectedMood == 1, isDark, () => _saveMood(1, 7)),
            _buildMoodIcon('😓', (getTranslated('moodStressed', context) ?? 'moodStressed'), _selectedMood == 2, isDark, () => _saveMood(2, 4)),
            _buildMoodIcon('😟', (getTranslated('moodAnxious', context) ?? 'moodAnxious'), _selectedMood == 3, isDark, () => _saveMood(3, 2)),
          ],
        ),
      ],
    );
  }

  void _saveMood(int index, int score) async {
    setState(() => _selectedMood = index);
    
    // Save to SQL Database
    final date = DateTime.now().toString().split(' ')[0]; // yyyy-MM-dd
    await HealthDatabaseHelper.instance.updateDailyMetric(date, 'mood_score', score);
  }

  Widget _buildMoodIcon(String emoji, String label, bool isSelected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isSelected ? Colors.purpleAccent : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)), borderRadius: BorderRadius.circular(16)),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStressLevel(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text((getTranslated('stressLevel', context) ?? 'stressLevel'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            const Text('35%', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 15),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: 0.35, backgroundColor: isDark ? Colors.white10 : Colors.black12, color: Colors.purpleAccent, minHeight: 8),
        ),
      ],
    );
  }

  Widget _buildSessionsList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text((getTranslated('meditationSessions', context) ?? 'meditationSessions'), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        _buildSessionCard((getTranslated('breathingExercise', context) ?? 'breathingExercise'), '10 ${(getTranslated('minutesUnit', context) ?? 'minutesUnit')}', Icons.air, isDark),
        _buildSessionCard((getTranslated('deepSleepMelody', context) ?? 'deepSleepMelody'), '20 ${(getTranslated('minutesUnit', context) ?? 'minutesUnit')}', Icons.nights_stay, isDark),
      ],
    );
  }

  Widget _buildSessionCard(String title, String duration, IconData icon, bool isDark) {
    final isBreathing = title == (getTranslated('breathingExercise', context) ?? 'breathingExercise');
    final isThisPlaying = _isPlaying && _currentPlayingTitle == title;
    
    return GestureDetector(
      onTap: () {
        if (isBreathing) {
          _startBreathingExercise();
        } else {
          _toggleAudio(title);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          border: isDark ? null : Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.purpleAccent, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                  Text(duration, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            Icon(isThisPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.purpleAccent, size: 35),
          ],
        ),
      ),
    );
  }
}

class _BreathingExerciseOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const _BreathingExerciseOverlay({required this.onClose});

  @override
  State<_BreathingExerciseOverlay> createState() => _BreathingExerciseOverlayState();
}

class _BreathingExerciseOverlayState extends State<_BreathingExerciseOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  String _instruction = ''; 
  bool _isInhale = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isInhale = false);
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _isInhale = true);
        _controller.forward();
      }
    });
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    _instruction = _isInhale ? (isAr ? 'شهيق' : 'Inhale') : (isAr ? 'زفير' : 'Exhale');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5), width: 2),
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Text(
              _instruction,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ).animate(target: _isInhale ? 1 : 0).fade(duration: 500.ms),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }
}
