import 'package:flutter/foundation.dart';

class AreaMenuItem<S extends Enum> {
  const AreaMenuItem({required this.screen, required this.label});

  final S screen;
  final String label;
}

abstract class AreaController<S extends Enum> extends ChangeNotifier {
  AreaController({required S menuScreen})
    : _menuScreen = menuScreen,
      _screen = menuScreen;

  final S _menuScreen;
  S _screen;

  S get screen => _screen;
  List<AreaMenuItem<S>> get menuItems;

  void selectMenuItem(S screen) {
    if (!menuItems.any((item) => item.screen == screen)) {
      throw ArgumentError.value(screen, 'screen', 'is not a menu screen');
    }

    final screenChanged = updateScreen(screen);
    final transientStateChanged = clearTransientState();
    publishIf(screenChanged || transientStateChanged);
  }

  @protected
  bool updateScreen(S screen) {
    if (_screen == screen) return false;
    _screen = screen;
    return true;
  }

  @protected
  bool clearTransientState() => false;

  @protected
  void publishIf(bool changed) {
    if (changed) notifyListeners();
  }

  void reset() {
    final screenChanged = updateScreen(_menuScreen);
    final transientStateChanged = clearTransientState();
    publishIf(screenChanged || transientStateChanged);
  }
}
