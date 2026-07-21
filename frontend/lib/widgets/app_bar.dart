import 'package:flutter/material.dart';

import 'buttons.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final VoidCallback? onHome;
  final VoidCallback? onBack;
  final bool showBack;
  final VoidCallback? onLogout;
  final List<Widget> actions;

  const AppTopBar({
    required this.title,
    this.onHome,
    this.onBack,
    this.showBack = false,
    this.onLogout,
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
        if (onLogout != null)
          AppBarIconButton(
            onPressed: onLogout!,
            icon: Icons.logout,
            tooltip: 'Log out',
          ),
      ],
    );
  }
}
