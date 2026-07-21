import 'package:flutter/material.dart';

class LargeFilledButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final double fontSize;
  final VoidCallback? onPressed;
  final Icon? icon;
  const LargeFilledButton({
    this.text,
    this.child,
    this.fontSize = 18,
    this.icon,
    this.onPressed,
    super.key,
  }) : assert(text != null || child != null);

  @override
  Widget build(BuildContext context) {
    final label = Padding(
      padding: const EdgeInsets.all(6),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        child: child ?? Text(text!),
      ),
    );

    return icon == null
        ? FilledButton(onPressed: onPressed, child: label)
        : FilledButton.icon(onPressed: onPressed, icon: icon, label: label);
  }
}

class AppBarIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  const AppBarIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 30,
      color: Theme.of(context).colorScheme.primary,
      tooltip: tooltip,
    );
  }
}
