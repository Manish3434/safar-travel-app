import 'package:flutter/material.dart';

/// Painter that draws the 10 px twisted rope track and its frayed loose bottom end.
///
/// Features:
/// - 10 px wide twisted rope track.
/// - Diagonal helical thread stripes spaced evenly along the track.
/// - Soft bilateral drop shadow.
/// - Frayed, untied bottom tassel fibers hanging loose ~18 px above the sea waves.
class RopePainter extends CustomPainter {
  final double ropeCenterX;
  final double startY;
  final double endY;
  final bool isDark;

  const RopePainter({
    required this.ropeCenterX,
    required this.startY,
    required this.endY,
    required this.isDark,
  });

  static const double ropeWidth = 10.0;
  static const double halfWidth = ropeWidth / 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (endY <= startY) return;

    final ropeRect = Rect.fromLTRB(
      ropeCenterX - halfWidth,
      startY,
      ropeCenterX + halfWidth,
      endY,
    );

    // ── 1. Soft Drop Shadow ──────────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = isDark ? Colors.black.withOpacity(0.40) : Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          ropeRect.left + 1.2,
          ropeRect.top,
          ropeRect.right + 2.4,
          ropeRect.bottom + 2.0,
        ),
        const Radius.circular(halfWidth),
      ),
      shadowPaint,
    );

    // ── 2. Rope Body Base Gradient ───────────────────────────────────────────
    // Warm tan gradient simulating rounded 3D cylinder
    final baseGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: isDark
          ? const [
              Color(0xFF8C5D30),
              Color(0xFFBA874E),
              Color(0xFFD4A373),
              Color(0xFF9E6E3D),
              Color(0xFF6B421A),
            ]
          : const [
              Color(0xFFB07D48),
              Color(0xFFDDB07A),
              Color(0xFFF3D5A5),
              Color(0xFFC59560),
              Color(0xFF8A5928),
            ],
      stops: const [0.0, 0.25, 0.55, 0.85, 1.0],
    );

    final ropePaint = Paint()
      ..shader = baseGradient.createShader(ropeRect)
      ..style = PaintingStyle.fill;

    // Draw cylindrical rope column with rounded top
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        ropeRect,
        topLeft: const Radius.circular(halfWidth),
        topRight: const Radius.circular(halfWidth),
        bottomLeft: const Radius.circular(2.0),
        bottomRight: const Radius.circular(2.0),
      ),
      ropePaint,
    );

    // ── 3. Diagonal Helical Twist Stripes ────────────────────────────────────
    final stripeDarkPaint = Paint()
      ..color = isDark ? const Color(0xFF523314).withOpacity(0.75) : const Color(0xFF6B421A).withOpacity(0.65)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final stripeLightPaint = Paint()
      ..color = isDark ? const Color(0xFFF1D19C).withOpacity(0.35) : const Color(0xFFFFF2D8).withOpacity(0.55)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    const stripeStep = 7.5;
    const stripeSlopeY = 5.0; // Angle of twist

    for (double y = startY + 2.0; y < endY - 4.0; y += stripeStep) {
      final p1 = Offset(ropeCenterX - halfWidth + 0.8, y);
      final p2 = Offset(ropeCenterX + halfWidth - 0.8, y + stripeSlopeY);

      // Dark shadow indentation of rope twist
      canvas.drawLine(p1, p2, stripeDarkPaint);

      // Light catchlight highlight right above indentation
      canvas.drawLine(
        Offset(p1.dx, p1.dy - 1.2),
        Offset(p2.dx, p2.dy - 1.2),
        stripeLightPaint,
      );
    }

    // ── 4. Loose Frayed Tassel Fibers at Bottom ──────────────────────────────
    // The rope is NOT tied to anything at the sea. Fibers hang loose and frayed.
    _drawFrayedEnd(canvas, ropeCenterX, endY);
  }

  void _drawFrayedEnd(Canvas canvas, double cx, double ey) {
    // Frayed fibers palette
    final fiberColors = [
      const Color(0xFFC59560),
      const Color(0xFF8A5928),
      const Color(0xFFDDB07A),
      const Color(0xFF6B421A),
      const Color(0xFFF3D5A5),
    ];

    // Fray strands configuration: (dxOffset, length, curve)
    final strands = [
      (-4.2, 12.0, -2.8),
      (-2.0, 14.5, -1.2),
      (0.0, 15.5, 0.4),
      (2.2, 13.8, 1.8),
      (4.0, 11.2, 3.2),
      (-3.2, 8.5, -1.5),
      (3.0, 9.0, 2.0),
    ];

    for (int i = 0; i < strands.length; i++) {
      final strand = strands[i];
      final color = fiberColors[i % fiberColors.length];

      final strandPaint = Paint()
        ..color = color
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(cx + strand.$1 * 0.7, ey)
        ..quadraticBezierTo(
          cx + strand.$1 + strand.$3 * 0.5,
          ey + strand.$2 * 0.5,
          cx + strand.$1 + strand.$3,
          ey + strand.$2,
        );

      canvas.drawPath(path, strandPaint);
    }

    // Frayed collar / pinch band right at the fray break
    final collarPaint = Paint()
      ..color = const Color(0xFF5A3512)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(cx - halfWidth + 0.5, ey - 1.0),
      Offset(cx + halfWidth - 0.5, ey - 1.0),
      collarPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RopePainter oldDelegate) {
    return oldDelegate.ropeCenterX != ropeCenterX ||
        oldDelegate.startY != startY ||
        oldDelegate.endY != endY ||
        oldDelegate.isDark != isDark;
  }
}
