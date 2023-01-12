import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview;

class PlatformWebViewController with ChangeNotifier {
  inapp.InAppWebViewController? inAppWebViewController;
  webview.WebViewController? webViewController;

  PlatformWebViewController(
      {this.webViewController, this.inAppWebViewController});

  static PlatformWebViewController from(dynamic controller) {
    PlatformWebViewController platformWebViewController =
        PlatformWebViewController();
    if (controller is webview.WebViewController) {
      platformWebViewController.webViewController = controller;
      platformWebViewController.inAppWebViewController = null;
    } else if (controller is inapp.InAppWebViewController) {
      platformWebViewController.webViewController = null;
      platformWebViewController.inAppWebViewController = controller;
    } else {
      platformWebViewController.webViewController = null;
      platformWebViewController.inAppWebViewController = null;
    }

    return platformWebViewController;
  }

  load(String? filename) async {
    if (StringUtil.isEmpty(filename)) {
      String html = """<html><body></body></html>""";
      if (webViewController != null) {
        await webViewController!.loadHtmlString(html);
      } else if (inAppWebViewController != null) {
        await inAppWebViewController!.loadData(data: html);
      }
      return;
    }
    if (filename!.startsWith('assets')) {
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
            inapp.URLRequest(url: Uri.parse(filename));
        await inAppWebViewController!.loadUrl(urlRequest: urlRequest);
      }
    } else {
      if (webViewController != null) {
        await webViewController!.loadFile(filename);
      } else if (inAppWebViewController != null) {
        inapp.URLRequest urlRequest =
            inapp.URLRequest(url: Uri.parse('file:$filename'));
        await inAppWebViewController!.loadUrl(urlRequest: urlRequest);
      }
    }
  }

  reload() async {
    if (webViewController != null) {
      await webViewController!.reload();
    } else if (inAppWebViewController != null) {
      await inAppWebViewController!.reload();
    }
  }

  goBack() async {
    if (webViewController != null) {
      await webViewController!.goBack();
    } else if (inAppWebViewController != null) {
      await inAppWebViewController!.goBack();
    }
  }

  goForward() async {
    if (webViewController != null) {
      await webViewController!.goForward();
    } else if (inAppWebViewController != null) {
      await inAppWebViewController!.goForward();
    }
  }

  Future<String?> getUrl() async {
    if (webViewController != null) {
      return await webViewController!.currentUrl();
    } else if (inAppWebViewController != null) {
      Uri? webUri = await inAppWebViewController!.getUrl();
      return webUri.toString();
    }
    return null;
  }
}

/// 平台Webview，打开一个内部的浏览器窗口，可以用来观看网页，音频，视频文件，office文件
class PlatformWebView extends StatefulWidget {
  final String? initialUrl;
  final void Function(PlatformWebViewController controller)? onWebViewCreated;

  const PlatformWebView({super.key, this.initialUrl, this.onWebViewCreated});

  @override
  State createState() => _PlatformWebViewState();
}

class _PlatformWebViewState extends State<PlatformWebView> {
  inapp.InAppWebViewGroupOptions options = inapp.InAppWebViewGroupOptions(
      crossPlatform: inapp.InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: inapp.AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: inapp.IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  ///6.x.x
  // inapp.InAppWebViewSettings settings = inapp.InAppWebViewSettings(
  //     useShouldOverrideUrlLoading: true,
  //     mediaPlaybackRequiresUserGesture: false,
  //     allowsInlineMediaPlayback: true,
  //     iframeAllow: "camera; microphone",
  //     iframeAllowFullscreen: true);

  inapp.PullToRefreshController pullToRefreshController =
      inapp.PullToRefreshController();
  PlatformWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
  }

  _onWebViewCreated(dynamic controller) {
    webViewController = PlatformWebViewController.from(controller);
    if (widget.onWebViewCreated != null) {
      widget.onWebViewCreated!(webViewController!);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget webviewWidget;
    if (platformParams.windows || platformParams.mobile || platformParams.web) {
      webviewWidget = webview.WebView(
        key: UniqueKey(),
        backgroundColor: Colors.black,
        initialUrl: widget.initialUrl,
        javascriptMode: webview.JavascriptMode.unrestricted,
        onWebViewCreated: _onWebViewCreated,
        onPageStarted: (url) => logger.i("onPageStarted: $url"),
        onPageFinished: (url) => logger.i("onPageFinished"),
        onWebResourceError: (error) => logger.i("error: ${error.failingUrl}"),
        gestureNavigationEnabled: true,
        allowsInlineMediaPlayback: true,
        initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
      );
    } else {
      webviewWidget = inapp.InAppWebView(
        key: UniqueKey(),
        initialUrlRequest: widget.initialUrl != null
            ? inapp.URLRequest(url: Uri.parse(widget.initialUrl!))
            : null,
        initialOptions: options,
        // initialSettings: settings,
        onWebViewCreated: _onWebViewCreated,
        pullToRefreshController: pullToRefreshController,
        onLoadStart: (controller, url) {},
        androidOnPermissionRequest: (controller, origin, resources) async {
          return inapp.PermissionRequestResponse(
              resources: resources,
              action: inapp.PermissionRequestResponseAction.GRANT);
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {},
        onLoadStop: (controller, url) async {
          pullToRefreshController.endRefreshing();
        },
        onLoadError: (controller, url, code, message) {
          pullToRefreshController.endRefreshing();
        },
        onProgressChanged: (controller, progress) {
          if (progress == 100) {
            pullToRefreshController.endRefreshing();
          }
        },
        onUpdateVisitedHistory: (controller, url, androidIsReload) {},
        onConsoleMessage: (controller, consoleMessage) {},
      );
    }

    return webviewWidget;
  }
}
