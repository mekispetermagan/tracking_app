import 'package:flutter/material.dart';

import '../controllers/controllers.dart';
import '../screens/screens.dart';

class MentorArea extends StatefulWidget {
  const MentorArea({required this.onLogout, super.key});

  final Future<void> Function() onLogout;

  @override
  State<MentorArea> createState() => _MentorAreaState();
}

class _MentorAreaState extends State<MentorArea> {
  final _areaController = MentorAreaController();

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _areaController,
      builder: (_, _) => _buildArea(),
    );
  }

  Widget _buildArea() {
    return PopScope(
      canPop: _areaController.screen == MentorScreen.menu,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _areaController.screen != MentorScreen.menu) {
          _areaController.reset();
        }
      },
      child: switch (_areaController.screen) {
        MentorScreen.menu => MentorMenuScreen(
          items: _areaController.menuItems,
          onSelect: _areaController.select,
          onLogout: widget.onLogout,
        ),

        MentorScreen.myProfile => PlaceholderTaskScreen(
          title: 'My profile',
          onHome: _areaController.reset,
          onLogout: widget.onLogout,
        ),

        MentorScreen.sessionLog => PlaceholderTaskScreen(
          title: 'Session log',
          onHome: _areaController.reset,
          onLogout: widget.onLogout,
        ),

        MentorScreen.manageStudents => PlaceholderTaskScreen(
          title: 'Manage students',
          onHome: _areaController.reset,
          onLogout: widget.onLogout,
        ),

        MentorScreen.submitInvoice => PlaceholderTaskScreen(
          title: 'Submit invoice',
          onHome: _areaController.reset,
          onLogout: widget.onLogout,
        ),

        MentorScreen.uploadPhotos => PlaceholderTaskScreen(
          title: 'Upload photos',
          onHome: _areaController.reset,
          onLogout: widget.onLogout,
        ),

        MentorScreen.storyOfTheMonth => PlaceholderTaskScreen(
          title: 'Story of the month',
          onHome: _areaController.reset,
          onLogout: widget.onLogout,
        ),
      },
    );
  }
}
