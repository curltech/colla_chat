import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/platform_webview.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

///基于WebView实现的媒体播放器和记录器，
class WebViewVideoPlayerController extends AbstractMediaPlayerController {
  PlatformWebViewController? controller;

  WebViewVideoPlayerController() {
    fileType = FileType.media;
  }

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
      return Center(
          child: CommonAutoSizeText(
        AppLocalizations.t('Please select a media file'),
        style: const TextStyle(color: Colors.white),
      ));
    }
    var platformWebView = PlatformWebView(
      key: key,
      initialUrl: currentMediaSource!.filename,
      onWebViewCreated: _onWebViewCreated,
    );
    return platformWebView;
  }
}
