import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

/// 不支持Windows和linux
class MobileInAppWebView extends StatefulWidget {
  final String initialUrl;
  final void Function(InAppWebViewController)? onWebViewCreated;

  const MobileInAppWebView(
      {super.key, required this.initialUrl, this.onWebViewCreated});

  @override
  State createState() => _MobileInAppWebViewState();
}

class _MobileInAppWebViewState extends State<MobileInAppWebView> {
  InAppWebViewSettings settings = InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  PullToRefreshController? pullToRefreshController;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      withLeading: true,
      child: buildInAppWebView(),
    );
  }

  InAppWebView buildInAppWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
      initialSettings: settings,
      onWebViewCreated: widget.onWebViewCreated,
      onPermissionRequest: (controller, request) async {
        return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT);
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
