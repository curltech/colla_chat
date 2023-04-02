import 'package:colla_chat/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// InAppWebView，打开一个内部的浏览器窗口，可以用来观看网页，音频，视频文件，office文件
class FlutterInAppWebView extends StatefulWidget {
  final String? initialUrl;
  final String? html;
  final void Function(InAppWebViewController controller)? onWebViewCreated;

  const FlutterInAppWebView(
      {super.key, this.initialUrl, this.html, this.onWebViewCreated});

  @override
  State createState() => _FlutterInAppWebViewState();
}

class _FlutterInAppWebViewState extends State<FlutterInAppWebView> {
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  ///6.x.x
  // InAppWebViewSettings settings = InAppWebViewSettings(
  //     useShouldOverrideUrlLoading: true,
  //     mediaPlaybackRequiresUserGesture: false,
  //     allowsInlineMediaPlayback: true,
  //     iframeAllow: "camera; microphone",
  //     iframeAllowFullscreen: true);

  PullToRefreshController pullToRefreshController = PullToRefreshController();
  InAppWebViewController? controller;

  @override
  void initState() {
    super.initState();
  }

  _onWebViewCreated(InAppWebViewController controller) {
    this.controller = controller;
    if (widget.onWebViewCreated != null) {
      widget.onWebViewCreated!(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget inAppWebView;
    if (platformParams.mobile || platformParams.web) {
      inAppWebView = InAppWebView(
        initialUrlRequest: widget.initialUrl != null
            ? URLRequest(url: Uri.parse(widget.initialUrl!))
            : null,
        initialOptions: options,
        // initialSettings: settings,
        onWebViewCreated: _onWebViewCreated,
        pullToRefreshController: pullToRefreshController,
        onLoadStart: (controller, url) {},
        androidOnPermissionRequest: (controller, origin, resources) async {
          return PermissionRequestResponse(
              resources: resources,
              action: PermissionRequestResponseAction.GRANT);
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
      if (widget.html != null) {
        controller!.loadData(data: widget.html!);
      }
    } else {
      inAppWebView = Container();
    }

    return inAppWebView;
  }
}
