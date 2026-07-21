import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/screens.dart';

void main() {
  testWidgets('labels unfinished features as coming soon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComingSoonScreen(
          title: 'Submit invoice',
          onHome: () {},
          onLogout: () {},
        ),
      ),
    );

    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.text('Submit invoice is not available yet.'), findsOneWidget);
    expect(find.textContaining('placeholder'), findsNothing);
    expect(find.byIcon(Icons.construction_outlined), findsOneWidget);
  });
}
