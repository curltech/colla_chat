import 'dart:io';
import 'package:colla_chat/widgets/common/mobile_webview.dart';
import 'package:universal_html/html.dart' as html;
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flick_video_player/src/utils/web_key_bindings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

///基于flick实现的媒体播放器和记录器，
class WebviewVideoPlayerController extends AbstractMediaPlayerController {
  WebViewController? controller;

  WebviewVideoPlayerController();

  @override
  next() {
    stop();
    super.next();
    play();
  }

  @override
  previous() {
    stop();
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

  @override
  Widget buildMediaView({
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
    var mobileWebView = MobileWebView(
      initialUrl: currentMediaSource!.filename,
      onWebViewCreated: _onWebViewCreated,
    );
    return mobileWebView;
  }

  void _onWebViewCreated(WebViewController controller) {
    this.controller = controller;
  }

  @override
  setShuffleModeEnabled(bool enabled) {}

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
      controller!.loadFile(currentMediaSource!.filename);
    }
  }

  @override
  resume() {}

  @override
  seek(Duration position, {int? index}) {}

  @override
  stop() {}
}
