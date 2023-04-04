import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// FlutterWebView，打开一个内部的浏览器窗口，可以用来观看网页，音频，视频文件，office文件
class FlutterWebView extends StatefulWidget {
  final String? initialUrl;
  final String? html;
  final String? initialFilename;
  final void Function(WebViewController controller)? onWebViewCreated;

  const FlutterWebView(
      {super.key,
      this.initialUrl,
      this.html,
      this.initialFilename,
      this.onWebViewCreated});

  @override
  State createState() => _FlutterWebViewState();
}

class _FlutterWebViewState extends State<FlutterWebView> {
  WebViewController? controller;

  @override
  void initState() {
    super.initState();
    createController();
  }

  void createController() {
    controller = WebViewController();
    controller!.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller!.setBackgroundColor(Colors.white);
    controller!.setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (request) {
        logger.i("request navigate ${request.url}");
        return NavigationDecision.navigate;
      },
      onPageStarted: (url) => logger.i("onPageStarted: $url"),
      onPageFinished: (url) => logger.i("onPageFinished: $url"),
      onWebResourceError: (error) =>
          logger.i("onWebResourceError: ${error.description}"),
    ));
    if (widget.initialUrl != null) {
      controller!.loadRequest(Uri.parse(widget.initialUrl!));
    }
    if (widget.initialFilename != null) {
      controller!.loadFile(widget.initialFilename!);
    }
    if (widget.html != null) {
      controller!.loadHtmlString(widget.html!);
    }
    if (widget.onWebViewCreated != null) {
      widget.onWebViewCreated!(controller!);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget webView;
    if (platformParams.windows || platformParams.mobile || platformParams.web) {
      webView = WebViewWidget(
        controller: controller!,
      );
    } else {
      webView = Container();
    }

    return webView;
  }
}
