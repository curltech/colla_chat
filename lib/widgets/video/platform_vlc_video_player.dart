import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/audio/platform_audio_player.dart';
import 'package:colla_chat/widgets/common/media_player_slider.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rxdart/rxdart.dart';

class VlcMediaSource {
  static Future<Media> media({String? filename, Uint8List? data}) async {
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
      filename = await FileUtil.writeTempFile(data, '');
      media = Media.file(File(filename));
    }

    return media;
  }

  static Future<Playlist> playlist(List<String> filenames) async {
    List<Media> medias = [];
    for (var filename in filenames) {
      medias.add(await media(filename: filename));
    }
    final playlist = Playlist(
      medias: medias,
    );

    return playlist;
  }
}

///基于vlc实现的媒体播放器和记录器，可以截取视频文件的图片作为缩略图
///支持Windows & Linux，linux需要VLC & libVLC installed.
class VlcVideoPlayerController extends AbstractMediaPlayerController {
  late Player player;
  final Playlist playlist = Playlist(medias: []);
  CurrentState? currentState;
  PositionState? positionState;

  PlaybackState? playbackState;

  GeneralState? generalState;

  VideoDimensions? videoDimensions;

  double bufferingProgress = 0.0;
  List<Media> medias = <Media>[];
  List<Device> devices = Devices.all;

  VlcVideoPlayerController({
    int id = 0,
    bool registerTexture = true,
    VideoDimensions? videoDimensions,
    List<String>? commandlineArguments,
    dynamic bool = false,
  }) {
    player = Player(
        id: id,
        registerTexture: !platformParams.windows,
        videoDimensions: videoDimensions,
        commandlineArguments: commandlineArguments,
        bool: bool);
    player.currentStream.listen((currentState) {
      this.currentState = currentState;
      logger.i('libvlc currentState:$currentState');
    });
    player.positionStream.listen((positionState) {
      this.positionState = positionState;
      //logger.i('libvlc positionState:$positionState');
    });
    player.playbackStream.listen((playbackState) {
      this.playbackState = playbackState;
      //logger.i('libvlc playbackState:$playbackState');
    });
    player.generalStream.listen((generalState) {
      this.generalState = generalState;
      logger.i('libvlc generalState:$generalState');
    });
    player.videoDimensionsStream.listen((videoDimensions) {
      this.videoDimensions = videoDimensions;
      logger.i('libvlc videoDimensions:$videoDimensions');
    });
    player.bufferingProgressStream.listen(
      (bufferingProgress) {
        this.bufferingProgress = bufferingProgress;
        //logger.i('libvlc bufferingProgress:$bufferingProgress');
      },
    );
    player.errorStream.listen((event) {
      logger.e('libvlc error:$event');
    });
    _open();
  }

