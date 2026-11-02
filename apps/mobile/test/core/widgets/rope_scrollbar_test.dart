import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safar/core/widgets/rope_scrollbar/mountain_painter.dart';
import 'package:safar/core/widgets/rope_scrollbar/rope_painter.dart';
import 'package:safar/core/widgets/rope_scrollbar/rope_scrollbar.dart';
import 'package:safar/core/widgets/rope_scrollbar/sea_painter.dart';
import 'package:safar/core/widgets/rope_scrollbar/traveler_painter.dart';

void main() {
  Widget buildTestApp({
    required Widget child,
    ScrollController? controller,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: RopeScrollbar(
            controller: controller,
            child: child,
          ),
        ),
      ),
    );
  }

  group('RopeScrollbar Widget Tests', () {
    testWidgets('1. Renders mountain summit, rope track, sea waves, and traveler on long content',
        (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(
        buildTestApp(
          controller: controller,
          child: ListView.builder(
            controller: controller,
            itemCount: 50,
            itemBuilder: (_, i) => SizedBox(
              height: 60,
              child: Text('Destination Item $i'),
            ),
          ),
        ),
      );

      // Pump frames to initialize LayoutBuilder and listeners
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify custom painters are present
      expect(find.byType(RopeScrollbar), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is MountainPainter), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is RopePainter), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is SeaPainter), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is TravelerPainter), findsOneWidget);

      controller.dispose();
    });

    testWidgets('2. Hides scrollbar artwork when content is short and does not scroll', (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(
        buildTestApp(
          controller: controller,
          child: ListView.builder(
            controller: controller,
            itemCount: 2,
            itemBuilder: (_, i) => SizedBox(
              height: 40,
              child: Text('Short Item $i'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the AnimatedOpacity wrapping the mountain
      final mountainOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byWidgetPredicate((w) => w is CustomPaint && w.painter is MountainPainter),
          matching: find.byType(AnimatedOpacity),
        ),
      );

      // Verify opacity is 0.0 because maxScrollExtent <= 10.0
      expect(mountainOpacity.opacity, 0.0);

      controller.dispose();
    });

    testWidgets('3. Scrolling moves the traveler down the rope smoothly', (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(
        buildTestApp(
          controller: controller,
          child: ListView.builder(
            controller: controller,
            itemCount: 50,
            itemBuilder: (_, i) => SizedBox(
              height: 60,
              child: Text('Item $i'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initial traveler position
      final initialTravelerFinder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is TravelerPainter);
      final initialTop = tester.getTopLeft(initialTravelerFinder).dy;

      // Scroll down list
      controller.jumpTo(800.0);
      await tester.pump();
      // Allow physics ticker to lerp down
      await tester.pump(const Duration(milliseconds: 300));

      final scrolledTop = tester.getTopLeft(initialTravelerFinder).dy;
      expect(scrolledTop, greaterThan(initialTop));

      controller.dispose();
    });

    testWidgets('4. Dragging the traveler climber scrolls the list content', (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(
        buildTestApp(
          controller: controller,
          child: ListView.builder(
            controller: controller,
            itemCount: 60,
            itemBuilder: (_, i) => SizedBox(
              height: 60,
              child: Text('Drag Target $i'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.offset, 0.0);

      final travelerFinder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is TravelerPainter);

      // Drag downward
      await tester.drag(travelerFinder, const Offset(0, 150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.offset, greaterThan(50.0));

      controller.dispose();
    });

    testWidgets('5. Tapping the rope track jumps to corresponding scroll position', (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(
        buildTestApp(
          controller: controller,
          child: ListView.builder(
            controller: controller,
            itemCount: 80,
            itemBuilder: (_, i) => SizedBox(
              height: 60,
              child: Text('Tap Target $i'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.offset, 0.0);

      // Tap midway on the rope
      final ropeFinder = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is RopePainter);
      await tester.tapAt(tester.getCenter(ropeFinder));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(controller.offset, greaterThan(100.0));

      controller.dispose();
    });

    testWidgets('6. Respects reduce motion: pauses sway, wave motion, and pose switching', (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(
        buildTestApp(
          controller: controller,
          disableAnimations: true, // Reduce motion enabled
          child: ListView.builder(
            controller: controller,
            itemCount: 50,
            itemBuilder: (_, i) => SizedBox(
              height: 60,
              child: Text('Reduced Motion Item $i'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final traveler = tester.widget<CustomPaint>(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is TravelerPainter),
      );
      final painter = traveler.painter as TravelerPainter;

      // In reduce motion, pose stays idle and sway angle is 0.0
      expect(painter.pose, TravelerPose.idle);
      expect(painter.swayAngle, 0.0);

      controller.dispose();
    });

    testWidgets('7. Mountain and Sea ignore touches so list content remains clickable', (tester) async {
      final controller = ScrollController();
      bool cardTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          controller: controller,
          child: ListView(
            controller: controller,
            children: [
              GestureDetector(
                onTap: () => cardTapped = true,
                child: Container(
                  height: 100,
                  color: Colors.blue,
                  child: const Text('Clickable Card'),
                ),
              ),
              for (int i = 0; i < 30; i++)
                SizedBox(height: 60, child: Text('Filler $i')),
            ],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Clickable Card'));
      await tester.pump();

      expect(cardTapped, isTrue);

      controller.dispose();
    });

    testWidgets('8. Accessibility semantics expose scroll percentage', (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(
        buildTestApp(
          controller: controller,
          child: ListView.builder(
            controller: controller,
            itemCount: 50,
            itemBuilder: (_, i) => SizedBox(height: 60, child: Text('Item $i')),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Rope scrollbar' && w.properties.slider == true,
        ),
        findsOneWidget,
      );

      controller.dispose();
    });
  });
}
