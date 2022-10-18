import 'package:colla_chat/platform.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MobileWebView extends StatefulWidget {
  final String initialUrl;

  const MobileWebView({super.key, required this.initialUrl});

  @override
  State createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<MobileWebView> {
  @override
  void initState() {
    super.initState();
    // Enable virtual display.
    if (platformParams.android) {
      WebView.platform = AndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: widget.initialUrl,
    );
  }
}