  _open({bool autoStart = false}) {
    player.open(
      playlist,
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
  }

  @override
  resume() {
    player.play();
  }

  @override
  stop() {
    player.stop();
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
  double getSpeed() {
    return player.general.rate;
  }

  @override
  double getVolume() {
    return player.general.volume;
  }

  ///下面是播放列表的功能
  @override
  add({String? filename, Uint8List? data}) async {
    Media media = await VlcMediaSource.media(filename: filename, data: data);
    player.add(media);
  }

  @override
  remove(int index) {
    player.remove(index);
  }

  @override
  insert(int index, {String? filename, Uint8List? data}) async {
    Media media = await VlcMediaSource.media(filename: filename, data: data);
    player.insert(index, media);
  }

  @override
  next() {
    player.next();
  }

  @override
  previous() {
    player.previous();
  }

  @override
  int? currentIndex() {
    return player.current.index;
  }

  @override
  setCurrentIndex(int? index) {
    if (index != null) {
      player.jumpToIndex(index);
    }
  }

  @override
  move(int initialIndex, int finalIndex) {
    player.move(initialIndex, finalIndex);
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
    player.dispose();
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

  Video _buildVideoWidget({
    Key? key,
    int? playerId,
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
    bool showFullscreenButton = false,
    Color fillColor = Colors.black,
  }) {
    player = player ?? this.player;
    return Video(
      key: key,
      playerId: playerId,
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
      showFullscreenButton: showFullscreenButton,
      fillColor: fillColor,
    );
  }

  NativeVideo _buildNativeVideoWidget({
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
  }) {
    player = player ?? this.player;
    return NativeVideo(
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
    );
  }

  Widget buildVideoWidget({
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
    bool showFullscreenButton = false,
    Color fillColor = Colors.black,
  }) {
    if (platformParams.windows) {
      return _buildVideoWidget(
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
        // showFullscreenButton: showFullscreenButton,
        // fillColor: fillColor,
      );
    } else {
      return _buildVideoWidget();
    }
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

class VlcMediaRecorder {
  Record? record;

  VlcMediaRecorder();

  start({
    int id = 0,
    required String filename,
    required File savingFile,
  }) async {
    if (record != null) {
      dispose();
    }
    Media media = await VlcMediaSource.media(filename: filename);
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

class PlatformVlcVideoPlayer extends StatefulWidget {
  late final VlcVideoPlayerController controller;

  ///是否显示内置控件
  final bool showControls;

  ///如果是外置控件，是否显示简洁版
  final bool simple;

  PlatformVlcVideoPlayer(
      {Key? key,
      VlcVideoPlayerController? controller,
      this.simple = false,
      this.showControls = true})
      : super(key: key) {
    this.controller = controller ?? VlcVideoPlayerController();
  }

  @override
  State createState() => _PlatformVlcVideoPlayerState();
}

class _PlatformVlcVideoPlayerState extends State<PlatformVlcVideoPlayer> {
  bool playlistVisible = false;

  @override
  void initState() {
    super.initState();
  }

  _isTablet() {
    bool isTablet = false;
    final double devicePixelRatio = ui.window.devicePixelRatio;
    final double width = ui.window.physicalSize.width;
    final double height = ui.window.physicalSize.height;
    if (devicePixelRatio < 2 && (width >= 1000 || height >= 1000)) {
      isTablet = true;
    } else if (devicePixelRatio == 2 && (width >= 1920 || height >= 1920)) {
      isTablet = true;
    } else {
      isTablet = false;
    }

    return isTablet;
  }

  _isPhone() {
    bool isPhone = false;
    final double devicePixelRatio = ui.window.devicePixelRatio;
    final double width = ui.window.physicalSize.width;
    final double height = ui.window.physicalSize.height;
    if (devicePixelRatio < 2 && (width >= 1000 || height >= 1000)) {
      isPhone = false;
    } else if (devicePixelRatio == 2 && (width >= 1920 || height >= 1920)) {
      isPhone = false;
    } else {
      isPhone = true;
    }

    return isPhone;
  }

  ///显示播放列表按钮
  Widget _buildPlaylistVisibleButton(BuildContext context) {
    return Ink(
        child: InkWell(
      child: playlistVisible
          ? const Icon(Icons.visibility_off_rounded, size: 24)
          : const Icon(Icons.visibility_rounded, size: 24),
      onTap: () {
        setState(() {
          playlistVisible = !playlistVisible;
        });
      },
    ));
  }

  Widget _buildVideoView({Color? color, double? height, double? width}) {
    color = color ?? Colors.black.withOpacity(1);
    Widget container = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      height = height ?? constraints.maxHeight;
      width = width ?? constraints.maxWidth;
      return Center(
        child: Container(
          margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
          width: width,
          height: height,
          decoration: BoxDecoration(color: color),
          child: widget.controller.buildVideoWidget(
            player: widget.controller.player,
            height: height,
            width: width,
            fit: BoxFit.cover,
            showControls: widget.showControls,
          ),
        ),
      );
    });
    return container;
  }

  ///播放列表
  Widget _buildPlaylist(BuildContext context) {
    Playlist playlist = widget.controller.playlist;
    return Column(children: [
      Card(
        color: Colors.white.withOpacity(0.5),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 16.0, top: 16.0),
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Ink(
                    child: InkWell(
                      child: const Icon(Icons.add),
                      onTap: () async {
                        List<String> filenames = await FileUtil.pickFiles();
                        for (var filename in filenames) {
                          await widget.controller.add(filename: filename);
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 150.0,
              child: ReorderableListView(
                shrinkWrap: true,
                onReorder: (int initialIndex, int finalIndex) async {
                  if (finalIndex > playlist.medias.length) {
                    finalIndex = playlist.medias.length;
                  }
                  if (initialIndex < finalIndex) finalIndex--;
                  widget.controller.move(initialIndex, finalIndex);
                },
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: List.generate(
                  playlist.medias.length,
                  (int index) {
                    return ListTile(
                      key: Key(index.toString()),
                      leading: Text(
                        index.toString(),
                        style: const TextStyle(fontSize: 14.0),
                      ),
                      title: Text(
                        playlist.medias[index].resource,
                        style: const TextStyle(fontSize: 14.0),
                      ),
                    );
                  },
                  growable: true,
                ),
              ),
            ),
          ],
        ),
      ),
      const Spacer(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = _isTablet();
    bool isPhone = _isPhone();
    List<Widget> controls = [];
    controls.add(Expanded(child: _buildVideoView()));
    if (!widget.showControls) {
      Widget controllerPanel = PlatformVlcControllerPanel(
        controller: widget.controller,
        simple: widget.simple,
      );
      controls.add(controllerPanel);
    }
    return Stack(children: [
      Column(children: controls),
      Visibility(visible: playlistVisible, child: _buildPlaylist(context))
    ]);
  }
}

///视频播放器的控制面板
class PlatformVlcControllerPanel extends StatefulWidget {
  late final VlcVideoPlayerController controller;

  ///如果是外置控件，是否显示简洁版
  final bool simple;

  PlatformVlcControllerPanel({
    Key? key,
    VlcVideoPlayerController? controller,
    this.simple = false,
  }) : super(key: key) {
    this.controller = controller ?? VlcVideoPlayerController();
  }

  @override
  State createState() => _PlatformVlcControllerPanelState();
}

class _PlatformVlcControllerPanelState
    extends State<PlatformVlcControllerPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget controllerPanel;
    if (widget.simple) {
      controllerPanel = _buildSimpleControllerPanel(context);
    } else {
      controllerPanel = _buildComplexControllerPanel(context);
    }
    return controllerPanel;
  }

  ///简单播放控制面板，包含音量，简单播放按钮，
  Row _buildSimpleControlPanel(BuildContext buildContext) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<GeneralState>(
            stream: widget.controller.player.generalStream,
            builder: (context, snapshot) {
              var label = '${snapshot.data?.volume.toStringAsFixed(1)}';
              return _buildVolumeButton(context, label: label);
            },
          ),
          StreamBuilder<PlaybackState>(
              stream: widget.controller.player.playbackStream,
              builder: (context, snapshot) {
                PlaybackState? playerState = snapshot.data;
                List<Widget> widgets = [];
                if (!playerState!.isCompleted && !playerState.isPlaying) {
                  widgets.add(Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 24.0,
                    height: 24.0,
                    child: const CircularProgressIndicator(),
                  ));
                } else {
                  if (!playerState!.isPlaying) {
                    widgets.add(Ink(
                        child: InkWell(
                      onTap: widget.controller.play,
                      child: const Icon(Icons.play_arrow_rounded, size: 36),
                    )));
                  } else if (!playerState.isCompleted) {
                    widgets.add(Ink(
                        child: InkWell(
                      onTap: widget.controller.pause,
                      child: const Icon(Icons.pause, size: 36),
                    )));
                  } else {
                    widgets.add(Ink(
                        child: InkWell(
                      child: const Icon(Icons.replay, size: 36),
                      onTap: () => widget.controller.seek(Duration.zero),
                    )));
                  }
                }
                return Row(
                  children: widgets,
                );
              }),
        ]);
  }

  ///音量按钮
  Widget _buildVolumeButton(BuildContext context, {String? label}) {
    return Ink(
        child: InkWell(
      child: Row(children: [
        const Icon(Icons.volume_up_rounded, size: 24),
        Text(label ?? '')
      ]),
      onTap: () {
        MediaPlayerSliderUtil.showSliderDialog(
          context: context,
          title: "Adjust volume",
          divisions: 10,
          min: 0.0,
          max: 1.0,
          value: widget.controller.getVolume(),
          stream: widget.controller.player.generalStream,
          onChanged: widget.controller.setVolume,
        );
      },
    ));
  }

  ///速度按钮
  Widget _buildSpeedButton(BuildContext context, {String? label}) {
    return Ink(
        child: InkWell(
      child: Row(children: [
        const Icon(Icons.speed_rounded, size: 24),
        Text(label ?? '')
      ]),
      onTap: () {
        MediaPlayerSliderUtil.showSliderDialog(
          context: context,
          title: "Adjust speed",
          divisions: 10,
          min: 0.5,
          max: 1.5,
          value: widget.controller.getSpeed(),
          stream: widget.controller.player.generalStream,
          onChanged: widget.controller.setSpeed,
        );
      },
    ));
  }

  Widget _buildComplexControlPanel(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<GeneralState>(
          stream: widget.controller.player.generalStream,
          builder: (context, snapshot) {
            var label = '1.0';
            if (snapshot.data != null) {
              label = '${snapshot.data?.volume.toStringAsFixed(1)}';
            }
            return _buildVolumeButton(context, label: label);
          },
        ),
        const SizedBox(
          width: 25,
        ),
        _buildComplexPlayPanel(),
        const SizedBox(
          width: 25,
        ),
        StreamBuilder<GeneralState>(
          stream: widget.controller.player.generalStream,
          builder: (context, snapshot) {
            var label = '1.0';
            if (snapshot.data != null) {
              label = '${snapshot.data?.rate.toStringAsFixed(1)}';
            }
            return _buildSpeedButton(context, label: label);
          },
        ),
      ],
    );
  }

