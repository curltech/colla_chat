import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/webview/platform_webview.dart';
import 'package:flutter/material.dart';

///基于WebView实现的媒体播放器和记录器，
class WebViewVideoPlayerController extends AbstractMediaPlayerController {
  PlatformWebViewController? platformWebViewController;

  WebViewVideoPlayerController(super.playlistController);

  String getMediaHtml(String filename, {bool autoplay = false}) {
    String autoplayStr = autoplay ? 'autoplay' : '';
    String? typeTag = FileUtil.mimeType(filename);
    String? mediaTag = 'video';
    if (typeTag != null &&
        (typeTag.endsWith('mp3') || typeTag.endsWith('wav'))) {
      mediaTag = 'audio';
    }
    String html =
        '<p align=center><$mediaTag controls="controls" $autoplayStr><source src="file:///$filename" type="$typeTag"></$mediaTag></p>';

    return html;
  }

  void _onWebViewCreated(PlatformWebViewController platformWebViewController) {
    this.platformWebViewController = platformWebViewController;
    // play();
  }

  @override
  Future<void> playMediaSource(PlatformMediaSource mediaSource) async {
    if (autoplay && platformWebViewController != null) {
      platformWebViewController!.load(mediaSource.filename);
    }
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    String? initialFilename;
    var currentMediaSource = playlistController.current;
    if (currentMediaSource != null) {
      initialFilename = currentMediaSource.filename;
    }
    var platformWebView = PlatformWebView(
      key: key,
      initialFilename: initialFilename,
      onWebViewCreated: _onWebViewCreated,
    );
    return platformWebView;
  }

  @override
  close() {}

  @override
  pause() {}

  @override
  resume() {}

  @override
  stop() {}
}
