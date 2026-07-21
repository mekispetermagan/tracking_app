import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/app_bar.dart';

void main() {
  testWidgets('uses branded title and icon buttons for Home and Logout roles', (
    tester,
  ) async {
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
    final logo = tester.widget<Image>(find.byType(Image));
    expect(
      (logo.image as AssetImage).assetName,
      'assets/images/ag_uganda_logo_no_text_small.png',
    );
    expect(find.text('Area'), findsOneWidget);

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

  testWidgets('can show a disabled back button explicitly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AppTopBar(title: Text('Saving'), showBack: true),
        ),
      ),
    );

    expect(
      tester.widget<BackButton>(find.byType(BackButton)).onPressed,
      isNull,
    );
  });
}
