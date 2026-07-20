import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/app_bar.dart';

void main() {
  testWidgets('uses icon buttons for Home and Logout roles', (tester) async {
    var homePressed = false;
    var logoutPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppTopBar(
            title: const Text('Area'),
            onHome: () => homePressed = true,
            onLogout: () => logoutPressed = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
    expect(find.byTooltip('Log out'), findsOneWidget);

    await tester.tap(find.byTooltip('Home'));
    await tester.tap(find.byTooltip('Log out'));

    expect(homePressed, isTrue);
    expect(logoutPressed, isTrue);
  });

  testWidgets('uses a back button for the Back role', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppTopBar(title: const Text('Detail'), onBack: () {}),
        ),
      ),
    );

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byIcon(Icons.home), findsNothing);
    expect(find.byIcon(Icons.logout), findsNothing);
  });
}
