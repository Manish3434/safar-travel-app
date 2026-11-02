import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Articulated poses for the cartoon traveler climber.
enum TravelerPose {
  idle,
  climbLeft,
  climbRight,
}

/// Painter that renders the original vector cartoon traveler climber.
///
/// Features (inspired by the owner's reference character):
/// - Explorer hat (brown with red ribbon band).
/// - Cheerful face with friendly smile, expressive eyes, and rosy cheeks.
/// - White explorer shirt with red straps.
/// - Orange backpack with cylindrical bedroll strapped on top.
/// - Brown trousers and hiking boots.
/// - Articulated arm and leg positions for idle, climbLeft, and climbRight.
/// - Sway angle for gentle lateral idle breathing motion.
class TravelerPainter extends CustomPainter {
  final TravelerPose pose;
  final double swayAngle;
  final bool isDark;

  const TravelerPainter({
    required this.pose,
    this.swayAngle = 0.0,
    required this.isDark,
  });

  static const Color outlineColor = Color(0xFF2E1508);
  static const Color skinColor = Color(0xFFFFDBAC);
  static const Color skinShadow = Color(0xFFE0B584);
  static const Color hatBrown = Color(0xFFA66A38);
  static const Color hatDark = Color(0xFF7A471C);
  static const Color redBand = Color(0xFFDC2626);
  static const Color shirtWhite = Color(0xFFF8FAFC);
  static const Color shirtShadow = Color(0xFFE2E8F0);
  static const Color backpackOrange = Color(0xFFEA580C);
  static const Color bedrollGreen = Color(0xFF4D7C0F);
  static const Color pantsBrown = Color(0xFF6B4226);
  static const Color bootDark = Color(0xFF331A0B);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0; // 28.0 px
    const cy = 44.0; // Pivot / center of character

    canvas.save();

    // Pivot around upper chest / hand grip area for natural rope sway
    canvas.translate(cx, cy - 8.0);
    if (swayAngle != 0.0) {
      canvas.rotate(swayAngle);
    }
    canvas.translate(-cx, -(cy - 8.0));

    // ── 1. Orange Backpack & Bedroll (Drawn Behind Torso) ───────────────────
    _drawBackpack(canvas, cx);

    // ── 2. Legs & Boots (Drawn Behind Shirt) ─────────────────────────────────
    _drawLegs(canvas, cx);

    // ── 3. Torso & White Shirt with Red Straps ───────────────────────────────
    _drawTorso(canvas, cx);

    // ── 4. Head, Face & Explorer Hat ─────────────────────────────────────────
    _drawHeadAndHat(canvas, cx);

    // ── 5. Arms & Hands Gripping the Rope ───────────────────────────────────
    _drawArms(canvas, cx);

