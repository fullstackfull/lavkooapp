import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syriapharmacy/utill/custom_themes.dart';

/// The approved launch experience — Concept 3A.
///
/// Layer 2 of a two-layer opening. The platform draws the brand composition
/// before the runtime exists; this takes over at the same butterfly, the same
/// size, the same place, and brings it to life where it already stands — it
/// settles, the glow blooms, the wordmark and rule arrive, and then the dark
/// cover crossfades into the very gradient the home header wears while the
/// butterfly shrinks into its header slot. No blank frame and no hard cut.
///
/// The approved concept had the butterfly glide in from off-screen here. That
/// works only over a splash showing nothing, and Android 12 draws an icon on
/// its own splash whether an app wants one or not — so the entrance would have
/// shown the same mark twice, vanishing in between. The settle is that motion
/// kept and the second appearance dropped; the decision was the client's.
///
/// Two animated layers only, transform and opacity exclusively. No Lottie, no
/// video, no per-frame rendering, and nothing fetched from the network.
class LaunchTransitionWidget extends StatefulWidget {
  const LaunchTransitionWidget({
    super.key,
    this.appReady,
    this.onFinished,
    this.wordmark = 'LAVKOO',
  });

  /// Resolves when the app can be shown. The sequence holds its resting frame
  /// until then and never exits before the guaranteed minimum.
  final Future<void>? appReady;

  /// Called once the handover has finished and Home should own the screen.
  final VoidCallback? onFinished;

  final String wordmark;

  @override
  State<LaunchTransitionWidget> createState() => _LaunchTransitionWidgetState();
}

/// Timings, in milliseconds from the moment the runtime takes over (the spec's
/// 150 ms mark). Native splash spends 0–150; this widget spends the rest.
class _T {
  static const int reveal = 650; // 150 → 800
  static const int handover = 250; // 800 → 1050
  static const int minimumOnScreen = 600;
  static const int hairlineAfter = 3000;

  // Within the reveal phase.
  static const double bgEnd = 50 / reveal;
  static const double settleEnd = 300 / reveal;
  static const double glowStart = 60 / reveal;
  static const double glowEnd = 360 / reveal;
  static const double wordmarkStart = 320 / reveal;
  static const double wordmarkEnd = 470 / reveal;
  static const double sparkleStart = 440 / reveal;
  static const double sparkleEnd = 560 / reveal;
  static const double ruleStart = 500 / reveal;

  // Within the handover phase.
  static const double coverEnd = 150 / handover;
  static const double textFadeEnd = 120 / handover;
  static const double butterflyEnd = 200 / handover;
  static const double glowExitStart = 50 / handover;
}

