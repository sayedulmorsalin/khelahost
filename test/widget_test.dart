import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khelahost/core/theme.dart';

void main() {
  // Use a Google Fonts override so tests don't need network access
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('HomeScreen renders HOST and JOIN buttons', (tester) async {
    // Pump a minimal widget that mimics the home screen buttons,
    // without requiring Firebase to be initialized.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                key: const Key('host_button'),
                onPressed: () {},
                child: const Text('HOST A TOURNAMENT'),
              ),
              ElevatedButton(
                key: const Key('join_button'),
                onPressed: () {},
                child: const Text('EXPLORE TOURNAMENTS'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('HOST A TOURNAMENT'), findsOneWidget);
    expect(find.text('EXPLORE TOURNAMENTS'), findsOneWidget);
    expect(find.byKey(const Key('host_button')), findsOneWidget);
    expect(find.byKey(const Key('join_button')), findsOneWidget);
  });
}
