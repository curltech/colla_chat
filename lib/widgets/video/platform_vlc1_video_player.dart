import 'dart:io';

import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/audio/platform_audio_player.dart';
import 'package:colla_chat/widgets/common/media_player_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class Vlc1MediaSource {
  static Future<String> media({String? filename, Uint8List? data}) async {
    if (filename == null) {
      data = data ?? Uint8List.fromList([]);
      filename = await FileUtil.writeTempFile(data, '');
    }

    return Future.value(filename);
  }

  static Future<List<String>> playlist(List<String> filenames) async {
    List<String> playlist = [];
    for (var filename in filenames) {
      playlist.add(await media(filename: filename));
    }

    return playlist;
  }
}

///基于chewie实现的媒体播放器和记录器，
class Vlc1VideoPlayerController extends AbstractMediaPlayerController {
  List<String> playlist = [];
  VlcPlayerController? _videoPlayerController;

  int? _currentIndex;

  Vlc1VideoPlayerController();

  _open({bool autoStart = false}) async {}

  VlcPlayerController? get current {
    return _videoPlayerController;
  }

  @override
  PlayerStatus get status {
    VlcPlayerValue value = current!.value;
    if (value.isPlaying) {
      return PlayerStatus.playing;
    } else if (value.isBuffering) {
      return PlayerStatus.buffering;
    } else if (value.isInitialized) {
      return PlayerStatus.init;
    }

    return PlayerStatus.stop;
  }

  _buildVideoPlayerController(String filename) async {
    if (_videoPlayerController == null) {
      if (filename.startsWith('assets/')) {
        _videoPlayerController = VlcPlayerController.asset(filename);
      } else if (filename.startsWith('http')) {
        _videoPlayerController = VlcPlayerController.network(filename);
      } else {
        _videoPlayerController = VlcPlayerController.file(File(filename));
      }
      await _videoPlayerController!.initialize();
    } else if (_videoPlayerController!.dataSource != filename) {
      if (filename.startsWith('assets/')) {
        await _videoPlayerController!.setMediaFromAsset(filename);
      } else if (filename.startsWith('http')) {
        await _videoPlayerController!.setMediaFromNetwork(filename);
      } else {
        await _videoPlayerController!.setMediaFromFile(File(filename));
      }
    }
  }

  ///基本的视频控制功能
  @override
  play() {
    if (current != null) {
      current!.play();
    }
  }

  @override
  seek(Duration position, {int? index}) {
    if (current != null) {
      current!.seekTo(position);
    }
  }

  @override
  pause() {
    if (current != null) {
      current!.pause();
    }
  }

  @override
  resume() {
    if (current != null) {
      current!.play();
    }
  }

  @override
  stop() {
    if (current != null) {
      current!.pause();
    }
  }

  @override
  Future<Duration?> getBufferedPosition() {
    throw '';
  }

  @override
  Future<Duration?> getDuration() {
    return current!.getDuration();
  }

  @override
  Future<Duration?> getPosition() {
    return current!.getPosition();
  }

  @override
  Future<double> getSpeed() async {
    var speed = await current!.getPlaybackSpeed();
    return speed ?? 1.0;
  }

  @override
  Future<double> getVolume() async {
    var volume = await current!.getVolume();
    return double.parse('$volume');
  }

  @override
  setVolume(double volume) {
    current!.setVolume(volume.toInt());
  }

  @override
  setSpeed(double speed) {
    current!.setPlaybackSpeed(speed);
  }

  Future<Uint8List> takeSnapshot(
    String filename,
    int width,
    int height,
  ) async {
    throw 'Not support';
  }

  @override
  dispose() {
    super.dispose();
    current!.dispose();
  }

  ///下面是播放列表的功能
  @override
  add({String? filename, Uint8List? data}) async {
    String dataSource =
        await Vlc1MediaSource.media(filename: filename, data: data);
    playlist.add(dataSource);
    _currentIndex = playlist.length - 1;
    await _buildVideoPlayerController(dataSource);
    play();
  }

  @override
  remove(int index) {
    if (index >= 0 && index < playlist.length) {
      playlist.removeAt(index);
      previous();
    }
  }

  @override
  insert(int index, {String? filename, Uint8List? data}) async {
    String dataSource =
        await Vlc1MediaSource.media(filename: filename, data: data);
    playlist.insert(index, dataSource);
  }

  @override
  move(int initialIndex, int finalIndex) {
    String dataSource = playlist[initialIndex];
    playlist[initialIndex] = playlist[finalIndex];
    playlist[finalIndex] = dataSource;
  }

  Widget buildVideoWidget({
    Key? key,
    double aspectRatio = 16 / 9,
    Widget? placeholder,
    bool virtualDisplay = true,
  }) {
    return VlcPlayer(
      key: key,
      controller: current!,
      aspectRatio: aspectRatio,
      placeholder: placeholder,
      virtualDisplay: virtualDisplay,
    );
  }

  @override
  setShuffleModeEnabled(bool enabled) {}
}

///采用Fijk-video-player实现的视频播放器，用于移动设备和web，内部实现采用video_player
class PlatformVlc1VideoPlayer extends StatefulWidget {
  late final Vlc1VideoPlayerController controller;
  final bool simple;
  final bool showControls;

