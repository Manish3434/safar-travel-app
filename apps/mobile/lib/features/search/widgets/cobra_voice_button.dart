import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The active lifecycle states of the Cobra Voice Search Button.
enum CobraVoiceState {
  /// Round teal button with white microphone icon.
  idle,

  /// Initial press / touch down (scale down with spring ripple).
  touching,

  /// In-place morphing between circle and cobra hood.
  morphing,

  /// Active listening with open mouth, moving equalizer bars, and pulsing ripples.
  listening,

  /// Processing / thinking with closed mouth and slow tongue flick.
  thinking,

  /// Voice response speaking with mouth animation.
  speaking,
}

/// Color theme configuration for the Cobra Voice Button.
class CobraVoiceTheme {
  final Color idleColor;
  final Color idleBorderColor;
  final Color hoodColor;
  final Color hoodDarkColor;
  final Color hoodLiningColor;
  final Color eyeColor;
  final Color mouthCavityColor;
  final Color fangsColor;
  final Color voiceBarColor;
  final Color rippleColor;

  const CobraVoiceTheme({
    this.idleColor = const Color(0xFF19C3B0),
    this.idleBorderColor = const Color(0xFF0E8F86),
    this.hoodColor = const Color(0xFFD4564C),
    this.hoodDarkColor = const Color(0xFF9E2A2B),
    this.hoodLiningColor = const Color(0xFFEED6B8),
    this.eyeColor = const Color(0xFFFBBF24),
    this.mouthCavityColor = const Color(0xFF420C14),
    this.fangsColor = Colors.white,
    this.voiceBarColor = Colors.white,
    this.rippleColor = const Color(0xFF19C3B0),
  });

  /// Coral-red scales variant from Spec v2 owner reference.
  static const coral = CobraVoiceTheme(
    idleColor: Color(0xFF19C3B0),
    idleBorderColor: Color(0xFF0E8F86),
    hoodColor: Color(0xFFD4564C),
    hoodDarkColor: Color(0xFF9E2A2B),
    hoodLiningColor: Color(0xFFEED6B8),
    eyeColor: Color(0xFFFBBF24),
    mouthCavityColor: Color(0xFF420C14),
    fangsColor: Colors.white,
    voiceBarColor: Colors.white,
    rippleColor: Color(0xFFD4564C),
  );

  /// Teal / Emerald scales variant matching the reference illustration.
  static const teal = CobraVoiceTheme(
    idleColor: Color(0xFF19C3B0),
    idleBorderColor: Color(0xFF0E8F86),
    hoodColor: Color(0xFF14B8A6),
    hoodDarkColor: Color(0xFF0F766E),
    hoodLiningColor: Color(0xFFF0E6D2),
    eyeColor: Color(0xFFF59E0B),
    mouthCavityColor: Color(0xFF051817),
    fangsColor: Colors.white,
    voiceBarColor: Colors.white,
    rippleColor: Color(0xFF14B8A6),
  );
}

/// A native Flutter Voice Search Button that morphs in-place into a 3D-styled
/// cartoon Cobra Head during active listening, complete with glowing equalizer
/// bars inside its open mouth.
///
/// Designed strictly according to Voice Search Button Spec v2.
class CobraVoiceButton extends StatefulWidget {
  /// The size (diameter) of the button widget.
  final double size;

  /// Current state of the voice engine.
  final CobraVoiceState state;

  /// External audio loudness in range [0.0, 1.0]. If null, simulated wave is used.
  final double? audioLoudness;

  /// Called when the user taps the button to toggle listening.
  final VoidCallback? onTap;

  /// Visual theme configuration.
  final CobraVoiceTheme theme;

  /// Optional caption displayed below the button when listening (e.g. "Listening...").
  final String? caption;

  /// Setting to toggle the snake morph off (renders a clean pulsing mic with bars).
  final bool enableSnakeMorph;

  const CobraVoiceButton({
    super.key,
    this.size = 64.0,
    this.state = CobraVoiceState.idle,
    this.audioLoudness,
    this.onTap,
    this.theme = const CobraVoiceTheme(),
    this.caption,
    this.enableSnakeMorph = true,
  });

  @override
  State<CobraVoiceButton> createState() => _CobraVoiceButtonState();
}

