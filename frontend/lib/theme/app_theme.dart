import 'package:flutter/material.dart';

const mentorGreen = Color(0xFF40C000);

ColorScheme buildMentorColorScheme() {
  return ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.light,
  );
}

ColorScheme buildAdminColorScheme() {
  const adminSlate = Color(0xFF455A64);

  return ColorScheme.fromSeed(
    seedColor: adminSlate,
    brightness: Brightness.dark,
  );
}

ThemeData buildMentorTheme() => buildAppTheme(buildMentorColorScheme());

ThemeData buildAdminTheme() => buildAppTheme(buildAdminColorScheme());

ThemeData buildAppTheme(ColorScheme colorScheme) {
  final baseTheme = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    fontFamily: 'Nunito',
  );
  final textTheme = baseTheme.textTheme;

  TextStyle? headingStyle(TextStyle? style) {
    return style?.copyWith(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.w600,
    );
  }

  return baseTheme.copyWith(
    textTheme: textTheme.copyWith(
      displayLarge: headingStyle(textTheme.displayLarge),
      displayMedium: headingStyle(textTheme.displayMedium),
      displaySmall: headingStyle(textTheme.displaySmall),
      headlineLarge: headingStyle(textTheme.headlineLarge),
      headlineMedium: headingStyle(textTheme.headlineMedium),
      headlineSmall: headingStyle(textTheme.headlineSmall),
      titleLarge: headingStyle(textTheme.titleLarge),
    ),
  );
}
