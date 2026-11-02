import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safar/features/search/widgets/cobra_voice_button.dart';

void main() {
  group('CobraVoiceButton Widget Tests', () {
    testWidgets('Renders idle state with accessibility semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CobraVoiceButton(
                state: CobraVoiceState.idle,
                size: 64.0,
              ),
            ),
          ),
        ),
      );

      // Verify the widget is rendered
      expect(find.byType(CobraVoiceButton), findsOneWidget);

      // Verify accessibility label for idle state
      expect(
        find.bySemanticsLabel('Voice search, double tap to start listening'),
        findsOneWidget,
      );
    });

    testWidgets('Renders listening state with caption and updated accessibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CobraVoiceButton(
                state: CobraVoiceState.listening,
                caption: 'Listening...',
                size: 64.0,
              ),
            ),
          ),
        ),
      );

      // Let animation settle
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.byType(CobraVoiceButton), findsOneWidget);
      expect(find.text('Listening...'), findsOneWidget);

      // Verify accessibility label switches to listening mode
      expect(
        find.bySemanticsLabel('Listening. Double tap to stop voice search'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping the button triggers onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CobraVoiceButton(
                state: CobraVoiceState.idle,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CobraVoiceButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapped, isTrue);
    });

    testWidgets('Respects reduce-motion system setting without morphing', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CobraVoiceButton(
                  state: CobraVoiceState.listening,
                  caption: 'Listening...',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Widget renders successfully in reduce motion mode
      expect(find.byType(CobraVoiceButton), findsOneWidget);
      expect(find.text('Listening...'), findsOneWidget);
    });

    testWidgets('Disables snake morph when enableSnakeMorph is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CobraVoiceButton(
                state: CobraVoiceState.listening,
                enableSnakeMorph: false,
                caption: 'Listening...',
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(CobraVoiceButton), findsOneWidget);
      expect(find.text('Listening...'), findsOneWidget);
    });

    testWidgets('Updates smoothly when audioLoudness changes', (tester) async {
      double loudness = 0.2;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CobraVoiceButton(
                    state: CobraVoiceState.listening,
                    audioLoudness: loudness,
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CobraVoiceButton), findsOneWidget);

      loudness = 0.85;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CobraVoiceButton(
                    state: CobraVoiceState.listening,
                    audioLoudness: loudness,
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CobraVoiceButton), findsOneWidget);
    });

    testWidgets('Transitions smoothly from idle to listening and back to idle', (tester) async {
      CobraVoiceState currentState = CobraVoiceState.idle;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    children: [
                      CobraVoiceButton(
                        state: currentState,
                        caption: 'Listening...',
                        onTap: () {
                          setState(() {
                            currentState = currentState == CobraVoiceState.idle
                                ? CobraVoiceState.listening
                                : CobraVoiceState.idle;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Listening...'), findsNothing);

      // Tap to start listening
      await tester.tap(find.byType(CobraVoiceButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text('Listening...'), findsOneWidget);

      // Tap to stop listening and morph back
      await tester.tap(find.byType(CobraVoiceButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text('Listening...'), findsNothing);
    });
  });
}