class _CobraVoiceButtonState extends State<CobraVoiceButton> with TickerProviderStateMixin {
  late final AnimationController _morphController;
  late final AnimationController _touchController;
  late final AnimationController _rippleController;
  late final AnimationController _barsController;
  late final AnimationController _blinkController;
  late final AnimationController _tongueController;

  late final Animation<double> _morphAnimation;
  late final Animation<double> _mouthAnimation;
  late final Animation<double> _eyesAnimation;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();

    // 1. Morph Controller: Controls the transition between circle and cobra hood.
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: const Interval(0.0, 0.70, curve: Curves.easeOutBack),
    );

    _eyesAnimation = CurvedAnimation(
      parent: _morphController,
      curve: const Interval(0.40, 0.85, curve: Curves.elasticOut),
    );

    _mouthAnimation = CurvedAnimation(
      parent: _morphController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutBack),
    );

    // 2. Touch Controller: Quick squish & spring on tap
    _touchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    // 3. Ripple Halo Controller: Repeating pulse rings in listening mode
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // 4. Voice Bars Controller: Idle breathing wave if loudness is unavailable
    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // 5. Periodic Eye Blink Controller
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    // 6. Tongue flick controller
    _tongueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _syncWithState(widget.state, isInitial: true);
  }

  @override
  void didUpdateWidget(CobraVoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncWithState(widget.state);
    }
  }

  void _syncWithState(CobraVoiceState state, {bool isInitial = false}) {
    switch (state) {
      case CobraVoiceState.idle:
        if (isInitial) {
          _morphController.value = 0.0;
        } else {
          _morphController.reverse();
        }
        _blinkTimer?.cancel();
        _rippleController.stop();
        _barsController.stop();
        _blinkController.stop();
        _tongueController.stop();
        break;

      case CobraVoiceState.touching:
        _touchController.forward().then((_) => _touchController.reverse());
        break;

      case CobraVoiceState.morphing:
        _morphController.forward();
        _rippleController.repeat();
        _barsController.repeat(reverse: true);
        break;

      case CobraVoiceState.listening:
        _morphController.forward();
        _rippleController.repeat();
        _barsController.repeat(reverse: true);
        _scheduleRandomBlink();
        break;

      case CobraVoiceState.thinking:
        _blinkTimer?.cancel();
        _morphController.forward();
        _tongueController.repeat(reverse: true);
        _barsController.stop();
        break;

      case CobraVoiceState.speaking:
        _blinkTimer?.cancel();
        _morphController.forward();
        _barsController.repeat(reverse: true);
        break;
    }
  }

  void _scheduleRandomBlink() {
    _blinkTimer?.cancel();
    if (!mounted || widget.state != CobraVoiceState.listening) return;
    _blinkTimer = Timer(Duration(milliseconds: 2200 + math.Random().nextInt(1400)), () {
      if (mounted && widget.state == CobraVoiceState.listening) {
        _blinkController.forward().then((_) {
          if (mounted && widget.state == CobraVoiceState.listening) {
            _blinkController.reverse().then((_) {
              if (mounted) _scheduleRandomBlink();
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _morphController.dispose();
    _touchController.dispose();
    _rippleController.dispose();
    _barsController.dispose();
    _blinkController.dispose();
    _tongueController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _touchController.forward().then((_) => _touchController.reverse());
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion = mediaQuery?.disableAnimations ?? false;
    final isListening = widget.state == CobraVoiceState.listening || widget.state == CobraVoiceState.morphing;

    // Accessibility label as required by Spec v2
    final semanticsLabel = isListening
        ? 'Listening. Double tap to stop voice search'
        : 'Voice search, double tap to start listening';

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _morphController,
                  _touchController,
                  _rippleController,
                  _barsController,
                  _blinkController,
                  _tongueController,
                ]),
                builder: (context, _) {
                  final touchSquish = 1.0 - (_touchController.value * 0.10);

                  return Transform.scale(
                    scale: touchSquish,
                    child: SizedBox(
                      width: widget.size * 1.55,
                      height: widget.size * 1.55,
                      child: CustomPaint(
                        painter: _CobraVoicePainter(
                          morphProgress: reduceMotion || !widget.enableSnakeMorph ? 0.0 : _morphAnimation.value,
                          mouthProgress: reduceMotion || !widget.enableSnakeMorph ? 0.0 : _mouthAnimation.value,
                          eyesProgress: reduceMotion || !widget.enableSnakeMorph ? 0.0 : _eyesAnimation.value,
                          rippleProgress: _rippleController.value,
                          barsProgress: _barsController.value,
                          blinkProgress: _blinkController.value,
                          tongueProgress: _tongueController.value,
                          audioLoudness: widget.audioLoudness,
                          state: widget.state,
                          theme: widget.theme,
                          reduceMotion: reduceMotion || !widget.enableSnakeMorph,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.caption != null && isListening) ...[
              const SizedBox(height: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isListening ? 1.0 : 0.0,
                child: ExcludeSemantics(
                  child: Text(
                    widget.caption!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The core painter that computes 200 interpolated polar points and renders
/// the 3D cobra face layers with 60 FPS performance.
class _CobraVoicePainter extends CustomPainter {
  final double morphProgress;
  final double mouthProgress;
  final double eyesProgress;
  final double rippleProgress;
  final double barsProgress;
  final double blinkProgress;
  final double tongueProgress;
  final double? audioLoudness;
  final CobraVoiceState state;
  final CobraVoiceTheme theme;
  final bool reduceMotion;

  _CobraVoicePainter({
    required this.morphProgress,
    required this.mouthProgress,
    required this.eyesProgress,
    required this.rippleProgress,
    required this.barsProgress,
    required this.blinkProgress,
    required this.tongueProgress,
    required this.audioLoudness,
    required this.state,
    required this.theme,
    required this.reduceMotion,
  });

  // Cached math constants to eliminate allocations per frame
  static const int _kPointCount = 200;
  static final List<double> _kAngles = List.generate(
    _kPointCount,
    (i) => (i * 2 * math.pi) / _kPointCount,
    growable: false,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final idleRadius = size.width * 0.32;
    final fullHoodRadius = idleRadius * 1.48;

    // ──────────────────────────────────────────────────────────────────────────
    // 1. LAYER 1: RIPPLE HALO (Active listening rings behind the button)
    // ──────────────────────────────────────────────────────────────────────────
    if (state == CobraVoiceState.listening || morphProgress > 0.05) {
      _paintRippleRings(canvas, center, idleRadius);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 2. LAYER 2: MORPHING HOOD SHELL (200-point polar interpolation)
    // ──────────────────────────────────────────────────────────────────────────
    final hoodPath = _computeMorphPath(center, idleRadius, fullHoodRadius, morphProgress);

    // Current interpolated theme color (Teal -> Hood Coral/Teal)
    final currentHoodColor = Color.lerp(theme.idleColor, theme.hoodColor, morphProgress) ?? theme.idleColor;
    final currentDarkColor = Color.lerp(theme.idleBorderColor, theme.hoodDarkColor, morphProgress) ?? theme.idleBorderColor;

    // 3D Soft Lighting Gradient (from top-left)
    final hoodGradient = RadialGradient(
      center: const Alignment(-0.35, -0.45),
      radius: 0.95,
      colors: [
        Color.lerp(currentHoodColor, Colors.white, 0.28)!,
        currentHoodColor,
        currentDarkColor,
      ],
      stops: const [0.0, 0.58, 1.0],
    );

    final hoodPaint = Paint()
      ..shader = hoodGradient.createShader(Rect.fromCircle(center: center, radius: fullHoodRadius))
      ..style = PaintingStyle.fill;

    // Soft drop shadow
    canvas.drawShadow(hoodPath, Colors.black.withOpacity(0.40), 10.0, true);
    canvas.drawPath(hoodPath, hoodPaint);

    // Scale texture diamond grid when morphed
    if (morphProgress > 0.30) {
      _paintScaleTexture(canvas, hoodPath, center, fullHoodRadius, morphProgress);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 3. LAYER 3: IDLE MICROPHONE ICON (fades out as morph progresses)
    // ──────────────────────────────────────────────────────────────────────────
    final micOpacity = (1.0 - (morphProgress * 2.2)).clamp(0.0, 1.0);
    if (micOpacity > 0.01) {
      _paintMicrophoneIcon(canvas, center, idleRadius * 0.46, micOpacity);
    }

    // If reduce motion or morph has not begun, stop here
    if (morphProgress < 0.05) return;

    // ──────────────────────────────────────────────────────────────────────────
    // 4. LAYER 4: INNER HOOD & CHEEKS CREAM LINING
    // ──────────────────────────────────────────────────────────────────────────
    _paintCreamHoodLining(canvas, center, fullHoodRadius, morphProgress);

    // ──────────────────────────────────────────────────────────────────────────
    // 5. LAYER 5: HEAD TOP & NOSTRILS
    // ──────────────────────────────────────────────────────────────────────────
    _paintHeadDomeAndNostrils(canvas, center, fullHoodRadius, morphProgress, currentHoodColor, currentDarkColor);

    // ──────────────────────────────────────────────────────────────────────────
    // 6. LAYER 6: TONGUE FLICK (Active flick at start or thinking state)
    // ──────────────────────────────────────────────────────────────────────────
    if (tongueProgress > 0.05 || state == CobraVoiceState.thinking) {
      _paintTongueFlick(canvas, center, fullHoodRadius, tongueProgress);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 7. LAYER 7: OPEN MOUTH & SHARP FANGS
    // ──────────────────────────────────────────────────────────────────────────
    if (mouthProgress > 0.05) {
      _paintOpenMouthAndFangs(canvas, center, fullHoodRadius, mouthProgress);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 8. LAYER 8: THREE VOICE EQUALIZER BARS (INSIDE THE MOUTH)
    // ──────────────────────────────────────────────────────────────────────────
    if (mouthProgress > 0.30) {
      _paintVoiceEqualizerBars(canvas, center, fullHoodRadius, mouthProgress);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 9. LAYER 9: BIG EXPRESSIVE COBRA EYES
    // ──────────────────────────────────────────────────────────────────────────
    if (eyesProgress > 0.05) {
      _paintCobraEyes(canvas, center, fullHoodRadius, eyesProgress, blinkProgress);
    }
  }

  /// Evaluates the 200 polar points blending between circle and cobra hood.
  Path _computeMorphPath(Offset center, double rCircle, double rHoodMax, double t) {
    final path = Path();

    for (int i = 0; i < _kPointCount; i++) {
      final theta = _kAngles[i];

      // Cobra hood parametric profile:
      // - Crest at top (theta = -pi/2)
      // - Wide flared cheeks (theta ~ -0.10*pi and 1.10*pi)
      // - Tapered chin at bottom (theta = pi/2)
      final cosTheta = math.cos(theta);
      final sinTheta = math.sin(theta);

      // Flared cheeks expansion factor
      final cheekFactor = math.pow(cosTheta.abs(), 1.6) * (1.0 + 0.35 * sinTheta);
      // Taper down to rounded chin
      final chinFactor = (sinTheta > 0) ? (1.0 - 0.28 * sinTheta) : 1.0;
      // Top crest rounding
      final crestFactor = (sinTheta < 0) ? (0.85 + 0.15 * math.cos(theta * 2)) : 1.0;

      final rTarget = rHoodMax * (0.68 + (0.44 * cheekFactor)) * chinFactor * crestFactor;
      final currentR = (1.0 - t) * rCircle + (t * rTarget);

      final x = center.dx + currentR * cosTheta;
      final y = center.dy + currentR * sinTheta;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  /// Concentric pulse ripple rings in background
  void _paintRippleRings(Canvas canvas, Offset center, double baseRadius) {
    for (int i = 0; i < 3; i++) {
      final phase = (rippleProgress + (i * 0.33)) % 1.0;
      final ringRadius = baseRadius * (1.1 + (phase * 1.1));
      final ringOpacity = ((1.0 - phase) * 0.45).clamp(0.0, 1.0);

      final ringPaint = Paint()
        ..color = theme.rippleColor.withOpacity(ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, ringRadius, ringPaint);
    }
  }

  /// Fine scale texture pattern on the hood
  void _paintScaleTexture(Canvas canvas, Path clipPath, Offset center, double radius, double t) {
    canvas.save();
    canvas.clipPath(clipPath);

    final scalePaint = Paint()
      ..color = Colors.white.withOpacity((0.06 * t).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const step = 8.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (double x = rect.left; x <= rect.right; x += step) {
      for (double y = rect.top; y <= rect.bottom; y += step) {
        final dist = (Offset(x, y) - center).distance;
        if (dist < radius * 0.85) {
          canvas.drawCircle(Offset(x, y), 2.0, scalePaint);
        }
      }
    }
    canvas.restore();
  }

  /// Crisp vector microphone icon in idle circle
  void _paintMicrophoneIcon(Canvas canvas, Offset center, double size, double opacity) {
    final clampedOpacity = opacity.clamp(0.0, 1.0);
    final micPaint = Paint()
      ..color = Colors.white.withOpacity(clampedOpacity)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(clampedOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.16
      ..strokeCap = StrokeCap.round;

    // Mic Capsule
    final capsuleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(0, -size * 0.15), width: size * 0.44, height: size * 0.82),
      Radius.circular(size * 0.22),
    );
    canvas.drawRRect(capsuleRect, micPaint);

    // Mic Cradle Arc
    final arcRect = Rect.fromCenter(
      center: center.translate(0, -size * 0.08),
      width: size * 0.82,
      height: size * 0.88,
    );
    canvas.drawArc(arcRect, 0.15, math.pi - 0.30, false, strokePaint);

    // Stem and Base
    final stemY = center.dy + size * 0.38;
    canvas.drawLine(Offset(center.dx, stemY), Offset(center.dx, stemY + size * 0.26), strokePaint);
    canvas.drawLine(
      Offset(center.dx - size * 0.30, stemY + size * 0.26),
      Offset(center.dx + size * 0.30, stemY + size * 0.26),
      strokePaint,
    );
  }

  /// Cream cheeks and inner hood ribs
  void _paintCreamHoodLining(Canvas canvas, Offset center, double radius, double t) {
    final liningPaint = Paint()
      ..color = theme.hoodLiningColor.withOpacity(t.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final cheekHeight = radius * 0.65;

    // Left Cream Cheek
    final leftCheek = Path()
      ..moveTo(center.dx - radius * 0.72, center.dy)
      ..quadraticBezierTo(
        center.dx - radius * 0.82,
        center.dy - cheekHeight * 0.4,
        center.dx - radius * 0.36,
        center.dy - cheekHeight * 0.7,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.42,
        center.dy,
        center.dx - radius * 0.22,
        center.dy + cheekHeight * 0.6,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.60,
        center.dy + cheekHeight * 0.5,
        center.dx - radius * 0.72,
        center.dy,
      )
      ..close();

    // Right Cream Cheek (Mirrored)
    final rightCheek = Path()
      ..moveTo(center.dx + radius * 0.72, center.dy)
      ..quadraticBezierTo(
        center.dx + radius * 0.82,
        center.dy - cheekHeight * 0.4,
        center.dx + radius * 0.36,
        center.dy - cheekHeight * 0.7,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.42,
        center.dy,
        center.dx + radius * 0.22,
        center.dy + cheekHeight * 0.6,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.60,
        center.dy + cheekHeight * 0.5,
        center.dx + radius * 0.72,
        center.dy,
      )
      ..close();

    canvas.drawPath(leftCheek, liningPaint);
    canvas.drawPath(rightCheek, liningPaint);

    // Subtle organic horizontal rib lines
    final ribPaint = Paint()
      ..color = const Color(0xFFC7B198).withOpacity((0.45 * t).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = -2; i <= 2; i++) {
      final yOffset = center.dy + (i * radius * 0.12);
      canvas.drawLine(
        Offset(center.dx - radius * 0.62, yOffset),
        Offset(center.dx - radius * 0.40, yOffset - 3),
        ribPaint,
      );
      canvas.drawLine(
        Offset(center.dx + radius * 0.62, yOffset),
        Offset(center.dx + radius * 0.40, yOffset - 3),
        ribPaint,
      );
    }
  }

  /// Crown dome and two dark nostrils
  void _paintHeadDomeAndNostrils(
    Canvas canvas,
    Offset center,
    double radius,
    double t,
    Color hoodColor,
    Color darkColor,
  ) {
    final domeCenter = Offset(center.dx, center.dy - radius * 0.26);
    final domeRadius = radius * 0.48;

    final domeGradient = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      radius: 0.9,
      colors: [
        Color.lerp(hoodColor, Colors.white, 0.32)!,
        hoodColor,
        darkColor,
      ],
    );

    final domePaint = Paint()
      ..shader = domeGradient.createShader(Rect.fromCircle(center: domeCenter, radius: domeRadius))
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: domeCenter, width: domeRadius * 1.95, height: domeRadius * 1.60),
      domePaint,
    );

    // Two dark nostrils
    final nostrilPaint = Paint()
      ..color = const Color(0xFF0F172A).withOpacity((0.85 * t).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final nostrilY = domeCenter.dy + domeRadius * 0.32;
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 8, nostrilY), width: 4.5, height: 3.5), nostrilPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 8, nostrilY), width: 4.5, height: 3.5), nostrilPaint);
  }

  /// Forked tongue flick animation
  void _paintTongueFlick(Canvas canvas, Offset center, double radius, double progress) {
    final tongueLength = radius * 0.36 * progress;
    final tongueY = center.dy + radius * 0.30;

    final tonguePaint = Paint()
      ..color = const Color(0xFFE11D48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(center.dx, tongueY)..lineTo(center.dx, tongueY + tongueLength);

    // Forked tips
    path.moveTo(center.dx, tongueY + tongueLength);
    path.lineTo(center.dx - 5, tongueY + tongueLength + 8);
    path.moveTo(center.dx, tongueY + tongueLength);
    path.lineTo(center.dx + 5, tongueY + tongueLength + 8);

    canvas.drawPath(path, tonguePaint);
  }

  /// Open mouth cavity with fangs
  void _paintOpenMouthAndFangs(Canvas canvas, Offset center, double radius, double t) {
    final mouthCenter = Offset(center.dx, center.dy + radius * 0.16);
    final mouthWidth = radius * 0.88 * t;
    final mouthHeight = radius * 0.72 * t;

    // Dark mouth cavity
    final mouthPath = Path()
      ..moveTo(mouthCenter.dx - mouthWidth * 0.5, mouthCenter.dy - mouthHeight * 0.35)
      ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy - mouthHeight * 0.45, mouthCenter.dx + mouthWidth * 0.5, mouthCenter.dy - mouthHeight * 0.35)
      ..quadraticBezierTo(mouthCenter.dx + mouthWidth * 0.55, mouthCenter.dy + mouthHeight * 0.40, mouthCenter.dx, mouthCenter.dy + mouthHeight * 0.55)
      ..quadraticBezierTo(mouthCenter.dx - mouthWidth * 0.55, mouthCenter.dy + mouthHeight * 0.40, mouthCenter.dx - mouthWidth * 0.5, mouthCenter.dy - mouthHeight * 0.35)
      ..close();

    final mouthPaint = Paint()
      ..color = theme.mouthCavityColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(mouthPath, mouthPaint);

    // Lower chin curve (cream)
    final chinPaint = Paint()
      ..color = theme.hoodLiningColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * t
      ..strokeCap = StrokeCap.round;

    final chinArc = Path()
      ..moveTo(mouthCenter.dx - mouthWidth * 0.42, mouthCenter.dy + mouthHeight * 0.32)
      ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + mouthHeight * 0.60, mouthCenter.dx + mouthWidth * 0.42, mouthCenter.dy + mouthHeight * 0.32);

    canvas.drawPath(chinArc, chinPaint);

    // Two sharp white fangs on upper jaw
    final fangsPaint = Paint()
      ..color = theme.fangsColor
      ..style = PaintingStyle.fill;

    final fangWidth = 6.0 * t;
    final fangHeight = 16.0 * t;
    final fangY = mouthCenter.dy - mouthHeight * 0.36;

    // Left Fang
    final leftFang = Path()
      ..moveTo(mouthCenter.dx - mouthWidth * 0.28, fangY)
      ..lineTo(mouthCenter.dx - mouthWidth * 0.28 + fangWidth, fangY)
      ..lineTo(mouthCenter.dx - mouthWidth * 0.28 + (fangWidth / 2), fangY + fangHeight)
      ..close();

    // Right Fang
    final rightFang = Path()
      ..moveTo(mouthCenter.dx + mouthWidth * 0.28 - fangWidth, fangY)
      ..lineTo(mouthCenter.dx + mouthWidth * 0.28, fangY)
      ..lineTo(mouthCenter.dx + mouthWidth * 0.28 - (fangWidth / 2), fangY + fangHeight)
      ..close();

    canvas.drawPath(leftFang, fangsPaint);
    canvas.drawPath(rightFang, fangsPaint);
  }

  /// Three glowing white equalizer bars inside the mouth
  void _paintVoiceEqualizerBars(Canvas canvas, Offset center, double radius, double mouthT) {
    final barsCenter = Offset(center.dx, center.dy + radius * 0.16);
    final barWidth = 7.0 * mouthT;
    final spacing = 12.0 * mouthT;

    // Loudness level: external volume or rhythmic sine-wave
    final loudness = (audioLoudness != null && audioLoudness! > 0.01)
        ? audioLoudness!.clamp(0.0, 1.0)
        : (0.35 + 0.55 * (0.5 + 0.5 * math.sin(barsProgress * 2 * math.pi)));

    final heights = [
      (12.0 + 16.0 * (loudness * 0.75)) * mouthT,
      (18.0 + 26.0 * loudness) * mouthT, // Middle tallest
      (14.0 + 18.0 * (loudness * 0.90)) * mouthT,
    ];

    final barPaint = Paint()
      ..color = theme.voiceBarColor
      ..style = PaintingStyle.fill;

    // Soft cyan glow around equalizer bars
    final glowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity((0.55 * mouthT).clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    for (int i = 0; i < 3; i++) {
      final x = barsCenter.dx + ((i - 1) * spacing);
      final h = heights[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, barsCenter.dy), width: barWidth, height: h),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, glowPaint);
      canvas.drawRRect(rect, barPaint);
    }
  }

  /// Big cartoon cobra eyes with golden amber iris, dark pupils, and specular highlights
  void _paintCobraEyes(Canvas canvas, Offset center, double radius, double t, double blink) {
    final eyeY = center.dy - radius * 0.32;
    final eyeSpacing = radius * 0.34;
    final eyeWidth = radius * 0.26 * t;
    final eyeHeight = radius * 0.22 * t * (1.0 - (blink * 0.88)); // Squishes on blink

    for (final dir in [-1.0, 1.0]) {
      final eyeCenter = Offset(center.dx + (dir * eyeSpacing), eyeY);

      // Amber Iris / Eye Sphere
      final eyeGradient = RadialGradient(
        center: const Alignment(-0.25, -0.25),
        radius: 0.85,
        colors: [
          const Color(0xFFFEF3C7),
          theme.eyeColor,
          const Color(0xFFB45309),
        ],
      );

      final eyePaint = Paint()
        ..shader = eyeGradient.createShader(Rect.fromCenter(center: eyeCenter, width: eyeWidth, height: eyeHeight))
        ..style = PaintingStyle.fill;

      canvas.drawOval(Rect.fromCenter(center: eyeCenter, width: eyeWidth, height: eyeHeight), eyePaint);

      // Dark Vertical Pupil
      if (blink < 0.6) {
        final pupilPaint = Paint()
          ..color = const Color(0xFF1C1917)
          ..style = PaintingStyle.fill;

        canvas.drawOval(
          Rect.fromCenter(center: eyeCenter, width: eyeWidth * 0.28, height: eyeHeight * 0.78),
          pupilPaint,
        );

        // Specular White Highlight Dot
        final highlightPaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(eyeCenter.dx - 3, eyeCenter.dy - 3), 2.8 * t, highlightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CobraVoicePainter oldDelegate) {
    return oldDelegate.morphProgress != morphProgress ||
        oldDelegate.mouthProgress != mouthProgress ||
        oldDelegate.eyesProgress != eyesProgress ||
        oldDelegate.rippleProgress != rippleProgress ||
        oldDelegate.barsProgress != barsProgress ||
        oldDelegate.blinkProgress != blinkProgress ||
        oldDelegate.tongueProgress != tongueProgress ||
        oldDelegate.audioLoudness != audioLoudness ||
        oldDelegate.state != state;
  }
}
