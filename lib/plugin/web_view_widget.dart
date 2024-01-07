import 'package:colla_chat/widgets/webview/platform_webview.dart';
import 'package:flutter/material.dart';

class WebViewWidget extends StatefulWidget {
  final String url;

  const WebViewWidget({super.key, required this.url});

  @override
  State createState() => _WebViewWidgetState();
}

class _WebViewWidgetState extends State<WebViewWidget> {
  PlatformWebViewController? platformWebViewController;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformWebView(
        initialUrl: widget.url,
        onWebViewCreated: (PlatformWebViewController controller) {
          platformWebViewController = controller;
        });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