    canvas.restore();
  }

  void _drawBackpack(Canvas canvas, double cx) {
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    // Bedroll on top (cylinder)
    final bedrollRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 28.0), width: 34.0, height: 10.0),
      const Radius.circular(5.0),
    );
    canvas.drawRRect(bedrollRect, Paint()..color = bedrollGreen);
    canvas.drawRRect(bedrollRect, outlinePaint);

    // Bedroll strap buckles
    final strapPaint = Paint()..color = const Color(0xFF3A2010);
    canvas.drawLine(Offset(cx - 9.0, 23.0), Offset(cx - 9.0, 33.0), strapPaint);
    canvas.drawLine(Offset(cx + 9.0, 23.0), Offset(cx + 9.0, 33.0), strapPaint);

    // Backpack main pouch (visible around torso sides)
    final backpackRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 44.0), width: 32.0, height: 26.0),
      const Radius.circular(8.0),
    );
    canvas.drawRRect(backpackRect, Paint()..color = backpackOrange);
    canvas.drawRRect(backpackRect, outlinePaint);

    // Backpack pocket details
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 47.0), width: 18.0, height: 12.0),
        const Radius.circular(4.0),
      ),
      Paint()..color = const Color(0xFFC2410C),
    );
  }

  void _drawLegs(Canvas canvas, double cx) {
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    final pantsPaint = Paint()..color = pantsBrown;
    final bootPaint = Paint()..color = bootDark;

    switch (pose) {
      case TravelerPose.idle:
        // Both legs hanging down together gripping rope
        // Left Leg
        _drawLimb(canvas, Offset(cx - 5.5, 54.0), Offset(cx - 4.5, 68.0), pantsPaint, outlinePaint, 7.0);
        // Left Boot
        _drawBoot(canvas, Offset(cx - 3.5, 73.0), bootPaint, outlinePaint, isLeft: true);

        // Right Leg
        _drawLimb(canvas, Offset(cx + 5.5, 54.0), Offset(cx + 4.5, 68.0), pantsPaint, outlinePaint, 7.0);
        // Right Boot
        _drawBoot(canvas, Offset(cx + 3.5, 73.0), bootPaint, outlinePaint, isLeft: false);
        break;

      case TravelerPose.climbLeft:
        // Left leg straight gripping lower; Right knee bent upward higher
        // Left Leg (extended)
        _drawLimb(canvas, Offset(cx - 5.5, 54.0), Offset(cx - 3.0, 71.0), pantsPaint, outlinePaint, 7.0);
        _drawBoot(canvas, Offset(cx - 2.0, 76.0), bootPaint, outlinePaint, isLeft: true);

        // Right Leg (bent high)
        _drawLimb(canvas, Offset(cx + 6.0, 53.0), Offset(cx + 10.0, 62.0), pantsPaint, outlinePaint, 7.0);
        _drawBoot(canvas, Offset(cx + 8.5, 67.0), bootPaint, outlinePaint, isLeft: false);
        break;

      case TravelerPose.climbRight:
        // Right leg straight gripping lower; Left knee bent upward higher
        // Left Leg (bent high)
        _drawLimb(canvas, Offset(cx - 6.0, 53.0), Offset(cx - 10.0, 62.0), pantsPaint, outlinePaint, 7.0);
        _drawBoot(canvas, Offset(cx - 8.5, 67.0), bootPaint, outlinePaint, isLeft: true);

        // Right Leg (extended)
        _drawLimb(canvas, Offset(cx + 5.5, 54.0), Offset(cx + 3.0, 71.0), pantsPaint, outlinePaint, 7.0);
        _drawBoot(canvas, Offset(cx + 2.0, 76.0), bootPaint, outlinePaint, isLeft: false);
        break;
    }
  }

  void _drawLimb(Canvas canvas, Offset start, Offset end, Paint fill, Paint outline, double thickness) {
    final limbPaint = Paint()
      ..color = fill.color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, limbPaint);

    final outPaint = Paint()
      ..color = outline.color
      ..strokeWidth = thickness + 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, outPaint);
    canvas.drawLine(start, end, limbPaint);
  }

  void _drawBoot(Canvas canvas, Offset pos, Paint fill, Paint outline, {required bool isLeft}) {
    final bootPath = Path();
    final dir = isLeft ? 1.0 : -1.0;
    bootPath.moveTo(pos.dx - 3.5, pos.dy - 3.0);
    bootPath.lineTo(pos.dx + 3.5, pos.dy - 3.0);
    bootPath.lineTo(pos.dx + 4.0 * dir, pos.dy + 4.5);
    bootPath.lineTo(pos.dx - 6.0 * dir, pos.dy + 4.5);
    bootPath.close();

    canvas.drawPath(bootPath, fill);
    canvas.drawPath(bootPath, outline);

    // Boot sole grip line
    canvas.drawLine(
      Offset(pos.dx - 6.0 * dir, pos.dy + 4.5),
      Offset(pos.dx + 4.0 * dir, pos.dy + 4.5),
      Paint()
        ..color = const Color(0xFF180A04)
        ..strokeWidth = 1.4,
    );
  }

  void _drawTorso(Canvas canvas, double cx) {
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 44.5), width: 22.0, height: 21.0),
      const Radius.circular(6.0),
    );

    // White shirt with subtle shading
    final shirtPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [shirtWhite, shirtShadow],
      ).createShader(Rect.fromCenter(center: Offset(cx, 44.5), width: 22.0, height: 21.0));

    canvas.drawRRect(torsoRect, shirtPaint);
    canvas.drawRRect(torsoRect, outlinePaint);

    // Red suspender / backpack chest straps
    final strapPaint = Paint()
      ..color = redBand
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(Offset(cx - 5.5, 35.0), Offset(cx - 5.5, 54.0), strapPaint);
    canvas.drawLine(Offset(cx + 5.5, 35.0), Offset(cx + 5.5, 54.0), strapPaint);

    // Horizontal chest buckle
    final bucklePaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(cx - 5.5, 43.0), Offset(cx + 5.5, 43.0), bucklePaint);

    // Silver buckle clasp
    canvas.drawCircle(Offset(cx, 43.0), 1.8, Paint()..color = const Color(0xFFE2E8F0));
  }

  void _drawHeadAndHat(Canvas canvas, double cx) {
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    // ── Neck ─────────────────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, 33.5), width: 7.0, height: 4.0),
      Paint()..color = skinShadow,
    );

    // ── Head ─────────────────────────────────────────────────────────────────
    final headCenter = Offset(cx, 24.0);
    const headRadius = 10.5;

    final headPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.2),
        radius: 0.9,
        colors: [skinColor, skinShadow],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));

    canvas.drawCircle(headCenter, headRadius, headPaint);
    canvas.drawCircle(headCenter, headRadius, outlinePaint);

    // ── Facial Features ──────────────────────────────────────────────────────
    // Cheerful Rosy Cheeks
    final cheekPaint = Paint()..color = const Color(0xFFF87171).withOpacity(0.55);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 6.5, 26.5), width: 4.0, height: 2.5), cheekPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 6.5, 26.5), width: 4.0, height: 2.5), cheekPaint);

    // Big friendly cartoon eyes
    _drawEye(canvas, Offset(cx - 3.8, 22.0));
    _drawEye(canvas, Offset(cx + 3.8, 22.0));

    // Cute button nose
    final nosePaint = Paint()
      ..color = const Color(0xFFD49A6A)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, 24.5), width: 2.4, height: 2.0),
      0,
      math.pi,
      false,
      nosePaint,
    );

    // Warm friendly smile
    final smilePaint = Paint()
      ..color = outlineColor
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final smilePath = Path()
      ..moveTo(cx - 4.5, 27.5)
      ..quadraticBezierTo(cx, 31.0, cx + 4.5, 27.5);
    canvas.drawPath(smilePath, smilePaint);

    // ── Explorer Hat ─────────────────────────────────────────────────────────
    // Hat Brim (curved wide oval)
    final brimRect = Rect.fromCenter(center: Offset(cx, 16.5), width: 34.0, height: 9.0);
    final brimPath = Path()
      ..moveTo(cx - 17.0, 17.0)
      ..quadraticBezierTo(cx, 13.5, cx + 17.0, 17.0)
      ..quadraticBezierTo(cx, 20.0, cx - 17.0, 17.0)
      ..close();

    canvas.drawPath(brimPath, Paint()..color = hatBrown);
    canvas.drawPath(brimPath, outlinePaint);

    // Hat Crown (tall rounded dome)
    final crownPath = Path()
      ..moveTo(cx - 10.0, 16.0)
      ..lineTo(cx - 8.0, 5.0)
      ..quadraticBezierTo(cx, 2.5, cx + 8.0, 5.0)
      ..lineTo(cx + 10.0, 16.0)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [hatBrown, hatDark],
      ).createShader(brimRect);

    canvas.drawPath(crownPath, crownPaint);
    canvas.drawPath(crownPath, outlinePaint);

    // Red ribbon band around crown base
    final ribbonPath = Path()
      ..moveTo(cx - 9.8, 15.5)
      ..lineTo(cx - 9.2, 11.5)
      ..quadraticBezierTo(cx, 10.0, cx + 9.2, 11.5)
      ..lineTo(cx + 9.8, 15.5)
      ..close();

    canvas.drawPath(ribbonPath, Paint()..color = redBand);
    canvas.drawPath(ribbonPath, outlinePaint);
  }

  void _drawEye(Canvas canvas, Offset pos) {
    // White sclera
    canvas.drawOval(Rect.fromCenter(center: pos, width: 3.8, height: 4.8), Paint()..color = Colors.white);

    // Pupil
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 0.3), width: 2.4, height: 3.0),
      Paint()..color = outlineColor,
    );

    // Catchlight highlight
    canvas.drawCircle(Offset(pos.dx - 0.7, pos.dy - 0.9), 0.7, Paint()..color = Colors.white);
  }

  void _drawArms(Canvas canvas, double cx) {
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    final handPaint = Paint()..color = skinColor;
    final sleevePaint = Paint()..color = shirtWhite;

    switch (pose) {
      case TravelerPose.idle:
        // Both hands gripping rope in front of chest
        // Left arm
        _drawArmSegment(canvas, Offset(cx - 10.0, 38.0), Offset(cx - 2.5, 41.0), sleevePaint, outlinePaint);
        _drawHandGrip(canvas, Offset(cx - 2.0, 41.0), handPaint, outlinePaint);

        // Right arm
        _drawArmSegment(canvas, Offset(cx + 10.0, 38.0), Offset(cx + 2.5, 43.5), sleevePaint, outlinePaint);
        _drawHandGrip(canvas, Offset(cx + 2.0, 43.5), handPaint, outlinePaint);
        break;

      case TravelerPose.climbLeft:
        // Left hand reaches high up on the rope; Right hand holds rope lower
        // Left Arm (high)
        _drawArmSegment(canvas, Offset(cx - 10.0, 37.0), Offset(cx - 2.0, 24.0), sleevePaint, outlinePaint);
        _drawHandGrip(canvas, Offset(cx - 1.5, 23.5), handPaint, outlinePaint);

        // Right Arm (mid/lower)
        _drawArmSegment(canvas, Offset(cx + 10.0, 38.0), Offset(cx + 2.5, 45.0), sleevePaint, outlinePaint);
        _drawHandGrip(canvas, Offset(cx + 2.0, 45.0), handPaint, outlinePaint);
        break;

      case TravelerPose.climbRight:
        // Right hand reaches high up on the rope; Left hand holds rope lower
        // Left Arm (mid/lower)
        _drawArmSegment(canvas, Offset(cx - 10.0, 38.0), Offset(cx - 2.5, 45.0), sleevePaint, outlinePaint);
        _drawHandGrip(canvas, Offset(cx - 2.0, 45.0), handPaint, outlinePaint);

        // Right Arm (high)
        _drawArmSegment(canvas, Offset(cx + 10.0, 37.0), Offset(cx + 2.0, 24.0), sleevePaint, outlinePaint);
        _drawHandGrip(canvas, Offset(cx + 1.5, 23.5), handPaint, outlinePaint);
        break;
    }
  }

  void _drawArmSegment(Canvas canvas, Offset start, Offset end, Paint fill, Paint outline) {
    final armPaint = Paint()
      ..color = fill.color
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, armPaint);

    final outPaint = Paint()
      ..color = outline.color
      ..strokeWidth = 8.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, outPaint);
    canvas.drawLine(start, end, armPaint);
  }

  void _drawHandGrip(Canvas canvas, Offset pos, Paint fill, Paint outline) {
    // Cartoon glove / fist wrapping around the rope
    canvas.drawCircle(pos, 3.8, fill);
    canvas.drawCircle(pos, 3.8, outline);

    // Finger separation notches
    final notchPaint = Paint()
      ..color = outlineColor
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(pos.dx - 1.5, pos.dy - 1.5), Offset(pos.dx + 1.5, pos.dy - 1.5), notchPaint);
    canvas.drawLine(Offset(pos.dx - 1.5, pos.dy + 1.0), Offset(pos.dx + 1.5, pos.dy + 1.0), notchPaint);
  }

  @override
  bool shouldRepaint(covariant TravelerPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.swayAngle != swayAngle ||
        oldDelegate.isDark != isDark;
  }
}
