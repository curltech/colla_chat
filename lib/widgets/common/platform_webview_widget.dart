import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/platform_webview.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview;
import 'package:url_launcher/url_launcher.dart';

import 'package:webview_win_floating/webview.dart';

///
class PlatformWebViewWidget extends StatefulWidget with TileDataMixin {
  PlatformWebViewWidget({super.key}) {
    if (platformParams.windows) {
      webview.WebView.platform = WindowsWebViewPlugin();
    }

    if (platformParams.android) {
      webview.WebView.platform = webview.AndroidWebView();
    }
  }

  @override
  State createState() => _PlatformWebViewWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'webview';

  @override
  Icon get icon => const Icon(Icons.web);

  @override
  String get title => 'Webview';
}

class _PlatformWebViewWidgetState extends State<PlatformWebViewWidget> {
  String initialUrl = 'https://bing.com/';
  PlatformWebViewController? webViewController;
  inapp.InAppWebViewSettings settings = inapp.InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  inapp.PullToRefreshController? pullToRefreshController;

  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    pullToRefreshController = kIsWeb
        ? null
        : inapp.PullToRefreshController(
            settings: inapp.PullToRefreshSettings(
              color: Colors.blue,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                String? url = await webViewController?.getUrl();
                webViewController?.load(url);
              }
            },
          );
  }

  _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        withLeading: true,
        child: Column(children: <Widget>[
          buildTextField(),
          Expanded(
            child: Stack(
              children: [
                buildWebView(),
                progress < 1.0
                    ? LinearProgressIndicator(value: progress)
                    : Container(),
              ],
            ),
          ),
        ]));
  }

  Widget buildTextField() {
    return Row(children: [
      InkWell(
        child: const Icon(Icons.arrow_back),
        onTap: () {
          webViewController?.goBack();
        },
      ),
      InkWell(
        child: const Icon(Icons.arrow_forward),
        onTap: () {
          webViewController?.goForward();
        },
      ),
      InkWell(
        child: const Icon(Icons.refresh),
        onTap: () {
          webViewController?.reload();
        },
      ),
      Expanded(
          child: TextFormField(
        autofocus: true,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.https),
        ),
        controller: urlController,
        keyboardType: TextInputType.url,
        onEditingComplete: () {
          String url = urlController.text;
          if (!url.startsWith('http')) {
            url = 'https://$url';
          }
          webViewController?.load(url);
        },
      )),
    ]);
  }

  _onWebViewCreated(dynamic controller) {
    webViewController = PlatformWebViewController.from(controller);
  }

  Widget buildWebView() {
    if (platformParams.windows || platformParams.mobile || platformParams.web) {
      return webview.WebView(
        backgroundColor: Colors.black,
        initialUrl: initialUrl,
        javascriptMode: webview.JavascriptMode.unrestricted,
        onWebViewCreated: _onWebViewCreated,
        gestureNavigationEnabled: true,
        allowsInlineMediaPlayback: true,
        initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
      );
    } else {
      return buildInAppWebView();
    }
  }

  Widget buildInAppWebView() {
    return inapp.InAppWebView(
      initialUrlRequest: inapp.URLRequest(url: inapp.WebUri(initialUrl)),
      initialSettings: settings,
      pullToRefreshController: pullToRefreshController,
      onWebViewCreated: _onWebViewCreated,
      onLoadStart: (controller, url) {
        urlController.text = url.toString();
      },
      onPermissionRequest: (controller, request) async {
        return inapp.PermissionResponse(
            resources: request.resources,
            action: inapp.PermissionResponseAction.GRANT);
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        var uri = navigationAction.request.url!;
        if (!["http", "https", "file", "chrome", "data", "javascript", "about"]
            .contains(uri.scheme)) {
          if (await canLaunchUrl(uri)) {
            // Launch the App
            await launchUrl(
              uri,
            );
            // and cancel the request
            return inapp.NavigationActionPolicy.CANCEL;
          }
        }

        return inapp.NavigationActionPolicy.ALLOW;
      },
      onLoadStop: (controller, url) async {
        pullToRefreshController?.endRefreshing();
        urlController.text = url.toString();
      },
      onReceivedError: (controller, request, error) {
        pullToRefreshController?.endRefreshing();
      },
      onProgressChanged: (controller, progress) {
        if (progress == 100) {
          pullToRefreshController?.endRefreshing();
        }
        setState(() {
          this.progress = progress / 100;
        });
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) {
        urlController.text = url.toString();
      },
      onConsoleMessage: (controller, consoleMessage) {
        logger.i(consoleMessage);
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
