import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// InAppWebView，打开一个内部的浏览器窗口，可以用来观看网页，音频，视频文件，office文件
class FlutterInAppWebView extends StatelessWidget {
  final String? initialUrl;
  final String? html;
  final String? initialFilename;
  final int inAppWebViewVersion = 6;
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
    if (inAppWebViewVersion == 5) {
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

      return options;
    }
    if (inAppWebViewVersion == 6) {
      ///6.x.x
      InAppWebViewSettings settings = InAppWebViewSettings(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          iframeAllow: "camera; microphone",
          iframeAllowFullscreen: true);

      return settings;
    }
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
        // 5.x.x initialOptions: settings,
        initialSettings: settings,
        onWebViewCreated: _onWebViewCreated,
        pullToRefreshController: pullToRefreshController,
        onLoadStart: (controller, url) {},
        // 5.x.x androidOnPermissionRequest: (controller, origin, resources) async {
        //   return PermissionRequestResponse(
        //       resources: resources,
        //       action: PermissionRequestResponseAction.GRANT);
        // },
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
        // 5.x.x onLoadError: (controller, url, code, message) {
        //   pullToRefreshController.endRefreshing();
        // },
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
    } else if (platformParams.macos && html != null) {
      inAppWebView = Center(
          child: CommonAutoSizeText(
              AppLocalizations.t('Only supported in App browser')));
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
