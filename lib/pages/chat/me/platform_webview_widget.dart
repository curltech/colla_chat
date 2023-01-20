import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/platform_webview.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

class PlatformWebViewWidget extends StatefulWidget with TileDataMixin {
  PlatformWebViewController platformWebViewController =
      PlatformWebViewController();
  String initUrl = 'https://bing.com';
  late PlatformWebView platformWebView;

  PlatformWebViewWidget({super.key}) {
    platformWebView = buildWebView();
  }

  @override
  State createState() => _PlatformWebViewWidgetState();

  PlatformWebView buildWebView() {
    return PlatformWebView(
        initialUrl: initUrl,
        onWebViewCreated: (PlatformWebViewController controller) {
          platformWebViewController = controller;
        });
  }

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
  final urlTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    urlTextController.text = widget.initUrl;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: widget.title,
      withLeading: true,
      child: Column(children: <Widget>[
        buildTextField(),
        Expanded(
          child: widget.platformWebView,
        ),
      ]),
    );
  }

  Widget buildTextField() {
    return Row(children: [
      const SizedBox(
        width: 10,
      ),
      InkWell(
        child: const Icon(Icons.arrow_back),
        onTap: () {
          widget.platformWebViewController.goBack();
        },
      ),
      const SizedBox(
        width: 10,
      ),
      InkWell(
        child: const Icon(Icons.arrow_forward),
        onTap: () {
          widget.platformWebViewController.goForward();
        },
      ),
      const SizedBox(
        width: 10,
      ),
      InkWell(
        child: const Icon(Icons.refresh),
        onTap: () {
          widget.platformWebViewController.reload();
        },
      ),
      const SizedBox(
        width: 10,
      ),
      Expanded(
          child: TextFormField(
        autofocus: true,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.http),
        ),
        controller: urlTextController,
        keyboardType: TextInputType.url,
        onFieldSubmitted: (String url) {
          //String url = urlController.text;
          if (!url.startsWith('http')) {
            url = 'https://$url';
          }
          widget.platformWebViewController.load(url);
        },
      )),
    ]);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
