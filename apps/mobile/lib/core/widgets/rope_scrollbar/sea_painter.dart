import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Painter that draws the ocean and gently moving waves at the bottom of the RopeScrollbar.
///
/// Features:
/// - Width ≈ 90 px, Height ≈ 80 px.
/// - Two wave layers moving slowly at different speeds.
/// - Back layer: deeper blue gradient for depth.
/// - Front layer: vibrant cyan/teal gradient with a delicate 1.8 px foam crest.
/// - Respects reduceMotion (freezes wave progress).
class SeaPainter extends CustomPainter {
  final double waveProgress;
  final bool isDark;
  final bool reduceMotion;

  const SeaPainter({
    required this.waveProgress,
    required this.isDark,
    required this.reduceMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Water level baseline: ~22 px down from the top of the 80 px sea box
    final baseWaterY = h * 0.28;

    // Wave motion phases (static if reduceMotion is active)
    final phase1 = reduceMotion ? 0.0 : waveProgress * 2.0 * math.pi;
    final phase2 = reduceMotion ? 1.2 : waveProgress * 2.0 * math.pi * 1.55 + 1.2;

    // Palette configuration
    final backColorTop = isDark ? const Color(0xFF0369A1) : const Color(0xFF0284C7);
    final backColorBottom = isDark ? const Color(0xFF082F49) : const Color(0xFF0369A1);

    final frontColorTop = isDark ? const Color(0xFF0EA5E9) : const Color(0xFF38BDF8);
    final frontColorBottom = isDark ? const Color(0xFF0284C7) : const Color(0xFF075985);

    // ── 1. Back Wave Layer (Deeper, Slower) ──────────────────────────────────
    final backPath = Path()..moveTo(0, h);
    backPath.lineTo(0, baseWaterY);

    const step = 3.0;
    for (double x = 0; x <= w + step; x += step) {
      final y = baseWaterY +
          math.sin((x / w) * 2.2 * math.pi + phase1) * 4.2 +
          math.sin((x / w) * 4.0 * math.pi + phase1 * 0.7) * 1.8;
      backPath.lineTo(x, y);
    }

    backPath.lineTo(w, h);
    backPath.close();

    final backPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [backColorTop.withOpacity(0.85), backColorBottom],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(backPath, backPaint);

    // ── 2. Front Wave Layer (Vibrant, Faster, Detailed Crest) ────────────────
    final frontPath = Path()..moveTo(0, h);
    final crestPath = Path();

    bool isFirst = true;
    for (double x = 0; x <= w + step; x += step) {
      final y = baseWaterY +
          4.0 +
          math.sin((x / w) * 2.6 * math.pi + phase2) * 5.0 +
          math.cos((x / w) * 5.0 * math.pi + phase2 * 1.2) * 2.0;

      if (isFirst) {
        frontPath.lineTo(0, y);
        crestPath.moveTo(0, y);
        isFirst = false;
      } else {
        frontPath.lineTo(x, y);
        crestPath.lineTo(x, y);
      }
    }

    frontPath.lineTo(w, h);
    frontPath.close();

    final frontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [frontColorTop, frontColorBottom],
        stops: const [0.0, 0.85],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(frontPath, frontPaint);

    // ── 3. Wave Foam Crest Line ──────────────────────────────────────────────
    final crestPaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.45 : 0.75)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(crestPath, crestPaint);

    // Sub-surface reflective glimmer highlights
    final glimmerPaint = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final glimmerY = baseWaterY + 14.0;
    canvas.drawLine(
      Offset(w * 0.20 + math.sin(phase1) * 3.0, glimmerY),
      Offset(w * 0.48 + math.sin(phase1) * 3.0, glimmerY),
      glimmerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.58 - math.sin(phase2) * 4.0, glimmerY + 7.0),
      Offset(w * 0.82 - math.sin(phase2) * 4.0, glimmerY + 7.0),
      glimmerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SeaPainter oldDelegate) {
    return oldDelegate.waveProgress != waveProgress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.reduceMotion != reduceMotion;
  }
}
