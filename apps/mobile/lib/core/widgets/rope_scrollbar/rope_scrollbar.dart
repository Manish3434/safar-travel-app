import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'mountain_painter.dart';
import 'rope_painter.dart';
import 'sea_painter.dart';
import 'traveler_painter.dart';

export 'mountain_painter.dart';
export 'rope_painter.dart';
export 'sea_painter.dart';
export 'traveler_painter.dart';

/// Reusable RopeScrollbar widget.
///
/// Replaces the default scrollbar on any long list or screen with a delightful,
/// interactive custom climber experience:
/// - Top: Snow-capped mountain with wooden summit peg and tied rope loops.
/// - Track: 10 px twisted warm-tan rope with soft shadow.
/// - Bottom: Moving ocean waves; rope hangs loose and frayed ~18 px above water.
/// - Thumb: Vector cartoon traveler climber that alternates climbing poses every ~34 px
///   of scroll, sways gently when idle, and follows the scroll position at 25% lerp per frame.
/// - Dragging the traveler scrolls the list; tapping the rope jumps to that spot.
/// - Respects "reduce motion", accessibility semantics, and hides when content fits on screen.
class RopeScrollbar extends StatefulWidget {
  /// The scrollable child widget (e.g. CustomScrollView, ListView).
  final Widget child;

  /// The scroll controller attached to the child list.
  /// If null, RopeScrollbar will track via ScrollNotifications.
  final ScrollController? controller;

  /// Right padding reserved for content so cards never sit under the artwork.
  /// Defaults to 88.0 px as specified.
  final double paddingRight;

  /// Whether the cartoon traveler climber is enabled on the rope.
  final bool enableClimber;

  const RopeScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.paddingRight = 88.0,
    this.enableClimber = true,
  });

  @override
  State<RopeScrollbar> createState() => _RopeScrollbarState();
}

class _RopeScrollbarState extends State<RopeScrollbar> with TickerProviderStateMixin {
  // ── Dimensions ─────────────────────────────────────────────────────────────
  static const double artworkWidth = 90.0;
  static const double mountainHeight = 112.0;
  static const double seaHeight = 80.0;
  static const double ropeCenterX = 48.0; // Aligned with summit peg
  static const double travelerWidth = 56.0;
  static const double travelerHeight = 88.0;

  // ── Animation Controllers ──────────────────────────────────────────────────
  late final AnimationController _waveController;
  Ticker? _physicsTicker;

  // ── Scroll State ───────────────────────────────────────────────────────────
  double _scrollOffset = 0.0;
  double _maxScrollExtent = 0.0;
  double _viewportDimension = 0.0;

  // ── Climber State ──────────────────────────────────────────────────────────
  double _currentTravelerY = 24.0;
  double _targetTravelerY = 24.0;
  TravelerPose _pose = TravelerPose.idle;
  double _accumulatedScrollDelta = 0.0;
  double _lastScrollOffset = 0.0;
  Timer? _idleDebounceTimer;
  double _idleTime = 0.0;
  double _swayAngle = 0.0;

  // ── Dragging State ─────────────────────────────────────────────────────────
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    // 1. Continuous wave animation (60 fps)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // 2. Physics & smoothing frame ticker (lerp 25% per frame)
    _physicsTicker = createTicker(_onPhysicsTick)..start();

