import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agu_frontend/screens/admin_login_screen.dart';
import 'package:agu_frontend/screens/mentor_login_screen.dart';
import 'package:agu_frontend/screens/start_screen.dart';

Widget _app(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('start screen offers both access paths', (tester) async {
    var mentorLogins = 0;
    var adminLogins = 0;
    await tester.pumpWidget(
      _app(
        StartScreen(
          onMentorLogin: () => mentorLogins++,
          onAdminLogin: () => adminLogins++,
        ),
      ),
    );

    expect(find.bySemanticsLabel('Afterschool Geekery Uganda'), findsOneWidget);
    await tester.tap(find.text('Mentor login'));
    await tester.tap(find.text('Admin login'));
    expect((mentorLogins, adminLogins), (1, 1));
  });

  testWidgets('admin login forwards edits and actions and clears messages', (
    tester,
  ) async {
    final phones = <String>[];
    final passwords = <String>[];
    var submits = 0;
    var cancels = 0;
    var clears = 0;
    var clearPhones = 0;

    await tester.pumpWidget(
      _app(
        AdminLoginScreen(
          phone: '0700000000',
          password: '',
          phoneFieldVersion: 0,
          phoneIsValid: true,
          canSubmit: true,
          isSubmitting: false,
          message: 'Try again',
          clearMessage: () => clears++,
          onPhoneChanged: phones.add,
          onPasswordChanged: passwords.add,
          onClearPhone: () => clearPhones++,
          onSubmit: () => submits++,
          onCancel: () => cancels++,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Try again'), findsOneWidget);
    expect(clears, 1);
    await tester.enterText(find.byType(TextFormField), '0712345678');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.byIcon(Icons.clear));
    await tester.tap(find.text('Login'));
    await tester.tap(find.byType(BackButton));

    expect(phones.last, '0712345678');
    expect(passwords.last, 'secret');
    expect((clearPhones, submits, cancels), (1, 1, 1));
  });

  testWidgets(
    'mentor login disables PIN and submit until credentials are valid',
    (tester) async {
      var submits = 0;
      await tester.pumpWidget(
        _app(
          MentorLoginScreen(
            phone: '',
            pin: '',
            phoneIsValid: false,
            phoneFieldVersion: 0,
            canSubmit: false,
            onPhoneChanged: (_) {},
            onPinChanged: (_) {},
            onClearPhone: () {},
            onSubmit: () => submits++,
            onCancel: () {},
            isSubmitting: false,
            message: null,
            clearMessage: () {},
          ),
        ),
      );

      final login = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Login'),
      );
      expect(login.onPressed, isNull);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(submits, 0);
    },
  );
}
