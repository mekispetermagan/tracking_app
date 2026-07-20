import 'package:flutter/material.dart';

import 'buttons.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final VoidCallback? onHome;
  final VoidCallback? onBack;
  final VoidCallback? onLogout;
  final List<Widget> actions;

  const AppTopBar({
    required this.title,
    this.onHome,
    this.onBack,
    this.onLogout,
    this.actions = const [],
    super.key,
  }) : assert(
         onHome == null || onBack == null,
         'An app bar cannot show both Home and Back as its leading action.',
       );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      leading: onHome != null
          ? AppBarIconButton(
              onPressed: onHome!,
              icon: Icons.home,
              tooltip: 'Home',
            )
          : onBack != null
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
