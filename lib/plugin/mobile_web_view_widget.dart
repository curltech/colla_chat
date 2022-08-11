import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../l10n/localization.dart';
import '../platform.dart';
import '../widgets/common/app_bar_view.dart';
import '../widgets/common/widget_mixin.dart';

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
    if (PlatformParams.instance.android) {
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
      title: Text(AppLocalizations.t(widget.title)),
      withLeading: widget.withLeading,
      child: WebView(
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          controller.complete(webViewController);
        },
        onProgress: (int progress) {
          print('WebView is loading (progress : $progress%)');
        },
        javascriptChannels: <JavascriptChannel>{
          _toasterJavascriptChannel(context),
        },
        navigationDelegate: (NavigationRequest request) {
          if (request.url.startsWith('https://www.youtube.com/')) {
            print('blocking navigation to $request}');
            return NavigationDecision.prevent;
          }
          print('allowing navigation to $request');
          return NavigationDecision.navigate;
        },
        onPageStarted: (String url) {
          print('Page started loading: $url');
        },
        onPageFinished: (String url) {
          print('Page finished loading: $url');
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
