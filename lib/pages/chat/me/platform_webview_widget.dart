import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/platform_webview.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

class PlatformWebViewWidget extends StatefulWidget with TileDataMixin {
  PlatformWebViewWidget({super.key});

  @override
  State createState() => _PlatformWebViewWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'webView';

  @override
  IconData get iconData => Icons.web;

  @override
  String get title => 'WebView';
}

class _PlatformWebViewWidgetState extends State<PlatformWebViewWidget> {
  final urlTextController = TextEditingController();

  PlatformWebViewController? platformWebViewController;

  bool fullScreen = false;

  @override
  void initState() {
    super.initState();
  }

  Widget buildTextField() {
    return Row(children: [
      const SizedBox(
        width: 10,
      ),
      InkWell(
        child: const Icon(Icons.arrow_back),
        onTap: () {
          platformWebViewController?.goBack();
        },
      ),
      const SizedBox(
        width: 10,
      ),
      InkWell(
        child: const Icon(Icons.arrow_forward),
        onTap: () {
          platformWebViewController?.goForward();
        },
      ),
      const SizedBox(
        width: 10,
      ),
      InkWell(
        child: const Icon(Icons.refresh),
        onTap: () {
          platformWebViewController?.reload();
        },
      ),
      const SizedBox(
        width: 10,
      ),
      Expanded(
          child: CommonAutoSizeTextFormField(
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
          platformWebViewController?.load(url);
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
      buildTextField(),
      Expanded(child: PlatformWebView(
          onWebViewCreated: (PlatformWebViewController controller) {
        platformWebViewController = controller;
      }))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: widget.title,
      withLeading: true,
      child: buildWebView(context),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