class _LaunchTransitionWidgetState extends State<LaunchTransitionWidget>
    with TickerProviderStateMixin {
  static const Curve _brandCurve = Cubic(0.22, 0.61, 0.36, 1);

  static const Color _flat = Color(0xFF063523);
  static const List<Color> _cover = [
    Color(0xFF0B4A31),
    Color(0xFF08402B),
    Color(0xFF063523),
  ];
  static const List<Color> _header = [Color(0xFF063523), Color(0xFF1F7A55)];
  static const List<Color> _strip = [Color(0xFF1F7A55), Color(0xFF0B5A3A)];

  late final AnimationController _reveal;
  late final AnimationController _handover;
  late final AnimationController _breathe;

  final DateTime _startedAt = DateTime.now();
  bool _ready = false;
  bool _handoverStarted = false;
  bool _finished = false;
  bool _showHairline = false;

  /// True when the app answered before the sparkle and the rule were due: the
  /// spec drops both and goes straight to the handover.
  bool _fastStart = false;

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
        vsync: this, duration: const Duration(milliseconds: _T.reveal));
    _handover = AnimationController(
        vsync: this, duration: const Duration(milliseconds: _T.handover));
    // The resting state must not look frozen: the glow breathes, nothing else.
    _breathe = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));

    _handover.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_finished) {
        _finished = true;
        widget.onFinished?.call();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
    _listenForReady();
  }

  void _begin() {
    if (!mounted) return;
    if (_reducedMotion) {
      // Reduced motion: the composition is simply there, then it hands over.
      _reveal.value = 1;
      _maybeHandover();
      return;
    }
    _reveal.forward().whenComplete(() {
      if (!mounted) return;
      _breathe.repeat(reverse: true);
      _maybeHandover();
    });
    Future.delayed(const Duration(milliseconds: _T.hairlineAfter), () {
      if (mounted && !_handoverStarted) setState(() => _showHairline = true);
    });
  }

  Future<void> _listenForReady() async {
    if (widget.appReady != null) {
      await widget.appReady;
    }
    if (!mounted) return;
    _ready = true;
    _maybeHandover();
  }

  /// The handover begins as soon as the app is ready AND the guaranteed minimum
  /// has passed — from wherever the butterfly happens to be. It is never
  /// skipped: it is the thing that prevents the cut into Home.
  void _maybeHandover() {
    if (!_ready || _handoverStarted || !mounted) return;

    final int elapsed = DateTime.now().difference(_startedAt).inMilliseconds;
    final int remaining = _T.minimumOnScreen - elapsed;
    if (remaining > 0) {
      Future.delayed(Duration(milliseconds: remaining), _maybeHandover);
      return;
    }

    _handoverStarted = true;
    _fastStart = _reveal.value < _T.sparkleStart;
    _breathe.stop();
    if (_showHairline) setState(() => _showHairline = false);
    if (_reducedMotion) {
      // A 200 ms crossfade, no flight and no breathing.
      _handover.duration = const Duration(milliseconds: 200);
    }
    _handover.forward();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _handover.dispose();
    _breathe.dispose();
    super.dispose();
  }

  double _interval(double value, double begin, double end, {Curve? curve}) {
    if (end <= begin) return value >= end ? 1 : 0;
    final double t = ((value - begin) / (end - begin)).clamp(0.0, 1.0);
    return (curve ?? _brandCurve).transform(t);
  }

  /// Where the composition rests. Fractions of the viewport, identical in Arabic
  /// and English — the mark is never mirrored.
  Offset _restCentre(Size size) => Offset(size.width * 0.50, size.height * 0.46);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double topInset = MediaQuery.paddingOf(context).top;
    // 118 px at a 390 pt reference viewport, so the composition holds on any handset.
    final double butterflyRest = size.width * 0.303;
    const double butterflyHeader = 30;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return AnimatedBuilder(
      animation: Listenable.merge([_reveal, _handover, _breathe]),
      child: null,
      builder: (context, _) {
        final double r = _reveal.value;
        final double h = _handover.value;

        // ── the gradient block: flat → cover → header, shrinking to header height
        final double coverFade = _interval(r, 0, _T.bgEnd, curve: Curves.linear);
        final double headerFade = _interval(h, 0, _T.coverEnd);
        final double blockHeight = size.height -
            (size.height - (topInset + 132)) * _brandCurve.transform(h.clamp(0.0, 1.0));

        // ── the butterfly: the settle, then the move into the header slot
        final double settle = _interval(r, 0, _T.settleEnd);
        final Offset restCentre = _restCentre(size);
        final double headerX =
        isRtl ? size.width - 14 - butterflyHeader / 2 : 14 + butterflyHeader / 2;
        final Offset headerCentre =
        Offset(headerX, topInset + 12 + butterflyHeader / 2);
        final double toHeader = _interval(h, 0, _T.butterflyEnd);
        final Offset centre = Offset.lerp(restCentre, headerCentre, toHeader)!;

        // The mark does not arrive — it is already here, drawn by the platform
        // before this widget existed. It takes over at the size and opacity the
        // native splash left it at and comes alive in place, because re-entering
        // from off-screen would show the shopper the same logo twice.
        final double settleScale = _reducedMotion ? 1 : 0.94 + 0.06 * settle;
        final double butterflySize = butterflyRest * settleScale +
            (butterflyHeader - butterflyRest * settleScale) * toHeader;
        final double butterflyOpacity = _reducedMotion ? 1 : 0.92 + 0.08 * settle;

        // ── the glow: follows the butterfly, breathes at rest, exits upward
        final double glowIn = _reducedMotion
            ? 0.30
            : 0.30 * _interval(r, _T.glowStart, _T.glowEnd, curve: Curves.easeOut);
        final double breathing = (_breathe.isAnimating && !_handoverStarted)
            ? 0.34 - 0.12 * Curves.easeInOut.transform(_breathe.value)
            : glowIn;
        final double glowOpacity =
            (r >= 1 && !_reducedMotion ? breathing : glowIn) *
                (1 - _interval(h, _T.glowExitStart, 1, curve: Curves.easeOut));
        final double glowRise =
            -40 * _interval(h, _T.glowExitStart, 1, curve: Curves.easeOut);

        // ── wordmark, sparkle, rule
        final double textFade = 1 - _interval(h, 0, _T.textFadeEnd, curve: Curves.easeIn);
        final double wordmarkIn = _reducedMotion
            ? 1
            : _interval(r, _T.wordmarkStart, _T.wordmarkEnd, curve: Curves.easeOut);
        final bool skipTrimmings = _fastStart && !_reducedMotion;
        final double sparkleIn = skipTrimmings
            ? 0
            : (_reducedMotion
            ? 1
            : _interval(r, _T.sparkleStart, _T.sparkleEnd, curve: Curves.easeOut));
        final double ruleIn = skipTrimmings
            ? 0
            : (_reducedMotion ? 1 : _interval(r, _T.ruleStart, 1));

        return Stack(children: [
          // The gradient block. Home is mounted underneath; this shrinks over it.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: blockHeight,
            child: Stack(fit: StackFit.expand, children: [
              const ColoredBox(color: _flat),
              Opacity(
                opacity: coverFade,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-0.42, -0.91), // 155°
                      end: Alignment(0.42, 0.91),
                      colors: _cover,
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: headerFade,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-0.64, -0.77), // 140°
                      end: Alignment(0.64, 0.77),
                      colors: _header,
                    ),
                  ),
                ),
              ),
            ]),
          ),

          // The glow, trailing the butterfly.
          Positioned(
            left: centre.dx - butterflyRest * 0.64,
            top: centre.dy - butterflyRest * 0.64 + glowRise,
            width: butterflyRest * 1.28,
            height: butterflyRest * 1.28,
            child: IgnorePointer(
              child: Opacity(
                opacity: glowOpacity.clamp(0.0, 1.0),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x4D1F7A55), Color(0x001F7A55)],
                      stops: [0.0, 0.68],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Wordmark and rule, under the butterfly's resting centre.
          Positioned(
            left: 0,
            right: 0,
            top: restCentre.dy + butterflyRest * 0.42 + 16,
            child: Opacity(
              opacity: (wordmarkIn * textFade).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 6 * (1 - wordmarkIn)),
                child: Column(children: [
                  Text(
                    widget.wordmark,
                    textAlign: TextAlign.center,
                    style: tajawalHeavy.copyWith(
                        fontSize: size.width * 0.0615, // 24 px at 390
                        color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: ruleIn.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scaleX: ruleIn.clamp(0.0, 1.0),
                      child: Container(
                        width: 56,
                        height: 2,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: _strip),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // The butterfly, and its sparkle riding the upper wing.
          Positioned(
            left: centre.dx - butterflySize / 2,
            top: centre.dy - butterflySize / 2,
            width: butterflySize,
            height: butterflySize,
            child: Opacity(
              opacity: butterflyOpacity.clamp(0.0, 1.0),
              child: Stack(clipBehavior: Clip.none, children: [
                // Vector, not a bitmap: the mark is drawn from 118px down to
                // its 30px header slot, and every size in between has to be
                // exact at 3x density.
                SvgPicture.asset(
                  'assets/launch/butterfly_mono_white.svg',
                  fit: BoxFit.contain,
                  width: butterflySize,
                  height: butterflySize,
                ),
                if (sparkleIn > 0)
                  Positioned(
                    top: butterflySize * 0.06,
                    right: -butterflySize * 0.10,
                    child: Opacity(
                      opacity: (sparkleIn * textFade).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.7 + 0.3 * sparkleIn,
                        child: SvgPicture.asset(
                          'assets/launch/sparkle.svg',
                          width: butterflySize * 0.17,
                          height: butterflySize * 0.17,
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),

          // A long wait says so with a hairline, never a spinner.
          if (_showHairline && !_handoverStarted)
            Positioned(
              left: 64,
              right: 64,
              bottom: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0x1FFFFFFF),
                    valueColor: AlwaysStoppedAnimation(Color(0xFF1F7A55)),
                    minHeight: 2,
                  ),
                ),
              ),
            ),
        ]);
      },
    );
  }
}