    // 3. Attach controller listener if supplied
    widget.controller?.addListener(_onControllerScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.controller != null && widget.controller!.hasClients) {
        _onControllerScroll();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      if (_waveController.isAnimating) {
        _waveController.stop();
      }
    } else {
      if (!_waveController.isAnimating) {
        _waveController.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(covariant RopeScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerScroll);
      widget.controller?.addListener(_onControllerScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.controller != null && widget.controller!.hasClients) {
          _onControllerScroll();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerScroll);
    _waveController.dispose();
    _physicsTicker?.dispose();
    _idleDebounceTimer?.cancel();
    super.dispose();
  }

  void _onControllerScroll() {
    if (!mounted || widget.controller == null) return;
    final pos = widget.controller!.position;
    _updateScrollMetrics(pos.pixels, pos.maxScrollExtent, pos.viewportDimension);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Only react to the primary vertical scroll notifications
    if (notification.metrics.axis == Axis.vertical) {
      _updateScrollMetrics(
        notification.metrics.pixels,
        notification.metrics.maxScrollExtent,
        notification.metrics.viewportDimension,
      );
    }
    return false; // Allow notification to bubble
  }

  void _updateScrollMetrics(double pixels, double maxExtent, double viewportDim) {
    final delta = (pixels - _lastScrollOffset).abs();
    _lastScrollOffset = pixels;

    setState(() {
      _scrollOffset = pixels.clamp(0.0, math.max(0.0, maxExtent));
      _maxScrollExtent = maxExtent;
      _viewportDimension = viewportDim;
    });

    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (!reduceMotion && widget.enableClimber && delta > 0.5) {
      _accumulatedScrollDelta += delta;

      // Switch climbing pose after every ~34 px of scrolling
      if (_accumulatedScrollDelta >= 34.0) {
        _accumulatedScrollDelta = 0.0;
        setState(() {
          _pose = (_pose == TravelerPose.climbLeft) ? TravelerPose.climbRight : TravelerPose.climbLeft;
        });
      }

      // Reset to idle after ~200 ms of no scrolling
      _idleDebounceTimer?.cancel();
      _idleDebounceTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _pose = TravelerPose.idle;
          });
        }
      });
    }
  }

  void _onPhysicsTick(Duration elapsed) {
    if (!mounted || _viewportDimension <= 0) return;

    final h = _viewportDimension;
    const ropeStartY = 24.0; // Just below summit peg
    final ropeEndY = h - seaHeight + 36.0; // ~18 px above sea water surface

    // Traveler boundaries along the rope:
    // Top: summit peg (y ≈ 10..14)
    // Bottom: feet at frayed end of rope
    const travelerMinY = ropeStartY - 10.0;
    final travelerMaxY = ropeEndY - travelerHeight + 14.0;
    final travelRange = math.max(0.0, travelerMaxY - travelerMinY);

    final scrollFraction = (_maxScrollExtent > 0)
        ? (_scrollOffset / _maxScrollExtent).clamp(0.0, 1.0)
        : 0.0;

    _targetTravelerY = travelerMinY + (scrollFraction * travelRange);

    // Follow smoothly: 25% of the remaining distance per frame
    final diff = _targetTravelerY - _currentTravelerY;
    final needMove = diff.abs() > 0.08;
    if (needMove) {
      _currentTravelerY += diff * 0.25;
    } else {
      _currentTravelerY = _targetTravelerY;
    }

    // Idle sway physics (only when in idle pose and reduce motion is off)
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final needSway = !reduceMotion && _pose == TravelerPose.idle && !_isDragging;
    if (needSway) {
      _idleTime += 0.035;
      _swayAngle = math.sin(_idleTime * 2.4) * 0.045; // ~2.5 degrees subtle sway
    } else {
      _swayAngle = 0.0;
    }

    // Only repaint if moving or swaying
    if (mounted && (needMove || needSway)) {
      setState(() {});
    }
  }

  // ── Drag & Tap Interactions ────────────────────────────────────────────────
  void _onRopeTapDown(TapDownDetails details) {
    if (_maxScrollExtent <= 0) return;

    final h = _viewportDimension;
    const ropeStartY = 24.0;
    final ropeEndY = h - seaHeight + 36.0;
    final ropeLength = ropeEndY - ropeStartY;

    if (ropeLength <= 0) return;

    final tapY = details.localPosition.dy.clamp(ropeStartY, ropeEndY);
    final ratio = ((tapY - ropeStartY) / ropeLength).clamp(0.0, 1.0);
    final targetOffset = ratio * _maxScrollExtent;

    HapticFeedback.selectionClick();

    if (widget.controller != null && widget.controller!.hasClients) {
      widget.controller!.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else {
      PrimaryScrollController.maybeOf(context)?.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onTravelerDragStart(DragStartDetails details) {
    _isDragging = true;
    _idleDebounceTimer?.cancel();
    HapticFeedback.lightImpact();
  }

  void _onTravelerDragUpdate(DragUpdateDetails details) {
    if (_maxScrollExtent <= 0) return;

    final h = _viewportDimension;
    const ropeStartY = 24.0;
    final ropeEndY = h - seaHeight + 36.0;
    final travelRange = (ropeEndY - travelerHeight + 14.0) - (ropeStartY - 10.0);

    if (travelRange <= 0) return;

    // Convert pixel delta on rope to scroll delta on content
    final scrollRatio = _maxScrollExtent / travelRange;
    final newOffset = (_scrollOffset + details.delta.dy * scrollRatio).clamp(0.0, _maxScrollExtent);

    // Alternate poses during manual climber dragging
    _accumulatedScrollDelta += details.delta.dy.abs();
    if (_accumulatedScrollDelta >= 18.0) {
      _accumulatedScrollDelta = 0.0;
      setState(() {
        _pose = (_pose == TravelerPose.climbLeft) ? TravelerPose.climbRight : TravelerPose.climbLeft;
      });
      HapticFeedback.selectionClick();
    }

    if (widget.controller != null && widget.controller!.hasClients) {
      widget.controller!.jumpTo(newOffset);
    } else {
      PrimaryScrollController.maybeOf(context)?.jumpTo(newOffset);
    }
  }

  void _onTravelerDragEnd(DragEndDetails details) {
    _isDragging = false;
    _idleDebounceTimer?.cancel();
    _idleDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _pose = TravelerPose.idle;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // Hide scrollbar when content is short or doesn't scroll
    final hasScrollableContent = _maxScrollExtent > 10.0;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height;

          if (_viewportDimension == 0.0) {
            _viewportDimension = viewportHeight;
          }

          const ropeStartY = 24.0;
          final ropeEndY = math.max(ropeStartY + 10.0, viewportHeight - seaHeight + 36.0);

          final scrollPercent = (_maxScrollExtent > 0)
              ? ((_scrollOffset / _maxScrollExtent) * 100).round()
              : 0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ── 1. Scrollable Content Layer ──────────────────────────────
              // Hide the OS default scrollbar and preserve right padding so content never sits under artwork
              Padding(
                padding: EdgeInsets.only(
                  right: hasScrollableContent ? widget.paddingRight : 0.0,
                ),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: widget.child,
                ),
              ),

              // ── 2. Mountain Summit (Top Right) ────────────────────────────
              // Mountain ignores touches so any content beneath can be tapped
              Positioned(
                top: 0,
                right: 0,
                width: artworkWidth,
                height: mountainHeight,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: hasScrollableContent ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 260),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: const Size(artworkWidth, mountainHeight),
                        painter: MountainPainter(isDark: isDark),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 3. Rope Track & Frayed End (Middle) ───────────────────────
              // Rope catches taps to jump and pans to scroll
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: artworkWidth,
                child: AnimatedOpacity(
                  opacity: hasScrollableContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 260),
                  child: Semantics(
                    label: 'Rope scrollbar',
                    value: '$scrollPercent%',
                    slider: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: _onRopeTapDown,
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: Size(artworkWidth, viewportHeight),
                          painter: RopePainter(
                            ropeCenterX: ropeCenterX,
                            startY: ropeStartY,
                            endY: ropeEndY,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 4. Ocean Sea & Moving Waves (Bottom Right) ─────────────────
              // Sea ignores touches
              Positioned(
                bottom: 0,
                right: 0,
                width: artworkWidth,
                height: seaHeight,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: hasScrollableContent ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 260),
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(artworkWidth, seaHeight),
                            painter: SeaPainter(
                              waveProgress: _waveController.value,
                              isDark: isDark,
                              reduceMotion: reduceMotion,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // ── 5. Cartoon Traveler Climber (Thumb) ───────────────────────
              // Draggable climber thumb following the rope
              if (widget.enableClimber)
                Positioned(
                  top: _currentTravelerY,
                  right: artworkWidth - ropeCenterX - (travelerWidth / 2.0),
                  width: travelerWidth,
                  height: travelerHeight,
                  child: AnimatedOpacity(
                    opacity: hasScrollableContent ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 260),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: _onTravelerDragStart,
                      onVerticalDragUpdate: _onTravelerDragUpdate,
                      onVerticalDragEnd: _onTravelerDragEnd,
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: const Size(travelerWidth, travelerHeight),
                          painter: TravelerPainter(
                            pose: reduceMotion ? TravelerPose.idle : _pose,
                            swayAngle: _swayAngle,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
