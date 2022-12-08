import 'package:colla_chat/widgets/common/platform_webview.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:flutter/material.dart';

///基于WebView实现的媒体播放器和记录器，
class WebViewVideoPlayerController extends AbstractMediaPlayerController {
  PlatformWebViewController? controller;

  WebViewVideoPlayerController();

  @override
  next() {
    super.next();
    _play();
  }

  @override
  previous() {
    super.previous();
    _play();
  }

  _play() {
    var currentMediaSource = this.currentMediaSource;
    if (controller != null && currentMediaSource != null) {
      controller!.load(currentMediaSource.filename);
    }
  }

  void _onWebViewCreated(PlatformWebViewController controller) {
    this.controller = controller;
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    if (currentMediaSource == null) {
      return const Center(child: Text('Please select a MediaPlayerType!'));
    }
    var platformWebView = PlatformWebView(
      key: key,
      initialUrl: currentMediaSource!.filename,
      onWebViewCreated: _onWebViewCreated,
    );
    return platformWebView;
  }
}
