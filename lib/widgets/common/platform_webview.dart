import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:webview_flutter/webview_flutter.dart' as webview;
import 'package:webview_win_floating/webview.dart';

class PlatformWebViewController {
  inapp.InAppWebViewController? inAppWebViewController;
  webview.WebViewController? webViewController;

  PlatformWebViewController(
      {this.webViewController, this.inAppWebViewController});

  load(String filename) async {
    if (StringUtil.isEmpty(filename)) {
      String html = """<html><body></body></html>""";
      if (webViewController != null) {
        await webViewController!.loadHtmlString(html);
      } else if (inAppWebViewController != null) {
        await inAppWebViewController!.loadData(data: html);
      }
      return;
    }
    if (filename.startsWith('assets')) {
      if (webViewController != null) {
        await webViewController!.loadFlutterAsset(filename);
      } else if (inAppWebViewController != null) {
        await inAppWebViewController!.loadFile(assetFilePath: filename);
      }
    } else if (filename.startsWith('http')) {
      if (webViewController != null) {
        await webViewController!.loadUrl(filename);
      } else if (inAppWebViewController != null) {
        inapp.URLRequest urlRequest =
            inapp.URLRequest(url: inapp.WebUri(filename));
        await inAppWebViewController!.loadUrl(urlRequest: urlRequest);
      }
    } else {
      if (webViewController != null) {
        await webViewController!.loadFile(filename);
      } else if (inAppWebViewController != null) {
        inapp.URLRequest urlRequest =
            inapp.URLRequest(url: inapp.WebUri('file:$filename'));
        await inAppWebViewController!.loadUrl(urlRequest: urlRequest);
      }
    }
  }
}

/// 平台Webview，打开一个内部的浏览器窗口，可以用来观看网页，音频，视频文件，office文件
class PlatformWebView extends StatefulWidget {
  final String initialUrl;
  final void Function(PlatformWebViewController webViewController)?
      onWebViewCreated;

  PlatformWebView(
      {super.key, required this.initialUrl, this.onWebViewCreated}) {
    if (platformParams.windows) {
      webview.WebView.platform = WindowsWebViewPlugin();
    }
  }

  @override
  State createState() => _PlatformWebViewState();
}

class _PlatformWebViewState extends State<PlatformWebView> {
  inapp.InAppWebViewSettings settings = inapp.InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  PlatformWebViewController webViewController = PlatformWebViewController();

  @override
  void initState() {
    super.initState();
    if (platformParams.android) {
      webview.WebView.platform = webview.AndroidWebView();
    }
  }

  _onWebViewCreated(dynamic controller) {
    if (controller is webview.WebViewController) {
      webViewController.webViewController = controller;
      webViewController.inAppWebViewController = null;
    } else if (controller is inapp.InAppWebViewController) {
      webViewController.webViewController = null;
      webViewController.inAppWebViewController = controller;
    } else {
      webViewController.webViewController = null;
      webViewController.inAppWebViewController = null;
    }
    if (widget.onWebViewCreated != null) {
      widget.onWebViewCreated!(webViewController);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget webviewWidget;
    if (platformParams.windows || platformParams.mobile || platformParams.web) {
      webviewWidget = webview.WebView(
        backgroundColor: Colors.black,
        initialUrl: widget.initialUrl,
        javascriptMode: webview.JavascriptMode.unrestricted,
        onWebViewCreated: _onWebViewCreated,
      );
    } else {
      webviewWidget = inapp.InAppWebView(
        initialUrlRequest:
            inapp.URLRequest(url: inapp.WebUri(widget.initialUrl)),
        initialSettings: settings,
        onWebViewCreated: _onWebViewCreated,
        onPermissionRequest: (controller, request) async {
          return inapp.PermissionResponse(
              resources: request.resources,
              action: inapp.PermissionResponseAction.GRANT);
        },
      );
    }

    return webviewWidget;
  }
}