  PlatformVlc1VideoPlayer(
      {Key? key,
      Vlc1VideoPlayerController? controller,
      this.simple = false,
      this.showControls = true})
      : super(key: key) {
    this.controller = controller ?? Vlc1VideoPlayerController();
  }

  @override
  State createState() => _PlatformVlc1VideoPlayerState();
}

class _PlatformVlc1VideoPlayerState extends State<PlatformVlc1VideoPlayer> {
  bool playlistVisible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildVlc1VideoPlayer(BuildContext context) {
    return VisibilityDetector(
      key: ObjectKey(widget.controller.current),
      onVisibilityChanged: (visiblityInfo) {
        if (visiblityInfo.visibleFraction > 0.9) {
          widget.controller.play();
        }
      },
      child: VlcPlayer(
        controller: widget.controller.current!,
        aspectRatio: 16 / 9,
      ),
    );
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
          child: _buildVlc1VideoPlayer(context),
        ),
      );
    });
    return container;
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

  ///播放列表
  Widget _buildPlaylist(BuildContext context) {
    List<String> playlist = widget.controller.playlist;
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
                  if (finalIndex > playlist.length) {
                    finalIndex = playlist.length;
                  }
                  if (initialIndex < finalIndex) finalIndex--;
                  widget.controller.move(initialIndex, finalIndex);
                },
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: List.generate(
                  playlist.length,
                  (int index) {
                    return ListTile(
                      key: Key(index.toString()),
                      leading: Text(
                        index.toString(),
                        style: const TextStyle(fontSize: 14.0),
                      ),
                      title: Text(
                        playlist[index].toString(),
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
    List<Widget> controls = [];
    controls.add(Expanded(child: _buildVideoView()));
    if (!widget.showControls) {
      Widget controllerPanel = PlatformChewieControllerPanel(
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
class PlatformChewieControllerPanel extends StatefulWidget {
  late final Vlc1VideoPlayerController controller;
  final bool simple;

  PlatformChewieControllerPanel({
    Key? key,
    Vlc1VideoPlayerController? controller,
    this.simple = false,
  }) : super(key: key) {
    this.controller = controller ?? Vlc1VideoPlayerController();
  }

  @override
  State createState() => _PlatformChewieControllerPanelState();
}

class _PlatformChewieControllerPanelState
    extends State<PlatformChewieControllerPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
    PlayerStatus status = widget.controller.status;
    List<Widget> widgets = [];

    if (status == PlayerStatus.init && status == PlayerStatus.stop) {
      widgets.add(Ink(
          child: InkWell(
        onTap: widget.controller.play,
        child: const Icon(Icons.play_arrow_rounded, size: 36),
      )));
    } else if (status == PlayerStatus.playing) {
      widgets.add(Ink(
          child: InkWell(
        onTap: widget.controller.pause,
        child: const Icon(Icons.pause, size: 36),
      )));
    } else if (status == PlayerStatus.completed) {
      widgets.add(Ink(
          child: InkWell(
        child: const Icon(Icons.replay, size: 36),
        onTap: () => widget.controller.seek(Duration.zero),
      )));
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVolumeButton(context),
          Row(children: widgets),
        ]);
  }

  ///音量按钮
  Widget _buildVolumeButton(BuildContext context) {
    return FutureBuilder<double>(
        future: widget.controller.getVolume(),
        builder: (context, snapshot) {
          var label = snapshot.data!.toStringAsFixed(1);
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
                value: snapshot.data!,
                onChanged: widget.controller.setVolume,
              );
            },
          ));
        });
  }

  ///速度按钮
  Widget _buildSpeedButton(BuildContext context) {
    return FutureBuilder<double>(
        future: widget.controller.getVolume(),
        builder: (context, snapshot) {
          var label = snapshot.data!.toStringAsFixed(1);
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
                value: snapshot.data!,
                onChanged: widget.controller.setSpeed,
              );
            },
          ));
        });
  }

  Widget _buildComplexControlPanel(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVolumeButton(context),
        const SizedBox(
          width: 25,
        ),
        _buildComplexPlayPanel(),
        const SizedBox(
          width: 25,
        ),
        _buildSpeedButton(context),
      ],
    );
  }

  ///复杂播放按钮面板
  Widget _buildComplexPlayPanel() {
    PlayerStatus status = widget.controller.status;
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
    if (status == PlayerStatus.stop || status == PlayerStatus.completed) {
      widgets.add(Ink(
          child: InkWell(
        onTap: widget.controller.play,
        child: const Icon(Icons.play_arrow_rounded, size: 36),
      )));
    } else if (status == PlayerStatus.playing) {
      widgets.add(Ink(
          child: InkWell(
        onTap: widget.controller.pause,
        child: const Icon(Icons.pause, size: 36),
      )));
    } else if (status == PlayerStatus.completed) {
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
  }

  Future<PositionData> _getPositionState() async {
    var duration = await widget.controller.getDuration();
    duration = duration ?? Duration.zero;
    var position = await widget.controller.getPosition();
    position = position ?? Duration.zero;
    return PositionData(position, Duration.zero, duration);
  }

  ///播放进度条
  Widget _buildPlayerSlider(BuildContext context) {
    return FutureBuilder<PositionData>(
      future: _getPositionState(),
      builder: (context, snapshot) {
        PositionData? positionData = snapshot.data;
        return MediaPlayerSlider(
          duration: positionData!.duration,
          position: positionData!.position,
          bufferedPosition: positionData.bufferedPosition,
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
