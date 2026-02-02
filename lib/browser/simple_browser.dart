import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hibiscus/browser/browser_controller.dart';
import 'package:hibiscus/browser/browser_state.dart';

/// A minimal browser page that only captures the current User-Agent.
class SimpleBrowserPage extends StatefulWidget {
  /// URL used to trigger a navigation and expose the UA.
  final String initialUrl;

  const SimpleBrowserPage({ 
    super.key,
    this.initialUrl = 'https://www.bing.com',
  });

  @override
  State<SimpleBrowserPage> createState() => _SimpleBrowserPageState();
}

class _SimpleBrowserPageState extends State<SimpleBrowserPage> {
  final _progress = ValueNotifier<double>(0);
  bool _captured = false;

  Future<void> _maybeCapture(InAppWebViewController controller) async {
    if (_captured) return;
    final ua = await _resolveUserAgent(controller);
    if (ua == null || ua.isEmpty) return;
    _captured = true;
    await browserState.saveUserAgent(ua);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<String?> _resolveUserAgent(InAppWebViewController controller) async {
    try {
      final settings = await controller.getSettings();
      final candidate = settings?.userAgent;
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    } catch (_) {}

    try {
      final result = await controller.evaluateJavascript(
        source: 'navigator.userAgent',
      );
      if (result is String && result.isNotEmpty) {
        return result;
      }
    } catch (_) {}

    return null;
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('获取 User-Agent')),
      body: Column(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _progress,
            builder: (context, value, _) {
              if (value >= 1) return const SizedBox.shrink();
              return LinearProgressIndicator(value: value);
            },
          ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
              initialSettings: BrowserSettings.webViewSettings,
              onWebViewCreated: (controller) {
                _maybeCapture(controller);
              },
              onLoadStop: (controller, _) {
                _maybeCapture(controller);
              },
              onProgressChanged: (controller, progress) {
                _progress.value = progress / 100.0;
              },
            ),
          ),
        ],
      ),
    );
  }
}
