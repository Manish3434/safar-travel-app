import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Painter that draws the snow-capped mountain summit at the top of the RopeScrollbar.
///
/// Features:
/// - Primary summit at x ≈ 48, y ≈ 14.
/// - Secondary peak at x ≈ 18, y ≈ 42.
/// - Two-toned faces (lighter left slope, darker right slope) with subtle shading.
/// - Crisp zig-zag snow cap.
/// - Wooden summit peg with rope wrapped twice around it.
/// - Gradient fade at base blending smoothly into page background.
class MountainPainter extends CustomPainter {
  final bool isDark;
  final Color? backgroundColor;

  const MountainPainter({
    required this.isDark,
    this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Mountain rock palette
    final leftFaceColor = isDark ? const Color(0xFF273549) : const Color(0xFF64748B);
    final leftFaceMid = isDark ? const Color(0xFF1E293B) : const Color(0xFF475569);
    final rightFaceColor = isDark ? const Color(0xFF0F172A) : const Color(0xFF334155);
    final ridgeColor = isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8);

    // ── 1. Secondary Peak (Left) ─────────────────────────────────────────────
    final secPeakPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.6)
      ..lineTo(w * 0.20, h * 0.36) // Secondary summit
      ..lineTo(w * 0.45, h)
      ..close();

    final secPeakPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          leftFaceMid,
          leftFaceColor.withOpacity(0.85),
          leftFaceMid.withOpacity(0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(secPeakPath, secPeakPaint);

    // ── 2. Primary Mountain Body (Left Face & Right Face) ────────────────────
    final summitX = w * 0.53; // ~48 px on 90 px width
    final summitY = h * 0.12; // ~14 px on 112 px height

    // Left Face Path
    final leftFacePath = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.08, h * 0.50)
      ..lineTo(summitX, summitY)
      ..lineTo(summitX + 2, h * 0.75)
      ..lineTo(w * 0.40, h)
      ..close();

    final leftFacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          leftFaceColor,
          leftFaceMid,
          leftFaceMid.withOpacity(0.0),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(leftFacePath, leftFacePaint);

    // Right Face Path (Darker, shadow side)
    final rightFacePath = Path()
      ..moveTo(summitX, summitY)
      ..lineTo(w, h * 0.85)
      ..lineTo(w, h)
      ..lineTo(w * 0.38, h)
      ..lineTo(summitX + 2, h * 0.75)
      ..close();

    final rightFacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          rightFaceColor,
          rightFaceColor.withOpacity(0.9),
          rightFaceColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(rightFacePath, rightFacePaint);

    // Ridge Line
    final ridgePaint = Paint()
      ..color = ridgeColor.withOpacity(0.65)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(summitX, summitY), Offset(summitX + 2, h * 0.75), ridgePaint);

    // ── 3. Snow Cap (Zig-zag Edge) ───────────────────────────────────────────
    final snowWhite = isDark ? const Color(0xFFF1F5F9) : const Color(0xFFFFFFFF);
    final snowShadow = isDark ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0);

    // Secondary Peak Snow
    final secSnowPath = Path()
      ..moveTo(w * 0.10, h * 0.46)
      ..lineTo(w * 0.20, h * 0.36)
      ..lineTo(w * 0.30, h * 0.48)
      ..lineTo(w * 0.25, h * 0.45)
      ..lineTo(w * 0.20, h * 0.49)
      ..lineTo(w * 0.15, h * 0.44)
      ..close();
    canvas.drawPath(secSnowPath, Paint()..color = snowShadow);

    // Primary Summit Snow Cap (Zig-Zag)
    final snowPath = Path()
      ..moveTo(w * 0.30, h * 0.30)
      ..lineTo(w * 0.40, h * 0.21)
      ..lineTo(summitX, summitY)
      ..lineTo(w * 0.68, h * 0.25)
      ..lineTo(w * 0.82, h * 0.38)
      // Zig-zag lower contour
      ..lineTo(w * 0.74, h * 0.33)
      ..lineTo(w * 0.68, h * 0.38)
      ..lineTo(w * 0.61, h * 0.31)
      ..lineTo(summitX + 1, h * 0.36)
      ..lineTo(w * 0.46, h * 0.29)
      ..lineTo(w * 0.41, h * 0.35)
      ..lineTo(w * 0.35, h * 0.28)
      ..close();

    final snowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [snowWhite, snowShadow],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.45));
    canvas.drawPath(snowPath, snowPaint);

    // ── 4. Wooden Summit Peg ─────────────────────────────────────────────────
    final pegX = summitX;
    final pegTopY = summitY - 14.0;
    final pegBottomY = summitY + 4.0;
    const pegRadius = 3.8;

    // Peg drop shadow
    final pegShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(pegX - pegRadius + 1.5, pegTopY + 1.5, pegX + pegRadius + 2.5, pegBottomY + 1.5),
        const Radius.circular(2.5),
      ),
      pegShadowPaint,
    );

    // Peg wood cylinder
    final pegWoodPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8B5A2B), Color(0xFFB87D43), Color(0xFF6B421A)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(pegX - pegRadius, pegTopY, pegRadius * 2, pegBottomY - pegTopY));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(pegX - pegRadius, pegTopY, pegX + pegRadius, pegBottomY),
        const Radius.circular(2.5),
      ),
      pegWoodPaint,
    );

    // Rounded peg head with subtle wood grain ring
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pegX, pegTopY), width: pegRadius * 2, height: 3.5),
      Paint()..color = const Color(0xFFD49B5B),
    );

    // ── 5. Double Rope Loop Wrapped Around Peg ──────────────────────────────
    // Loop 1 (upper coil)
    _drawRopeCoil(canvas, Offset(pegX, pegTopY + 6.0), pegRadius + 2.2, 3.8);
    // Loop 2 (lower coil)
    _drawRopeCoil(canvas, Offset(pegX, pegTopY + 10.5), pegRadius + 2.4, 4.0);

    // Knot tie detail
    final knotPaint = Paint()..color = const Color(0xFF8C5828);
    canvas.drawCircle(Offset(pegX + pegRadius + 1.0, pegTopY + 9.0), 2.2, knotPaint);
  }

  void _drawRopeCoil(Canvas canvas, Offset center, double rx, double ry) {
    // Coil shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..strokeWidth = 3.6
      ..style = PaintingStyle.stroke;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + 0.8, center.dy + 1.0), width: rx * 2, height: ry * 2),
      shadowPaint,
    );

    // Main coil
    final coilPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFDDB07A), Color(0xFFB57C45), Color(0xFF8C5828)],
      ).createShader(Rect.fromCenter(center: center, width: rx * 2, height: ry * 2))
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      coilPaint,
    );

    // Twist marks
    final twistPaint = Paint()
      ..color = const Color(0xFF6B421A).withOpacity(0.85)
      ..strokeWidth = 1.0;
    for (double angle = -math.pi * 0.8; angle <= math.pi * 0.8; angle += math.pi * 0.45) {
      final p1 = Offset(center.dx + math.cos(angle) * (rx - 1.5), center.dy + math.sin(angle) * (ry - 1.5));
      final p2 = Offset(center.dx + math.cos(angle) * (rx + 1.5), center.dy + math.sin(angle) * (ry + 1.5));
      canvas.drawLine(p1, p2, twistPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MountainPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.backgroundColor != backgroundColor;
  }
}
