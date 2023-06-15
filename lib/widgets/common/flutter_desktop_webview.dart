import 'package:flutter/material.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';

/// FlutterDesktopWebView，打开一个外部的浏览器窗口，可以用来观看网页，音频，视频文件，office文件
class FlutterDesktopWebView extends StatefulWidget {
  final String? initialUrl;
  final String? html;
  final String? initialFilename;
  Webview? webview;

  FlutterDesktopWebView({
    super.key,
    this.initialUrl,
    this.html,
    this.initialFilename,
  }) {
    WebviewWindow.create().then((webview) {
      this.webview = webview;
    });
  }

  @override
  State createState() => _FlutterDesktopWebViewState();
}

class _FlutterDesktopWebViewState extends State<FlutterDesktopWebView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
