import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/platform_webview.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

///基于WebView实现的媒体播放器和记录器，
class WebViewVideoPlayerController extends AbstractMediaPlayerController {
  PlatformWebViewController? platformWebViewController;

  WebViewVideoPlayerController() {
    fileType = FileType.any;
    allowedExtensions = ['mp3', 'wav', 'mp4', 'm4a', 'mov', 'mpeg', 'aac'];
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

  _play() {
    var currentMediaSource = this.currentMediaSource;
    if (platformWebViewController != null && currentMediaSource != null) {
      platformWebViewController!.load(currentMediaSource.filename);
      // String html = getMediaHtml(currentMediaSource.filename);
      // platformWebViewController!.loadHtml(html);
    }
  }

  void _onWebViewCreated(PlatformWebViewController platformWebViewController) {
    this.platformWebViewController = platformWebViewController;
    _play();
  }

  @override
  setCurrentIndex(int index) async {
    if (index >= -1 && index < playlist.length && currentIndex != index) {
      close();
      await super.setCurrentIndex(index);
      if (platformWebViewController != null) {
        _play();
      }
      notifyListeners();
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
    if (currentMediaSource != null) {
      initialFilename = currentMediaSource!.filename;
    }
    var platformWebView = PlatformWebView(
      key: key,
      initialFilename: initialFilename,
      onWebViewCreated: _onWebViewCreated,
    );
    return platformWebView;
  }

  @override
  close() {
    super.setCurrentIndex(-1);
  }
}
