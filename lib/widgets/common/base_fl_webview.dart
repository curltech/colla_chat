import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:fl_webview/fl_webview.dart';

/// FlWebView，打开一个内部的浏览器窗口，可以用来观看网页，音频，视频文件，office文件
class BaseFlWebView extends StatefulWidget {
  final String initialUrl;
  final String? html;
  final String? initialFilename;
  final void Function(FlWebViewController controller)? onWebViewCreated;

  const BaseFlWebView(
      {super.key,
      this.initialUrl = 'bing.com',
      this.html,
      this.initialFilename,
      this.onWebViewCreated});

  @override
  State createState() => _BaseFlWebViewState();
}

class _BaseFlWebViewState extends State<BaseFlWebView> {
  FlWebViewController? controller;

  @override
  void initState() {
    super.initState();
  }

  _onWebViewCreated(FlWebViewController controller) {
    this.controller = controller;
    if (widget.onWebViewCreated != null) {
      widget.onWebViewCreated!(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget webView;
    if (platformParams.windows || platformParams.mobile || platformParams.web) {
      webView = FlWebView(
          load: LoadUrlRequest(widget.initialUrl),
          progressBar: FlProgressBar(color: myself.primary),
          webSettings: WebSettings(),
          delegate: FlWebViewDelegate(
              onPageStarted: (FlWebViewController controller, String url) {
            logger.i('onPageStarted : $url');
          }, onPageFinished: (FlWebViewController controller, String url) {
            logger.i('onPageFinished : $url');
          }, onProgress: (FlWebViewController controller, int progress) {
            logger.i('onProgress ：$progress');
          }, onSizeChanged:
                  (FlWebViewController controller, WebViewSize webViewSize) {
            logger.i(
                'onSizeChanged : ${webViewSize.frameSize} --- ${webViewSize.contentSize}');
          }, onScrollChanged: (FlWebViewController controller,
                  WebViewSize webViewSize,
                  Offset offset,
                  ScrollPositioned positioned) {
            logger.i(
                'onScrollChanged : ${webViewSize.frameSize} --- ${webViewSize.contentSize} --- $offset --- $positioned');
          }, onNavigationRequest:
                  (FlWebViewController controller, NavigationRequest request) {
            logger.i(
                'onNavigationRequest : url=${request.url} --- isForMainFrame=${request.isForMainFrame}');
            return true;
          }, onUrlChanged: (FlWebViewController controller, String url) {
            logger.i('onUrlChanged : $url');
          }),
          onWebViewCreated: (FlWebViewController controller) async {
            String userAgentString = 'userAgentString';
            final value = await controller.getNavigatorUserAgent();
            logger.i('navigator.userAgent :  $value');
            userAgentString = '$value = $userAgentString';
            final userAgent = await controller.setUserAgent(userAgentString);
            logger.i('set userAgent:  $userAgent');
            _onWebViewCreated(controller);
          });
    } else {
      webView = Container();
    }

    return webView;
  }
}
