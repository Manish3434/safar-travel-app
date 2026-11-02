import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safar/core/l10n/generated/app_localizations.dart';
import 'package:safar/features/home/home_screen.dart';

Widget createHomeScreenTestWrapper() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: const ProviderScope(
      child: HomeScreen(),
    ),
  );
}

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('Renders app title, search hint, and category chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createHomeScreenTestWrapper());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify header texts
      expect(find.textContaining('Safar'), findsWidgets);
      expect(find.text('Where do you want to go?'), findsOneWidget);
      expect(find.text('Search cities, waterfalls, villages...'), findsOneWidget);

      // Verify category chips
      expect(find.text('Beaches'), findsOneWidget);
      expect(find.text('Forests'), findsOneWidget);
      expect(find.text('Bird Sanctuaries'), findsOneWidget);
      expect(find.text('Wildlife & Sanctuaries'), findsOneWidget);
      expect(find.text('Heritage'), findsOneWidget);
      expect(find.text('Museums'), findsOneWidget);

      // Verify Popular Destinations section title
      expect(find.text('Popular Destinations'), findsOneWidget);
    });
  });
}
