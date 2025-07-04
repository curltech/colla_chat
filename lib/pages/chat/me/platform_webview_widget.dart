import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/webview/platform_webview.dart';
import 'package:flutter/material.dart';

class PlatformWebViewWidget extends StatelessWidget with TileDataMixin {
  PlatformWebViewWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'webView';

  @override
  IconData get iconData => Icons.web;

  @override
  String get title => 'WebView';

  late final urlTextController = TextEditingController(text: initialUrl);

  final PlatformWebViewController platformWebViewController =
      PlatformWebViewController();

  bool fullScreen = false;

  final String initialUrl = 'http://43.135.164.104/';

  Widget buildTextField(BuildContext context) {
    return Row(children: [
      const SizedBox(
        width: 10,
      ),
      InkWell(
        child: const Icon(Icons.arrow_back),
        onTap: () {
          platformWebViewController.goBack();
        },
      ),
      const SizedBox(
        width: 10,
      ),
      InkWell(
        child: const Icon(Icons.arrow_forward),
        onTap: () {
          platformWebViewController.goForward();
        },
      ),
      const SizedBox(
        width: 10,
      ),
      InkWell(
        child: const Icon(Icons.refresh),
        onTap: () {
          platformWebViewController.reload();
        },
      ),
      const SizedBox(
        width: 10,
      ),
      Expanded(
          child: TextFormField(
        //prefixIcon: const Icon(Icons.http),
        controller: urlTextController,
        keyboardType: TextInputType.url,
        onFieldSubmitted: (String url) {
          String second = url.substring(1, 2);
          if (!url.startsWith('http') &&
              !url.startsWith('file') &&
              !url.startsWith('/') &&
              second != ':') {
            url = 'https://$url';
            urlTextController.text = url;
          }
          platformWebViewController.load(url);
        },
      )),
      const SizedBox(
        width: 10,
      ),
      InkWell(
        child: fullScreen
            ? const Icon(Icons.fullscreen_exit)
            : const Icon(Icons.fullscreen),
        onTap: () async {
          if (fullScreen) {
            fullScreen = false;
            Navigator.pop(context);
          } else {
            fullScreen = true;
            await DialogUtil.show(
                context: context,
                builder: (context) {
                  return Dialog.fullscreen(child: buildWebView(context));
                });
          }
        },
      ),
    ]);
  }

  Widget buildWebView(BuildContext context) {
    return Column(children: <Widget>[
      buildTextField(context),
      Expanded(
          child: PlatformWebView(
              initialUrl: initialUrl,
              webViewController: platformWebViewController))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title,
        helpPath: routeName,
        withLeading: true,
        child: buildWebView(context));
  }
}
