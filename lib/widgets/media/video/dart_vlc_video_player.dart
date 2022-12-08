import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart'
    as platform;
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class DartVlcMediaSource {
  static Media media({required String filename}) {
    Media media;
    if (filename.startsWith('assets/')) {
      media = Media.asset(filename);
    } else if (filename.startsWith('http')) {
      media = Media.network(filename);
    } else {
      media = Media.file(File(filename));
    }

    return media;
  }

  static Playlist fromMediaSource(
      List<platform.PlatformMediaSource> mediaSources) {
    List<Media> medias = [];
    for (var mediaSource in mediaSources) {
      medias.add(media(filename: mediaSource.filename));
    }
    final playlist = Playlist(
      medias: medias,
    );

    return playlist;
  }
}

///基于dart_vlc实现的媒体播放器和记录器，可以截取视频文件的图片作为缩略图
///支持Windows & Linux，linux需要VLC & libVLC installed.
class DartVlcVideoPlayerController extends AbstractMediaPlayerController {
  late Player player;
  CurrentState? currentState;
  PositionState? positionState;
  PlaybackState? playbackState;
  GeneralState? generalState;
  VideoDimensions? videoDimensions;
  double bufferingProgress = 0.0;
  List<Device> devices = [];

  DartVlcVideoPlayerController({
    int id = 0,
    bool registerTexture = true,
    VideoDimensions? videoDimensions = const VideoDimensions(640, 360),
    List<String>? commandlineArguments,
    dynamic bool = false,
  }) {
    DartVLC.initialize();
    devices = Devices.all;
    player = Player(
      id: id,
      videoDimensions: videoDimensions,
      commandlineArguments: commandlineArguments,
    );
    player.currentStream.listen((currentState) {
      this.currentState = currentState;
    });
    player.positionStream.listen((positionState) {
      this.positionState = positionState;
    });
    player.playbackStream.listen((playbackState) {
      this.playbackState = playbackState;
      if (playbackState.isPlaying) {
      } else if (playbackState.isCompleted) {}
      if (this.playbackState != null && this.playbackState!.isCompleted) {
        playlistVisible = true;
      }
      if (this.playbackState != null && this.playbackState!.isPlaying) {
        playlistVisible = false;
      }
    });
    player.generalStream.listen((generalState) {
      this.generalState = generalState;
    });
    player.videoDimensionsStream.listen((videoDimensions) {
      this.videoDimensions = videoDimensions;
    });
    player.bufferingProgressStream.listen(
      (bufferingProgress) {
        this.bufferingProgress = bufferingProgress;
      },
    );
    player.errorStream.listen((event) {
      logger.e('libvlc error:$event');
    });
    _open();
  }

  _open({bool autoStart = false}) {
    Playlist list = DartVlcMediaSource.fromMediaSource(playlist);
    player.open(
      list,
      autoStart: autoStart,
    );
  }

  @override
  setCurrentIndex(int index) async {
    if (index >= -1 && index < playlist.length && currentIndex != index) {
      await super.setCurrentIndex(index);
      notifyListeners();
      player.jumpToIndex(currentIndex);
    }
  }

  ///下面是播放列表的功能
  @override
  Future<platform.PlatformMediaSource?> add({required String filename}) async {
    platform.PlatformMediaSource? mediaSource =
        await super.add(filename: filename);
    if (mediaSource != null) {
      Media media = DartVlcMediaSource.media(filename: mediaSource.filename);
      player.add(media);
    }

    return mediaSource;
  }

  @override
  remove(int index) {
    super.remove(index);
    player.remove(index);
  }

  @override
  Future<platform.PlatformMediaSource?> insert(int index,
      {required String filename}) async {
    platform.PlatformMediaSource? mediaSource =
        await super.insert(index, filename: filename);
    if (mediaSource != null) {
      Media media = DartVlcMediaSource.media(filename: mediaSource.filename);
      player.insert(index, media);
    }
    return mediaSource;
  }

  @override
  next() {
    player.next();
    super.next();
  }

  @override
  previous() {
    player.previous();
    super.previous();
  }

  @override
  move(int initialIndex, int finalIndex) {
    player.move(initialIndex, finalIndex);
    super.move(initialIndex, finalIndex);
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    return Video(
      key: key,
      player: player,
    );
  }

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  play() {
    player.play();
  }

  pause() {
    player.pause();
  }

  resume() {
    player.play();
  }

  stop() {
    player.stop();
    playlistVisible = true;
  }

  seek(Duration position, {int? index}) {
    player.seek(position);
  }

  Future<double> getSpeed() {
    return Future.value(player.general.rate);
  }

  setSpeed(double speed) {
    player.setRate(speed);
  }

  Future<double> getVolume() async {
    return Future.value(player.general.volume);
  }

  setVolume(double volume) {
    player.setVolume(volume);
  }

  ///以下是视频播放器特有的方法
  takeSnapshot(
    String filename,
    int width,
    int height,
  ) {
    var file = File(filename);
    player.takeSnapshot(file, width, height);
  }

  Stream<PositionData> get positionDataStream {
    return Rx.combineLatest3<PositionState, double, GeneralState, PositionData>(
        player.positionStream,
        player.bufferingProgressStream,
        player.generalStream, (positionState, bufferingProgress, generalState) {
      Duration position = positionState.position!;
      Duration bufferedPosition =
          Duration(milliseconds: bufferingProgress.toInt());
      Duration duration = positionState.duration!;
      return PositionData(
          position, bufferedPosition, duration ?? Duration.zero);
    });
  }

  setEqualizer({double? band, double? preAmp, double? amp}) {
    Equalizer equalizer = Equalizer.createEmpty();
    if (preAmp != null) {
      equalizer.setPreAmp(preAmp);
    }
    if (band != null && amp != null) {
      equalizer.setBandAmp(band, amp);
    }
    player.setEqualizer(equalizer);
  }

  Broadcast broadcast({
    required int id,
    required Media media,
    required BroadcastConfiguration configuration,
  }) {
    final broadcast = Broadcast.create(
      id: 0,
      media: Media.file(File('C:/video.mp4')),
      configuration: const BroadcastConfiguration(
        access: 'http',
        mux: 'mpeg1',
        dst: '127.0.0.1:8080',
        vcodec: 'mp1v',
        vb: 1024,
        acodec: 'mpga',
        ab: 128,
      ),
    );
    broadcast.start();
    broadcast.dispose();
    return broadcast;
  }
}

class DartVlcMediaRecorder {
  Record? record;

  DartVlcMediaRecorder();

  start({
    int id = 0,
    required String filename,
    required File savingFile,
  }) async {
    if (record != null) {
      dispose();
    }
    Media media = await DartVlcMediaSource.media(filename: filename);
    record = Record.create(
      id: id,
      media: media,
      savingFile: savingFile,
    );
    record!.start();
  }

  dispose() {
    if (record != null) {
      record!.dispose();
      record = null;
    }
  }
}
