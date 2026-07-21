import 'package:flutter/widgets.dart';

class HelpScope extends InheritedWidget {
  const HelpScope({required this.text, required super.child, super.key});

  final String text;

  static String? maybeTextOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HelpScope>()?.text;
  }

  @override
  bool updateShouldNotify(HelpScope oldWidget) => text != oldWidget.text;
}
