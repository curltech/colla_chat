import 'dart:io';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/webview/flutter_webview.dart';
import 'package:colla_chat/widgets/webview/html_webview.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview;
import 'package:webf/webf.dart' as webf;
import 'package:webf/devtools.dart';

/// 平台浏览器的控制器
class PlatformWebViewController with ChangeNotifier {
  webf.WebFController? webfController;
  webview.WebViewController? webViewController;

  ///包装两种webview的实现
  PlatformWebViewController({
    this.webViewController,
    this.webfController,
  });

  from(dynamic controller) {
    if (controller is webview.WebViewController) {
      webViewController = controller;
      webfController = null;
    } else if (controller is webf.WebFController) {
      webViewController = null;
      webfController = controller;
    } else {
      webViewController = null;
      webfController = null;
    }
  }

  loadHtml(String html) async {
    if (webViewController != null) {
      if (platformParams.windows) {
        //windows平台不能直接加载html，会乱码
        String filename = await FileUtil.getTempFilename(extension: 'html');
        File file = File(filename);
        bool exist = file.existsSync();
        if (!exist) {
          file.writeAsStringSync(html, flush: true);
        }
        await webViewController!.loadFile(filename);
      } else {
        await webViewController!.loadHtmlString(html);
      }
    } else if (webfController != null) {
      webf.WebFBundle bundle = webf.WebFBundle.fromContent(html);
      await webfController!.load(bundle);
    }
  }

  load(String? filename) async {
    if (StringUtil.isEmpty(filename)) {
      String html = """<html><body></body></html>""";
      if (webViewController != null) {
        await webViewController!.loadHtmlString(html);
      } else if (webfController != null) {
        webf.WebFBundle bundle = webf.WebFBundle.fromContent(html);
        await webfController!.load(bundle);
      }
    }
    if (filename!.startsWith('assets')) {
      if (webViewController != null) {
        await webViewController!.loadFlutterAsset(filename);
      } else if (webfController != null) {
        webf.WebFBundle bundle = webf.WebFBundle.fromUrl(filename);
        await webfController!.load(bundle);
      }
    } else if (filename.startsWith('http')) {
      if (webViewController != null) {
        await webViewController!.loadRequest(Uri.parse(filename));
      } else if (webfController != null) {
        webf.WebFBundle bundle = webf.WebFBundle.fromUrl(filename);
        await webfController!.load(bundle);
      }
    } else {
      if (webViewController != null) {
        await webViewController!.loadFile(filename);
      } else if (webfController != null) {
        webf.WebFBundle bundle = webf.WebFBundle.fromUrl(filename);
        await webfController!.load(bundle);
      }
    }
  }

  reload() async {
    if (webViewController != null) {
      await webViewController!.reload();
    } else if (webfController != null) {
      await webfController!.reload();
    }
  }

  goBack() async {
    if (webViewController != null) {
      await webViewController!.goBack();
    } else if (webfController != null) {
      webfController!.history.back();
    }
  }

  goForward() async {
    if (webViewController != null) {
      await webViewController!.goForward();
    } else if (webfController != null) {
      webfController!.history.forward();
    }
  }

  Future<String?> getUrl() async {
    if (webViewController != null) {
      return await webViewController!.currentUrl();
    } else if (webfController != null) {
      return webfController!.url;
    }
    return null;
  }
}

/// 平台Webview，打开一个内部的浏览器窗口，可以用来观看网页，音频，视频文件，office文件
/// 支持所以的平台，移动和windows平台使用webview，macos和linux使用webf
class PlatformWebView extends StatelessWidget {
  final String? initialUrl;
  final String? html;
  final String? initialFilename;
  final bool inline;
  double? width;
  double? height;

  final PlatformWebViewController webViewController;

  PlatformWebView(
      {super.key,
      this.initialUrl,
      this.html,
      this.initialFilename,
      this.inline = false,
      this.width,
      this.height,
      required this.webViewController});

  Future<String?> readHtml(String filename) async {
    File file = File(filename);
    bool exist = file.existsSync();
    if (exist) {
      return await file.readAsString();
    }
    return null;
  }

  Widget _buildPlatformWebView(BuildContext context) {
    Widget platformWebView;
    if (inline) {
      if (html != null) {
        platformWebView = HtmlWebView(
          html: html!,
        );
      } else if (initialFilename != null) {
        platformWebView = PlatformFutureBuilder(
            future: readHtml(initialFilename!),
            builder: (BuildContext context, String? html) {
              return HtmlWebView(
                html: html!,
              );
            });
      } else {
        platformWebView = nil;
      }
    } else {
      if (platformParams.windows ||
          // platformParams.macos ||
          platformParams.mobile ||
          platformParams.web) {
        platformWebView = FlutterWebView(
          initialUrl: initialUrl,
          html: html,
          initialFilename: initialFilename,
          onWebViewCreated: (webview.WebViewController controller) {
            webViewController.from(controller);
          },
        );
      } else {
        webf.WebFController webFController = webf.WebFController(
          context,
          // devToolsService: ChromeDevToolsService(),
        );
        if (initialUrl != null) {
          webFController.preload(webf.WebFBundle.fromUrl(initialUrl!));
        } else if (initialFilename != null) {
          webFController.preload(webf.WebFBundle.fromUrl(initialFilename!));
        } else if (html != null) {
          webFController.preload(webf.WebFBundle.fromContent(html!));
        } else {
          String html = """<html><body></body></html>""";
          webFController.preload(webf.WebFBundle.fromContent(html));
        }
        webViewController.from(webFController);
        platformWebView = webf.WebF(controller: webFController);
      }
    }

    return platformWebView;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(child: _buildPlatformWebView(context)),
    );
  }
}
