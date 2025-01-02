import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// InAppWebView，打开一个内部的浏览器窗口，可以用来观看网页，音频，视频文件，office文件
/// 不支持linux
class FlutterInAppWebView extends StatelessWidget {
  final String? initialUrl;
  final String? html;
  final String? initialFilename;
  final void Function(InAppWebViewController controller)? onWebViewCreated;

  PullToRefreshController pullToRefreshController = PullToRefreshController();
  InAppWebViewController? controller;
  late final Widget inAppWebView;
  final InAppBrowser browser = InAppBrowser();

  FlutterInAppWebView(
      {super.key,
      this.initialUrl,
      this.html,
      this.initialFilename,
      this.onWebViewCreated}) {
    _buildInAppWebView();
  }

  _getSetting() {
    InAppWebViewSettings settings = InAppWebViewSettings(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        iframeAllow: "camera; microphone",
        iframeAllowFullscreen: true);

    return settings;
  }

  _onWebViewCreated(InAppWebViewController controller) {
    this.controller = controller;
    if (onWebViewCreated != null) {
      onWebViewCreated!(controller);
    }
  }

  Widget _buildInAppWebView() {
    InAppWebViewSettings settings = _getSetting();
    URLRequest? urlRequest =
        initialUrl != null ? URLRequest(url: WebUri(initialUrl!)) : null;

    ///移动和web直接使用InAppWebView
    if (platformParams.mobile || platformParams.web) {
      inAppWebView = InAppWebView(
        initialUrlRequest: urlRequest,
        initialFile: initialFilename,
        initialSettings: settings,
        onWebViewCreated: _onWebViewCreated,
        pullToRefreshController: pullToRefreshController,
        onLoadStart: (controller, url) {},
        onPermissionRequest: (controller, origin) async {
          return PermissionResponse(
              resources: [], action: PermissionResponseAction.DENY);
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          return null;
        },
        onLoadStop: (controller, url) async {
          pullToRefreshController.endRefreshing();
        },
        onReceivedError: (controller, url, err) {
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
      if (html != null) {
        controller!.loadData(data: html!);
      }
    } else {
      inAppWebView = Center(
          child:
              CommonAutoSizeText(AppLocalizations.t('Not supported platform')));
    }

    return inAppWebView;
  }

  @override
  Widget build(BuildContext context) {
    return inAppWebView;
  }
}
