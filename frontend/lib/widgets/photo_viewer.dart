import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PhotoViewerItem {
  final String imageUrl;
  final String caption;

  const PhotoViewerItem({required this.imageUrl, required this.caption});
}

Future<void> showPhotoViewer({
  required BuildContext context,
  required List<PhotoViewerItem> items,
  int initialIndex = 0,
  bool showCounter = true,
  double controlIconSize = 36,
  TextStyle captionStyle = const TextStyle(color: Colors.white, fontSize: 16),
}) {
  assert(items.isNotEmpty);
  assert(initialIndex >= 0 && initialIndex < items.length);

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (context) {
      return Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: SizedBox.expand(
          child: _PhotoViewer(
            items: items,
            initialIndex: initialIndex,
            showCounter: showCounter,
            controlIconSize: controlIconSize,
            captionStyle: captionStyle,
          ),
        ),
      );
    },
  );
}

class _PhotoViewer extends StatefulWidget {
  final List<PhotoViewerItem> items;
  final int initialIndex;
  final bool showCounter;
  final double controlIconSize;
  final TextStyle captionStyle;

  const _PhotoViewer({
    required this.items,
    required this.initialIndex,
    required this.showCounter,
    required this.controlIconSize,
    required this.captionStyle,
  });

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pageController;
  late final FocusNode _focusNode;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.items[_currentIndex];

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Material(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: PhotoViewGallery.builder(
                itemCount: widget.items.length,
                pageController: _pageController,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                scrollPhysics: const ClampingScrollPhysics(),
                gaplessPlayback: true,
                wantKeepAlive: true,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                loadingBuilder: (context, loadingProgress) {
                  final expectedBytes = loadingProgress?.expectedTotalBytes;
                  final progress =
                      loadingProgress == null || expectedBytes == null
                      ? null
                      : loadingProgress.cumulativeBytesLoaded / expectedBytes;

                  return Center(
                    child: CircularProgressIndicator(value: progress),
                  );
                },
                builder: (context, index) {
                  final item = widget.items[index];

                  return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(item.imageUrl),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Photo unavailable',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (widget.showCounter)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.items.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: _ViewerButton(
                  icon: Icons.close,
                  iconSize: widget.controlIconSize,
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentItem.caption,
                      textAlign: TextAlign.center,
                      style: widget.captionStyle,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.items.length > 1) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerButton(
                    icon: Icons.chevron_left,
                    iconSize: widget.controlIconSize,
                    tooltip: 'Previous photo',
                    onPressed: _currentIndex > 0 ? _showPrevious : null,
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerButton(
                    icon: Icons.chevron_right,
                    iconSize: widget.controlIconSize,
                    tooltip: 'Next photo',
                    onPressed: _currentIndex < widget.items.length - 1
                        ? _showNext
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _showPrevious();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _showNext();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _showPrevious() {
    if (_currentIndex <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _showNext() {
    if (_currentIndex >= widget.items.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}

class _ViewerButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ViewerButton({
    required this.icon,
    required this.iconSize,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: iconSize,
        color: Colors.white,
        disabledColor: Colors.white24,
        tooltip: tooltip,
      ),
    );
  }
}
