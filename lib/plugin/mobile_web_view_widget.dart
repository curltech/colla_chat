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
  IconData get iconData => Icons.video_call;

  @override
  String get title => 'MobileWebView';
}

class _MobileWebViewWidgetState extends State<MobileWebViewWidget> {
  late final WebViewController webViewController;

  @override
  void initState() {
    super.initState();
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      child: WebViewWidget(
        key: UniqueKey(),
        controller: webViewController,
      ),
    );

    return appBarView;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
