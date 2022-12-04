import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/media_player_slider.dart';
import 'package:colla_chat/widgets/media/abstract_media_controller.dart'
    as platform;
import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player_util.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:visibility_detector/visibility_detector.dart';

class DartVlcMediaSource {
  static Future<Media> media({String? filename, List<int>? data}) async {
    Media media;
    if (filename != null) {
      if (filename.startsWith('assets/')) {
        media = Media.asset(filename);
      } else if (filename.startsWith('http')) {
        media = Media.network(filename);
      } else {
        media = Media.file(File(filename));
      }
    } else {
      data = data ?? Uint8List.fromList([]);
      filename = await FileUtil.writeTempFile(data);
      media = Media.file(File(filename!));
    }

    return media;
  }

  static Future<Playlist> fromMediaSource(
      List<platform.PlatformMediaSource> mediaSources) async {
    List<Media> medias = [];
    for (var mediaSource in mediaSources) {
      medias.add(await media(filename: mediaSource.filename));
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
      notifyListeners();
    });
    player.positionStream.listen((positionState) {
      this.positionState = positionState;
      notifyListeners();
    });
    player.playbackStream.listen((playbackState) {
      this.playbackState = playbackState;
      if (playbackState.isPlaying) {
        status = PlayerStatus.playing;
      } else if (playbackState.isCompleted) {
        status = PlayerStatus.completed;
      }
      if (this.playbackState != null && this.playbackState!.isCompleted) {
        playlistVisible = true;
      }
      if (this.playbackState != null && this.playbackState!.isPlaying) {
        playlistVisible = false;
      }
      notifyListeners();
    });
    player.generalStream.listen((generalState) {
      this.generalState = generalState;
      notifyListeners();
    });
    player.videoDimensionsStream.listen((videoDimensions) {
      this.videoDimensions = videoDimensions;
      notifyListeners();
    });
    player.bufferingProgressStream.listen(
      (bufferingProgress) {
        this.bufferingProgress = bufferingProgress;
        notifyListeners();
      },
    );
    player.errorStream.listen((event) {
      logger.e('libvlc error:$event');
    });
    _open();
  }

  _open({bool autoStart = false}) async {
    Playlist list = await DartVlcMediaSource.fromMediaSource(playlist);
    player.open(
      list,
      autoStart: autoStart,
    );
  }

  ///基本的视频控制功能
  @override
  play() {
    player.play();
  }

  @override
  pause() {
    player.pause();
    status = PlayerStatus.pause;
  }

  @override
  resume() {
    player.play();
  }

  @override
  stop() {
    player.stop();
    playlistVisible = true;
  }

  @override
  seek(Duration position, {int? index}) {
    player.seek(position);
  }

  @override
  setVolume(double volume) {
    player.setVolume(volume);
  }

  @override
  setSpeed(double speed) {
    player.setRate(speed);
  }

  @override
  Future<double> getSpeed() {
    return Future.value(player.general.rate);
  }

  @override
  Future<double> getVolume() async {
    return Future.value(player.general.volume);
  }

  @override
  setCurrentIndex(int? index) async {
    super.setCurrentIndex(index);
    if (currentIndex != null) {
      player.jumpToIndex(currentIndex!);
    }
  }

  ///下面是播放列表的功能
  @override
  Future<platform.PlatformMediaSource?> add(
      {String? filename, List<int>? data}) async {
    platform.PlatformMediaSource? mediaSource =
        await super.add(filename: filename, data: data);
    if (mediaSource != null) {
      Media media =
          await DartVlcMediaSource.media(filename: mediaSource.filename);
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
      {String? filename, List<int>? data}) async {
    platform.PlatformMediaSource? mediaSource =
        await super.insert(index, filename: filename, data: data);
    if (mediaSource != null) {
      Media media =
          await DartVlcMediaSource.media(filename: mediaSource.filename);
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
  Future<Duration?> getBufferedPosition() {
    double progress = player.bufferingProgress;

    return Future<Duration?>.value(Duration(milliseconds: progress.toInt()));
  }

  @override
  Future<Duration?> getDuration() {
    return Future<Duration?>.value(player.position.duration);
  }

  @override
  Future<Duration?> getPosition() {
    return Future<Duration?>.value(player.position.position);
  }

  @override
  setShuffleModeEnabled(bool enabled) {
    throw UnimplementedError();
  }

  @override
  dispose() {
    super.dispose();
    close();
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

  @override
  Widget buildMediaView({
    Key? key,
    Player? player,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    double scale = 1.0,
    bool showControls = true,
    Color? progressBarActiveColor,
    Color? progressBarInactiveColor = Colors.white24,
    Color? progressBarThumbColor,
    Color? progressBarThumbGlowColor = const Color.fromRGBO(0, 161, 214, .2),
    Color? volumeActiveColor,
    Color? volumeInactiveColor = Colors.grey,
    Color volumeBackgroundColor = const Color(0xff424242),
    Color? volumeThumbColor,
    double? progressBarThumbRadius = 10.0,
    double? progressBarThumbGlowRadius = 15.0,
    bool showTimeLeft = false,
    TextStyle progressBarTextStyle = const TextStyle(),
    FilterQuality filterQuality = FilterQuality.low,
    Color fillColor = Colors.black,
  }) {
    player = player ?? this.player;
    return Video(
      key: key,
      player: player,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      scale: scale,
      showControls: showControls,
      progressBarActiveColor: progressBarActiveColor,
      progressBarInactiveColor: progressBarInactiveColor,
      progressBarThumbColor: progressBarThumbColor,
      progressBarThumbGlowColor: progressBarThumbGlowColor,
      volumeActiveColor: volumeActiveColor,
      volumeInactiveColor: volumeInactiveColor,
      volumeBackgroundColor: volumeBackgroundColor,
      volumeThumbColor: volumeThumbColor,
      progressBarThumbRadius: progressBarThumbRadius,
      progressBarThumbGlowRadius: progressBarThumbGlowRadius,
      showTimeLeft: showTimeLeft,
      progressBarTextStyle: progressBarTextStyle,
      filterQuality: filterQuality,
      fillColor: fillColor,
    );
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

  @override
  close() {
    player.dispose();
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

class DartVlcVideoPlayer extends StatefulWidget {
  late final DartVlcVideoPlayerController controller;

  final int id;

  ///是否显示内置控件
  final bool showControls;

  ///如果是外置控件，是否显示简洁版
  final bool showVolume;
  final bool showSpeed;

  //是否显示播放列表和媒体视图
  final bool showPlaylist;
  final bool showMediaView;

  final Color? color;
  final double? height;
  final double? width;
  final String? filename;
  final List<int>? data;

  DartVlcVideoPlayer(
      {Key? key,
      DartVlcVideoPlayerController? controller,
      required this.id,
      this.showVolume = true,
      this.showSpeed = false,
      this.showControls = true,
      this.showPlaylist = true,
      this.showMediaView = true,
      this.color,
      this.width,
      this.height,
      this.filename,
      this.data})
      : super(key: key) {
    this.controller = controller ?? DartVlcVideoPlayerController(id: id);
  }

  @override
  State createState() => _DartVlcVideoPlayerState();
}

class _DartVlcVideoPlayerState extends State<DartVlcVideoPlayer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
    if (widget.filename != null || widget.data != null) {
      widget.controller.add(filename: widget.filename, data: widget.data);
    }
  }

  _update() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AbstractMediaPlayerController controller = widget.controller;
    List<Widget> columns = [];
    List<Widget> rows = [];
    if (widget.showMediaView) {
      rows.add(PlatformMediaPlayerUtil.buildMediaView(
          controller: controller,
          color: widget.color,
          width: widget.width,
          height: widget.height,
          showControls: widget.showControls));
    }
    if (widget.showPlaylist) {
      rows.add(Visibility(
          visible: controller.playlistVisible,
          child: PlatformMediaPlayerUtil.buildPlaylist(context, controller)));
    }
    if (rows.isNotEmpty) {
      var view = VisibilityDetector(
          key: ObjectKey(controller),
          onVisibilityChanged: (visiblityInfo) {
            if (visiblityInfo.visibleFraction > 0.9 && controller.autoPlay) {
              controller.play();
            }
          },
          child: Stack(children: rows));
      columns.add(Expanded(child: view));
    }
    if (!widget.showControls) {
      Widget controllerPanel = DartVlcControllerPanel(
        controller: widget.controller,
        showVolume: widget.showVolume,
        showSpeed: widget.showSpeed,
        showPlaylist: widget.showPlaylist,
      );
      columns.add(Expanded(child: controllerPanel));
    }
    return Column(children: columns);
  }
}

///视频播放器的控制面板
class DartVlcControllerPanel extends StatefulWidget {
  late final DartVlcVideoPlayerController controller;

  ///如果是外置控件，是否显示简洁版
  final bool showVolume;
  final bool showSpeed;
  final bool showPlaylist;

  DartVlcControllerPanel({
    Key? key,
    DartVlcVideoPlayerController? controller,
    this.showVolume = true,
    this.showSpeed = false,
    this.showPlaylist = true,
  }) : super(key: key) {
    this.controller = controller ?? DartVlcVideoPlayerController();
  }

  @override
  State createState() => _DartVlcControllerPanelState();
}

class _DartVlcControllerPanelState extends State<DartVlcControllerPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget controllerPanel = _buildControllerPanel(context);

    return controllerPanel;
  }

  ///简单播放控制面板，包含音量，简单播放按钮，
  Widget _buildControlPanel(BuildContext buildContext) {
    List<Widget> rows = [];
    if (widget.showPlaylist) {
      rows.add(PlatformMediaPlayerUtil.buildPlaylistVisibleButton(
          context, widget.controller));
    }
    if (widget.showVolume) {
      rows.add(StreamBuilder<GeneralState>(
        stream: widget.controller.player.generalStream,
        builder: (context, snapshot) {
          return PlatformMediaPlayerUtil.buildVolumeButton(
              context, widget.controller);
        },
      ));
    }
    rows.add(StreamBuilder<PlaybackState>(
        stream: widget.controller.player.playbackStream,
        builder: (context, snapshot) {
          PlaybackState? playerState = snapshot.data;
          PlayerStatus status;
          if (playerState == null) {
            status = PlayerStatus.init;
          } else if (playerState.isPlaying) {
            status = PlayerStatus.playing;
          } else if (playerState.isCompleted) {
            status = PlayerStatus.completed;
          } else {
            status = widget.controller.status;
          }
          Widget playback = PlatformMediaPlayerUtil.buildPlaybackButton(
              context, widget.controller, status, widget.showPlaylist);

          return playback;
        }));
    if (widget.showSpeed) {
      rows.add(StreamBuilder<GeneralState>(
        stream: widget.controller.player.generalStream,
        builder: (context, snapshot) {
          return PlatformMediaPlayerUtil.buildSpeedButton(
              context, widget.controller);
        },
      ));
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: rows);
  }

  ///播放进度条
  Widget _buildPlayerSlider(BuildContext context) {
    return StreamBuilder<PositionState>(
      stream: widget.controller.player.positionStream,
      builder: (context, snapshot) {
        PositionState? positionData = snapshot.data;
        return MediaPlayerSlider(
          duration: positionData?.duration ?? Duration.zero,
          position: positionData?.position ?? Duration.zero,
          bufferedPosition: Duration.zero,
          onChangeEnd: widget.controller.seek,
        );
      },
    );
  }

  ///复杂控制器按钮面板，包含音量，速度和播放按钮
  Widget _buildControllerPanel(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPlayerSlider(context),
        _buildControlPanel(context),
      ],
    );
  }
}
