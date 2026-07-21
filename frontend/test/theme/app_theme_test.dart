import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/app_theme.dart';

void main() {
  test('uses Montserrat for major headings and Nunito elsewhere', () {
    final theme = buildAppTheme(ColorScheme.fromSeed(seedColor: Colors.blue));

    expect(theme.textTheme.displayLarge?.fontFamily, 'Montserrat');
    expect(theme.textTheme.headlineMedium?.fontFamily, 'Montserrat');
    expect(theme.textTheme.titleLarge?.fontFamily, 'Montserrat');
    expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w600);
    expect(theme.textTheme.titleMedium?.fontFamily, 'Nunito');
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Nunito');
    expect(theme.textTheme.labelLarge?.fontFamily, 'Nunito');
  });

  test('mentor and admin themes use different brightness', () {
    final mentorBrightness = buildMentorTheme().brightness;
    final adminBrightness = buildAdminTheme().brightness;

    expect(mentorBrightness, isNot(adminBrightness));
  });

  test('admin theme is visually separate from the mentor brand', () {
    final mentorScheme = buildMentorTheme().colorScheme;
    final adminScheme = buildAdminTheme().colorScheme;

    expect(adminScheme.primary, isNot(mentorScheme.primary));
    expect(adminScheme.secondary, isNot(mentorScheme.secondary));
    expect(adminScheme.surface, isNot(mentorScheme.surface));
  });
}
