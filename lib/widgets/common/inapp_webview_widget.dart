import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppWebViewUrlController with ChangeNotifier {
  String _url = '';

  String get url {
    return _url;
  }

  set url(String url) {
    _url = url;
    notifyListeners();
  }
}

InAppWebViewUrlController inAppWebViewUrlController =
    InAppWebViewUrlController();

class InAppWebViewWidget extends StatefulWidget with TileDataMixin {
  const InAppWebViewWidget({super.key});

  @override
  State createState() => _InAppWebViewWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'inapp_webview';

  @override
  Icon get icon => const Icon(Icons.person);

  @override
  String get title => 'InApp Webview';
}

class _InAppWebViewWidgetState extends State<InAppWebViewWidget> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  PullToRefreshController? pullToRefreshController;

  //String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    inAppWebViewUrlController.addListener(_update);
    pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.blue,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );
  }

  _update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    urlController.text = inAppWebViewUrlController.url;
    return AppBarView(
        withLeading: true,
        child: Column(children: <Widget>[
          buildTextField(),
          Expanded(
            child: Stack(
              children: [
                buildInAppWebView(),
                progress < 1.0
                    ? LinearProgressIndicator(value: progress)
                    : Container(),
              ],
            ),
          ),
          buildButtonBar(),
        ]));
  }

  TextField buildTextField() {
    return TextField(
      decoration: const InputDecoration(prefixIcon: Icon(Icons.search)),
      controller: urlController,
      keyboardType: TextInputType.url,
      onSubmitted: (value) {
        var url = WebUri(value);
        if (url.scheme.isEmpty) {
          url = WebUri("https://www.google.com/search?q=$value");
        }
        webViewController?.loadUrl(urlRequest: URLRequest(url: url));
      },
    );
  }

  InAppWebView buildInAppWebView() {
    return InAppWebView(
      key: webViewKey,
      initialUrlRequest: URLRequest(url: WebUri("https://inappwebview.dev/")),
      initialSettings: settings,
      pullToRefreshController: pullToRefreshController,
      onWebViewCreated: (controller) {
        webViewController = controller;
      },
      onLoadStart: (controller, url) {
        inAppWebViewUrlController.url = url.toString();
        urlController.text = inAppWebViewUrlController.url;
      },
      onPermissionRequest: (controller, request) async {
        return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT);
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
            return NavigationActionPolicy.CANCEL;
          }
        }

        return NavigationActionPolicy.ALLOW;
      },
      onLoadStop: (controller, url) async {
        pullToRefreshController?.endRefreshing();
        inAppWebViewUrlController.url = url.toString();
        urlController.text = inAppWebViewUrlController.url;
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
          urlController.text = inAppWebViewUrlController.url;
        });
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) {
        inAppWebViewUrlController.url = url.toString();
        urlController.text = inAppWebViewUrlController.url;
      },
      onConsoleMessage: (controller, consoleMessage) {
        logger.i(consoleMessage);
      },
    );
  }

  ButtonBar buildButtonBar() {
    return ButtonBar(
      alignment: MainAxisAlignment.center,
      children: <Widget>[
        ElevatedButton(
          child: const Icon(Icons.arrow_back),
          onPressed: () {
            webViewController?.goBack();
          },
        ),
        ElevatedButton(
          child: const Icon(Icons.arrow_forward),
          onPressed: () {
            webViewController?.goForward();
          },
        ),
        ElevatedButton(
          child: const Icon(Icons.refresh),
          onPressed: () {
            webViewController?.reload();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    inAppWebViewUrlController.removeListener(_update);
    super.dispose();
  }
}
