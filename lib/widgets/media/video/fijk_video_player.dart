import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///基于fijk实现的媒体播放器和记录器，
class FijkVideoPlayerController extends AbstractMediaPlayerController {
  final FijkPlayer player = FijkPlayer();
  double volume = 1.0;
  double speed = 1.0;

  FijkVideoPlayerController();

  _open({bool autoStart = false}) {}

  @override
  PlayerStatus get status {
    FijkState state = player.state;
    if (state == FijkState.started) {
      return PlayerStatus.playing;
    }
    if (player.isBuffering) {
      return PlayerStatus.buffering;
    }
    if (state == FijkState.completed) {
      return PlayerStatus.completed;
    }
    if (state == FijkState.initialized) {
      return PlayerStatus.init;
    }

    return PlayerStatus.stop;
  }

  ///基本的视频控制功能
  @override
  play() {
    var dataSource = player.dataSource;
    if (dataSource == null && currentMediaSource != null) {
      player.setDataSource(currentMediaSource!.filename);
    }
    player.start();
  }

  @override
  seek(Duration position, {int? index}) {
    player.seekTo(position.inMicroseconds);
  }

  @override
  pause() {
    player.pause();
  }

  @override
  resume() {
    player.start();
  }

  @override
  stop() {
    player.stop();
  }

  @override
  Future<Duration?> getBufferedPosition() {
    return Future.value(player.bufferPos);
  }

  @override
  Future<Duration?> getDuration() {
    return Future.value(player.value.duration);
  }

  @override
  Future<Duration?> getPosition() {
    return Future.value(player.currentPos);
  }

  @override
  Future<double> getSpeed() {
    return Future.value(speed);
  }

  @override
  Future<double> getVolume() {
    return Future.value(volume);
  }

  @override
  setVolume(double volume) {
    player.setVolume(volume);
    this.volume = volume;
  }

  @override
  setSpeed(double speed) {
    player.setSpeed(speed);
    this.speed = speed;
  }

  Future<Uint8List> takeSnapshot(
    String filename,
    int width,
    int height,
  ) async {
    return await player.takeSnapShot();
  }

  @override
  dispose() {
    super.dispose();
    player.dispose();
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
    //FijkFit fit = FijkFit.contain,
    FijkFit fsFit = FijkFit.contain,
    Widget Function(FijkPlayer, FijkData, BuildContext, Size, Rect)
        panelBuilder = defaultFijkPanelBuilder,
    Color color = const Color(0xFF607D8B),
    ImageProvider<Object>? cover,
    bool fs = true,
    void Function(FijkData)? onDispose,
  }) {
    return FijkView(
        player: player,
        width: width,
        height: height,
        fit: FijkFit.contain,
        fsFit: fsFit,
        panelBuilder: panelBuilder,
        color: color,
        cover: cover,
        fs: fs,
        onDispose: onDispose);
  }

  @override
  setShuffleModeEnabled(bool enabled) {}

  @override
  close() {}
}
