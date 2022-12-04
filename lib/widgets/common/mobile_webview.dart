import 'package:colla_chat/platform.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_win_floating/webview.dart';

///支持mobile和windows
class MobileWebView extends StatefulWidget {
  final String initialUrl;
  final void Function(WebViewController)? onWebViewCreated;

  MobileWebView({super.key, required this.initialUrl, this.onWebViewCreated}) {
    if (platformParams.windows) {
      WebView.platform = WindowsWebViewPlugin();
    }
  }

  @override
  State createState() => _MobileWebViewState();
}

class _MobileWebViewState extends State<MobileWebView> {
  late WebViewController controller;

  @override
  void initState() {
    super.initState();
    if (platformParams.android) {
      WebView.platform = AndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      backgroundColor: Colors.black,
      initialUrl: widget.initialUrl,
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: widget.onWebViewCreated,
    );
  }
}
