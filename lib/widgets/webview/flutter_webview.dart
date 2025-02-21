import 'dart:io';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// FlutterWebView，打开一个内部的浏览器窗口，可以用来观看网页，音频，视频文件，office文件
/// 支持移动和windows平台
class FlutterWebView extends StatelessWidget {
  final String? initialUrl;
  final String? html;
  final String? initialFilename;
  final void Function(WebViewController controller)? onWebViewCreated;

  WebViewController? controller;
  Widget? webView;

  FlutterWebView(
      {super.key,
      this.initialUrl,
      this.html,
      this.initialFilename,
      this.onWebViewCreated}) {
    _buildWebViewController();
    _buildWebViewWidget();
    _initWebViewContent();
  }

  void _buildWebViewController() {
    controller = WebViewController();
    controller!.setJavaScriptMode(JavaScriptMode.unrestricted);
    // controller!.setBackgroundColor(Colors.white);
    controller!.setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: (request) {
      //logger.i("request navigate ${request.url}");
      return NavigationDecision.navigate;
    }, onPageStarted: (url) {
      //logger.i("onPageStarted: $url");
    }, onPageFinished: (url) {
      //logger.i("onPageFinished: $url");
    }, onWebResourceError: (error) {
      logger.i("onWebResourceError: ${error.description}");
    }));
    if (onWebViewCreated != null) {
      onWebViewCreated!(controller!);
    }
  }

  Future<String> writeHtml(String html) async {
    String filename = await FileUtil.getTempFilename(extension: 'html');
    File file = File(filename);
    bool exist = file.existsSync();
    if (exist) {
      file.deleteSync();
    }
    file.writeAsStringSync(html, flush: true);

    return filename;
  }

  _initWebViewContent() {
    if (initialUrl != null) {
      controller!.loadRequest(Uri.parse(initialUrl!));
    }
    if (initialFilename != null) {
      controller!.loadFile(initialFilename!);
    }
    if (html != null) {
      if (platformParams.windows) {
        //windows平台不能直接加载html，会乱码
        writeHtml(html!).then((String filename) {
          controller!.loadFile(filename);
        });
      } else {
        controller!.loadHtmlString(html!);
      }
    }
  }

  _buildWebViewWidget() {
    if (platformParams.desktop || platformParams.mobile || platformParams.web) {
      webView = WebViewWidget(
        controller: controller!,
      );
    } else {
      webView = Center(
          child:
              CommonAutoSizeText(AppLocalizations.t('Not supported platform')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return webView!;
  }
}
