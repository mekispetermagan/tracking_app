import 'package:flutter_test/flutter_test.dart';
import 'package:agu_frontend/controllers/controllers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'mentor login normalizes phone and PIN and clears invalid credentials',
    () {
      final controller = MentorLoginController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setPhone('07a00 123-4567');
      controller.setPin('12a34567');

      expect(controller.phone, '0700123456');
      expect(controller.pin, '123456');
      expect(controller.canSubmit, isTrue);

      controller.setPhone('0700');
      expect(controller.pin, isEmpty);
      expect(controller.canSubmit, isFalse);
      expect(notifications, 3);
    },
  );

  test(
    'admin login persists, restores, and clears the remembered phone',
    () async {
      final first = AdminLoginController();
      first.setPhone('0700123456');
      first.setPassword('secret');
      await first.saveLastPhone();

      final restored = AdminLoginController();
      await restored.loadLastPhone();
      expect(restored.phone, '0700123456');
      expect(restored.password, isEmpty);

      restored.setPassword('another');
      await restored.clearPhone();
      expect(restored.phone, isEmpty);
      expect(restored.password, isEmpty);

      final afterClear = AdminLoginController();
      await afterClear.loadLastPhone();
      expect(afterClear.phone, isEmpty);
    },
  );

  test('mentor setup PIN normalizes values and requires a valid match', () {
    final controller = MentorSetupPinController();

    controller.setPin('12a34567');
    controller.setConfirmPin('12345');
    expect(controller.pin, '123456');
    expect(controller.canSubmit, isFalse);

    controller.setConfirmPin('123456');
    expect(controller.pinsMatch, isTrue);
    expect(controller.canSubmit, isTrue);

    controller.reset();
    expect(controller.pin, isEmpty);
    expect(controller.confirmPin, isEmpty);
  });

  test('admin setup password requires two valid exact values', () {
    final controller = AdminSetupPasswordController();

    controller.setPassword('secret');
    controller.setConfirmPassword('SECRET');
    expect(controller.passwordsMatch, isFalse);
    expect(controller.canSubmit, isFalse);

    controller.setConfirmPassword('secret');
    expect(controller.canSubmit, isTrue);
  });
}