  ///复杂播放按钮面板
  StreamBuilder<PlaybackState> _buildComplexPlayPanel() {
    return StreamBuilder<PlaybackState>(
        stream: widget.controller.player.playbackStream,
        builder: (context, snapshot) {
          PlaybackState? playerState = snapshot.data;
          List<Widget> widgets = [];
          widgets.add(Ink(
              child: InkWell(
            onTap: widget.controller.stop,
            child: const Icon(Icons.stop_rounded, size: 36),
          )));
          widgets.add(Ink(
              child: InkWell(
            onTap: widget.controller.previous,
            child: const Icon(Icons.skip_previous_rounded, size: 36),
          )));
          if (playerState == null || !playerState.isPlaying) {
            widgets.add(Ink(
                child: InkWell(
              onTap: widget.controller.play,
              child: const Icon(Icons.play_arrow_rounded, size: 36),
            )));
          } else if (playerState.isPlaying) {
            widgets.add(Ink(
                child: InkWell(
              onTap: widget.controller.pause,
              child: const Icon(Icons.pause, size: 36),
            )));
          } else {
            widgets.add(Ink(
                child: InkWell(
              child: const Icon(Icons.replay_rounded, size: 24),
              onTap: () => widget.controller.seek(Duration.zero),
            )));
          }
          widgets.add(Ink(
              child: InkWell(
            onTap: widget.controller.next,
            child: const Icon(Icons.skip_next_rounded, size: 36),
          )));
          return Row(
            children: widgets,
          );
        });
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
  Widget _buildComplexControllerPanel(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPlayerSlider(context),
        _buildComplexControlPanel(context),
      ],
    );
  }

  ///简单控制器面板，包含简单播放面板和进度条
  Widget _buildSimpleControllerPanel(BuildContext context) {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildSimpleControlPanel(context),
        _buildPlayerSlider(context),
      ],
    ));
  }
}
