import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/models.dart';

class CurriculumScreen extends StatelessWidget {
  final List<CurriculumCategory> categories;
  final CurriculumChapter? selectedChapter;
  final String? selectedChapterUrl;

  final bool isLoading;
  final String? message;

  final VoidCallback clearMessage;
  final Future<void> Function() onReload;
  final ValueChanged<CurriculumChapter> onSelectChapter;
  final VoidCallback onCloseChapter;
  final VoidCallback onBack;

  const CurriculumScreen({
    required this.categories,
    required this.selectedChapter,
    required this.selectedChapterUrl,
    required this.isLoading,
    required this.message,
    required this.clearMessage,
    required this.onReload,
    required this.onSelectChapter,
    required this.onCloseChapter,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message!)));

        clearMessage();
      });
    }

    final chapter = selectedChapter;

    return Scaffold(
      appBar: AppBar(
        title: Text(chapter?.englishTitle ?? 'Curriculum'),
        leading: BackButton(
          onPressed: chapter == null ? onBack : onCloseChapter,
        ),
        actions: [
          if (chapter == null)
            IconButton(
              onPressed: isLoading
                  ? null
                  : () {
                      onReload();
                    },
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload curriculum',
            ),
        ],
      ),
      body: SafeArea(
        child: chapter == null ? _buildMenu(context) : _buildChapter(chapter),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Curriculum unavailable.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  onReload();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (_, _) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final category = categories[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: ExpansionTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(
              category.englishTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              for (final chapter in category.chapters)
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 40, right: 16),
                  leading: const Icon(Icons.article_outlined),
                  title: Text(chapter.englishTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    onSelectChapter(chapter);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChapter(CurriculumChapter chapter) {
    final url = selectedChapterUrl;

    if (url == null) {
      return const Center(child: Text('Invalid chapter URL.'));
    }

    return _CurriculumChapterView(key: ValueKey(url), url: url);
  }
}

class _CurriculumChapterView extends StatefulWidget {
  final String url;

  const _CurriculumChapterView({required this.url, super.key});

  @override
  State<_CurriculumChapterView> createState() {
    return _CurriculumChapterViewState();
  }
}

class _CurriculumChapterViewState extends State<_CurriculumChapterView> {
  late final WebViewController _webViewController;

  int _progress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) {
              return;
            }

            setState(() {
              _progress = progress;
            });
          },
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }

            setState(() {
              _errorMessage = null;
              _progress = 0;
            });
          },
          onPageFinished: (_) {
            if (!mounted) {
              return;
            }

            setState(() {
              _progress = 100;
            });

            _prepareExternalLinks();
          },
          onNavigationRequest: _handleNavigation,
          onWebResourceError: (error) {
            if (error.isForMainFrame != true || !mounted) {
              return;
            }

            setState(() {
              _errorMessage = 'Could not load this chapter.';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<NavigationDecision> _handleNavigation(
    NavigationRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);

    if (uri == null) {
      return NavigationDecision.prevent;
    }

    if (uri.scheme == 'about' ||
        uri.host == 'curriculum.afterschool-geekery.org') {
      return NavigationDecision.navigate;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open the external link.')),
        );
    }

    return NavigationDecision.prevent;
  }

  Future<void> _prepareExternalLinks() async {
    try {
      await _webViewController.runJavaScript('''
        (() => {
          const prepareLinks = () => {
            document
              .querySelectorAll('a[target="_blank"]')
              .forEach((link) => {
                link.removeAttribute('target');
              });
          };

          prepareLinks();

          new MutationObserver(prepareLinks).observe(
            document.documentElement,
            {
              childList: true,
              subtree: true
            }
          );
        })();
        ''');
    } catch (_) {
      // The navigation delegate still handles
      // ordinary external links.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_progress < 100)
          Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(
              value: _progress == 0 ? null : _progress / 100,
            ),
          ),
        if (_errorMessage != null)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 48),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });

                          _webViewController.reload();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
