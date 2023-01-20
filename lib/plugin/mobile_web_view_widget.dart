import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MobileWebViewWidget extends StatefulWidget with TileDataMixin {
  final String url;

  MobileWebViewWidget({Key? key, required this.url}) : super(key: key);

  @override
  State createState() => _MobileWebViewWidgetState();

  @override
  String get routeName => 'mobile_web_view';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.video_call);

  @override
  String get title => 'MobileWebView';
}

class _MobileWebViewWidgetState extends State<MobileWebViewWidget> {
  final Completer<WebViewController> controller =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    if (platformParams.android) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      child: WebView(
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          controller.complete(webViewController);
        },
        onProgress: (int progress) {
          logger.i('WebView is loading (progress : $progress%)');
        },
        javascriptChannels: <JavascriptChannel>{
          _toasterJavascriptChannel(context),
        },
        navigationDelegate: (NavigationRequest request) {
          if (request.url.startsWith('https://www.youtube.com/')) {
            logger.i('blocking navigation to $request}');
            return NavigationDecision.prevent;
          }
          logger.i('allowing navigation to $request');
          return NavigationDecision.navigate;
        },
        onPageStarted: (String url) {
          logger.i('Page started loading: $url');
        },
        onPageFinished: (String url) {
          logger.i('Page finished loading: $url');
        },
        gestureNavigationEnabled: true,
        backgroundColor: const Color(0x00000000),
      ),
    );

    return appBarView;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
