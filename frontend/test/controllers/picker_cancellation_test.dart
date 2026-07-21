import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:agu_frontend/controllers/controllers.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('story picker error cannot restore state after reset', () async {
    final picker = _DelayedImagePicker();
    final controller = MentorStoryController(imagePicker: picker);

    final selection = controller.selectPhoto();
    controller.reset();
    picker.single.completeError(StateError('picker failed'));
    await selection;

    expect(controller.isSelectingPhoto, isFalse);
    expect(controller.selectedPhoto, isNull);
    expect(controller.message, isNull);
  });

  test('session picker error cannot restore state after reset', () async {
    final picker = _DelayedImagePicker();
    final controller = SessionPhotoController(imagePicker: picker);

    final selection = controller.selectPhotos();
    controller.reset();
    picker.multiple.completeError(StateError('picker failed'));
    await selection;

    expect(controller.isSelecting, isFalse);
    expect(controller.selectedPhotos, isEmpty);
    expect(controller.message, isNull);
  });
}

class _DelayedImagePicker extends ImagePicker {
  final single = Completer<XFile?>();
  final multiple = Completer<List<XFile>>();

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) {
    return single.future;
  }

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) {
    return multiple.future;
  }
}
