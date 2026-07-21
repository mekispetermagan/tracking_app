import 'package:flutter/material.dart';

const mentorSeedColor = Color.fromRGBO(0, 255, 223, 1);
const adminSeedColor = Color.fromRGBO(69, 90, 100, 1);

ColorScheme buildMentorColorScheme() {
  return ColorScheme.fromSeed(
    seedColor: mentorSeedColor,
    brightness: Brightness.dark,
  );
}

ColorScheme buildAdminColorScheme() {
  return ColorScheme.fromSeed(
    seedColor: adminSeedColor,
    brightness: Brightness.light,
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
