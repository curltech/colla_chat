import 'package:colla_chat/widgets/common/platform_webview.dart';
import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:flutter/material.dart';

///基于WebView实现的媒体播放器和记录器，
class WebViewVideoPlayerController extends AbstractMediaPlayerController {
  PlatformWebViewController? controller;

  WebViewVideoPlayerController();

  @override
  next() {
    super.next();
    play();
  }

  @override
  previous() {
    super.previous();
    play();
  }

  takeSnapshot(
    String filename,
    int width,
    int height,
  ) {}

  @override
  dispose() {
    super.dispose();
    close();
  }

  void _onWebViewCreated(PlatformWebViewController controller) {
    this.controller = controller;
  }

  @override
  close() {
    playlist.clear();
  }

  @override
  Future<Duration?> getBufferedPosition() async {
    if (currentMediaSource != null) {
      return Future.value(const Duration(seconds: 0));
    }
    return null;
  }

  @override
  Future<Duration?> getDuration() async {
    if (currentMediaSource != null) {
      return Future.value(const Duration(seconds: 0));
    }
    return null;
  }

  @override
  Future<Duration?> getPosition() async {
    if (currentMediaSource != null) {
      return Future.value(const Duration(seconds: 0));
    }
    return null;
  }

  @override
  Future<double> getSpeed() {
    double speed = 1.0;
    if (currentMediaSource != null) {}
    return Future.value(speed);
  }

  @override
  Future<double> getVolume() {
    double volume = 1.0;
    if (currentMediaSource != null) {}
    return Future.value(volume);
  }

  @override
  setVolume(double volume) {
    if (currentMediaSource != null) {}
  }

  @override
  setSpeed(double speed) {
    if (currentMediaSource != null) {}
  }

  @override
  pause() {}

  @override
  play() {
    if (controller != null && currentMediaSource != null) {
      controller!.load(currentMediaSource!.filename);
      status = PlayerStatus.playing;
    }
  }

  @override
  resume() {}

  @override
  seek(Duration position, {int? index}) {}

  @override
  stop() {
    if (controller != null && currentMediaSource != null) {
      controller!.load('');
      status = PlayerStatus.stop;
    }
  }

  @override
  Widget buildMediaView({
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    double scale = 1.0,
    bool showControls = true,
  }) {
    if (currentMediaSource == null) {
      return const Center(child: Text('Please select a MediaPlayerType!'));
    }
    key ??= UniqueKey();
    var platformWebView = PlatformWebView(
      key: key,
      initialUrl: currentMediaSource!.filename,
      onWebViewCreated: _onWebViewCreated,
    );
    return platformWebView;
  }
}
