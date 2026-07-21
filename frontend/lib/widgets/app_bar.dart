import 'package:flutter/material.dart';

import '../help/help_scope.dart';
import 'buttons.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final VoidCallback? onHome;
  final VoidCallback? onBack;
  final bool showBack;
  final VoidCallback? onLogout;
  final String? helpText;
  final List<Widget> actions;

  const AppTopBar({
    required this.title,
    this.onHome,
    this.onBack,
    this.showBack = false,
    this.onLogout,
    this.helpText,
    this.actions = const [],
    super.key,
  }) : assert(
         onHome == null || (!showBack && onBack == null),
         'An app bar cannot show both Home and Back as its leading action.',
       );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final effectiveHelpText = helpText ?? HelpScope.maybeTextOf(context);

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset(
            'assets/images/ag_uganda_logo_no_text_small.png',
            height: 28,
          ),
          const SizedBox(width: 12),
          Expanded(child: title),
        ],
      ),
      leading: onHome != null
          ? AppBarIconButton(
              onPressed: onHome!,
              icon: Icons.home,
              tooltip: 'Home',
            )
          : showBack || onBack != null
          ? BackButton(onPressed: onBack)
          : null,
      actions: [
        ...actions,
        if (effectiveHelpText != null)
          AppBarIconButton(
            onPressed: () => _showHelp(context, effectiveHelpText),
            icon: Icons.help_outline,
            tooltip: 'Help',
          ),
        if (onLogout != null)
          AppBarIconButton(
            onPressed: onLogout!,
            icon: Icons.logout,
            tooltip: 'Log out',
          ),
      ],
    );
  }

  Future<void> _showHelp(BuildContext context, String text) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
