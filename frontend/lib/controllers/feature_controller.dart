import 'package:flutter/foundation.dart';

abstract class FeatureController extends ChangeNotifier {
  int _requestRevision = 0;
  bool _isDisposed = false;

  @protected
  int beginRequest() => ++_requestRevision;

  @protected
  bool requestIsCurrent(int revision) {
    return !_isDisposed && revision == _requestRevision;
  }

  @protected
  void invalidateRequests() {
    _requestRevision++;
  }

  @override
  void dispose() {
    _isDisposed = true;
    invalidateRequests();
    super.dispose();
  }
}
