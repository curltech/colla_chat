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

  // inapp.InAppWebViewSettings settings = inapp.InAppWebViewSettings(
  //     useShouldOverrideUrlLoading: true,
  //     mediaPlaybackRequiresUserGesture: false,
  //     allowsInlineMediaPlayback: true,
  //     iframeAllow: "camera; microphone",
  //     iframeAllowFullscreen: true);

  inapp.PullToRefreshController? pullToRefreshController;

  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    pullToRefreshController = kIsWeb
        ? null
        : inapp.PullToRefreshController(
            options: inapp.PullToRefreshOptions(
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

  Widget buildWebView() {
    return PlatformWebView();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
