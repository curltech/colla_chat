import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/flutter_webview.dart';
import 'package:colla_chat/widgets/common/inapp_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:webview_flutter/webview_flutter.dart' as webview;

class PlatformWebViewController with ChangeNotifier {
  inapp.InAppWebViewController? inAppWebViewController;
  webview.WebViewController? webViewController;
  final inapp.InAppBrowser browser = inapp.InAppBrowser();

  ///包装两种webview的实现
  PlatformWebViewController({
    this.webViewController,
    this.inAppWebViewController,
  });

  static PlatformWebViewController from(dynamic controller) {
    PlatformWebViewController platformWebViewController =
        PlatformWebViewController();
    if (controller is webview.WebViewController) {
      platformWebViewController.webViewController = controller;
      platformWebViewController.inAppWebViewController = null;
    } else if (controller is inapp.InAppWebViewController) {
      platformWebViewController.webViewController = null;
      platformWebViewController.inAppWebViewController = controller;
    } else {
      platformWebViewController.webViewController = null;
      platformWebViewController.inAppWebViewController = null;
    }

    return platformWebViewController;
  }

  loadHtml(String html) async {
    if (webViewController != null) {
      await webViewController!.loadHtmlString(html);
    } else if (inAppWebViewController != null) {
      await inAppWebViewController!.loadData(data: html);
    } else {
      if (platformParams.macos) {
        if (platformParams.macos) {
          var settings = _getSettings();
          browser.openData(data: html, settings: settings);
        }
      }
    }
  }

  load(String? filename) async {
    if (StringUtil.isEmpty(filename)) {
      String html = """<html><body></body></html>""";
      if (webViewController != null) {
        await webViewController!.loadHtmlString(html);
      } else if (inAppWebViewController != null) {
        await inAppWebViewController!.loadData(data: html);
      } else {
        if (platformParams.macos) {
          var settings = _getSettings();
          browser.openData(data: html, settings: settings);
        }
      }
    }
    if (filename!.startsWith('assets')) {
      if (webViewController != null) {
        await webViewController!.loadFlutterAsset(filename);
      } else if (inAppWebViewController != null) {
        await inAppWebViewController!.loadFile(assetFilePath: filename);
      } else {
        if (platformParams.macos) {
          var settings = _getSettings();
          browser.openFile(
            assetFilePath: filename,
            settings: settings,
          );
        }
      }
    } else if (filename.startsWith('http')) {
      if (webViewController != null) {
        await webViewController!.loadRequest(Uri.parse(filename));
      } else if (inAppWebViewController != null) {
        inapp.URLRequest urlRequest =
            inapp.URLRequest(url: inapp.WebUri(filename));
        await inAppWebViewController!.loadUrl(urlRequest: urlRequest);
      } else {
        if (platformParams.macos) {
          inapp.URLRequest urlRequest =
              inapp.URLRequest(url: inapp.WebUri(filename));
          var settings = _getSettings();
          browser.openUrlRequest(urlRequest: urlRequest, settings: settings);
        }
      }
    } else {
      if (webViewController != null) {
        await webViewController!.loadFile(filename);
      } else if (inAppWebViewController != null) {
        inapp.URLRequest urlRequest =
            inapp.URLRequest(url: inapp.WebUri('file:$filename'));
        await inAppWebViewController!.loadUrl(urlRequest: urlRequest);
      } else {
        if (platformParams.macos) {
          inapp.URLRequest urlRequest =
              inapp.URLRequest(url: inapp.WebUri('file:$filename'));
          var settings = _getSettings();
          browser.openUrlRequest(urlRequest: urlRequest, settings: settings);
        }
      }
    }
  }

  inapp.InAppBrowserClassSettings _getSettings() {
    var settings = inapp.InAppBrowserClassSettings(
      browserSettings: inapp.InAppBrowserSettings(
        hideUrlBar: false,
        toolbarTopBackgroundColor: myself.primary,
        presentationStyle: inapp.ModalPresentationStyle.CURRENT_CONTEXT,
      ),
      webViewSettings: inapp.InAppWebViewSettings(
        useOnLoadResource: true,
      ),
    );

    return settings;
  }

  reload() async {
    if (webViewController != null) {
      await webViewController!.reload();
    } else if (inAppWebViewController != null) {
      await inAppWebViewController!.reload();
    }
  }

  goBack() async {
    if (webViewController != null) {
      await webViewController!.goBack();
    } else if (inAppWebViewController != null) {
      await inAppWebViewController!.goBack();
    }
  }

  goForward() async {
    if (webViewController != null) {
      await webViewController!.goForward();
    } else if (inAppWebViewController != null) {
      await inAppWebViewController!.goForward();
    }
  }

  Future<String?> getUrl() async {
    if (webViewController != null) {
      return await webViewController!.currentUrl();
    } else if (inAppWebViewController != null) {
      Uri? webUri = await inAppWebViewController!.getUrl();
      return webUri.toString();
    }
    return null;
  }
}

/// 平台Webview，打开一个内部的浏览器窗口，可以用来观看网页，音频，视频文件，office文件
class PlatformWebView extends StatefulWidget {
  final String? initialUrl;
  final String? html;
  final String? initialFilename;
  final void Function(PlatformWebViewController controller)? onWebViewCreated;

  const PlatformWebView(
      {super.key,
      this.initialUrl = 'bing.com',
      this.html,
      this.initialFilename,
      this.onWebViewCreated});

  @override
  State createState() => _PlatformWebViewState();
}

class _PlatformWebViewState extends State<PlatformWebView> {
  PlatformWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
  }

  _onWebViewCreated(dynamic controller) {
    webViewController = PlatformWebViewController.from(controller);
    if (widget.onWebViewCreated != null) {
      widget.onWebViewCreated!(webViewController!);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget platformWebView;
    if (platformParams.windows || platformParams.mobile || platformParams.web) {
      platformWebView = FlutterWebView(
        initialUrl: widget.initialUrl,
        html: widget.html,
        initialFilename: widget.initialFilename,
        onWebViewCreated: (webview.WebViewController controller) {
          _onWebViewCreated(controller);
        },
      );
    } else {
      platformWebView = FlutterInAppWebView(
        initialUrl: widget.initialUrl,
        html: widget.html,
        initialFilename: widget.initialFilename,
        onWebViewCreated: (inapp.InAppWebViewController controller) {
          _onWebViewCreated(controller);
        },
      );
    }

    return platformWebView;
  }
}
