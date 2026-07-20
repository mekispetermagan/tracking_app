import 'package:flutter/material.dart';

import '../widgets/buttons.dart';

class StartScreen extends StatelessWidget {
  final VoidCallback onAdminLogin;
  final VoidCallback onMentorLogin;

  const StartScreen({
    required this.onAdminLogin,
    required this.onMentorLogin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final logoWidth = (constraints.maxWidth * 0.67)
                                .clamp(160.0, 280.0);

                            return Align(
                              alignment: Alignment.center,
                              child: Image.asset(
                                'assets/images/ag_uganda_logo_light_without_background.png',
                                width: logoWidth,
                                fit: BoxFit.contain,
                                semanticLabel: 'Afterschool Geekery Uganda',
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 48),
                        LargeFilledButton(
                          onPressed: onMentorLogin,
                          text: 'Mentor login',
                        ),
                        const SizedBox(height: 24),
                        LargeFilledButton(
                          onPressed: onAdminLogin,
                          text: 'Admin login',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
