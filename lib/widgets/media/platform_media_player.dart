import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/media/media_player_slider.dart';
import 'package:colla_chat/widgets/media/platform_media_controller.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PlatformMediaPlayer extends StatefulWidget {
  final AbstractMediaPlayerController controller;

  //自定义简单控制器模式
  final bool showVolume;
  final bool showSpeed;

  //是否显示原生的控制器
  final bool showControls;

  //是否显示播放列表和媒体视图
  final bool showPlaylist;
  final bool showMediaView;
  final Color? color;
  final double? height;
  final double? width;
  final String? filename;
  final List<int>? data;

  const PlatformMediaPlayer(
      {Key? key,
      this.showVolume = true,
      this.showSpeed = false,
      required this.controller,
      this.showControls = true,
      this.showPlaylist = true,
      this.showMediaView = true,
      this.color,
      this.width,
      this.height,
      this.filename,
      this.data})
      : super(key: key);

  @override
  State createState() => _PlatformMediaPlayerState();
}

class _PlatformMediaPlayerState extends State<PlatformMediaPlayer> {
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

  ///播放列表
  Widget _buildPlaylist(BuildContext context) {
    AbstractMediaPlayerController controller = widget.controller;
    List<MediaSource> playlist = controller.playlist;
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
                          await controller.add(filename: filename);
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
                  controller.move(initialIndex, finalIndex);
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
                        playlist[index].filename.toString(),
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

  Widget _buildMediaView(
      {required AbstractMediaPlayerController controller,
      Color? color,
      double? height,
      double? width}) {
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
          child: controller.buildMediaView(),
        ),
      );
    });
    return container;
  }

  Widget _buildSliderWidget({
    required BuildContext context,
    required int divisions,
    required double min,
    required double max,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    var sliderThemeData = MediaPlayerSliderUtil.buildSliderTheme(context);
    return SizedBox(
      width: 100.0,
      child: RotatedBox(
          quarterTurns: 0,
          child: SliderTheme(
              data: sliderThemeData,
              child: Slider(
                //divisions: divisions,
                min: min,
                max: max,
                value: value,
                onChanged: onChanged,
              ))),
    );
  }

  ///音量按钮
  Widget _buildVolumeButton(BuildContext context) {
    AbstractMediaPlayerController controller = widget.controller;
    return FutureBuilder<double>(
        future: controller.getVolume(),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return _buildProgressIndicator();
          }
          return Row(children: [
            Ink(
                child: InkWell(
              child: const Icon(Icons.volume_up, size: 24),
              onTap: () {
                var volumeSlideVisible = controller.volumeSlideVisible;
                controller.volumeSlideVisible = !volumeSlideVisible;
              },
            )),
            Text(snapshot.data!.toStringAsFixed(1)),
            Visibility(
                visible: controller.volumeSlideVisible,
                child: _buildSliderWidget(
                  context: context,
                  divisions: 10,
                  min: 0.0,
                  max: 1.0,
                  value: snapshot.data!,
                  onChanged: controller.setVolume,
                )),
          ]);
        });
  }

  ///速度按钮
  Widget _buildSpeedButton(BuildContext context) {
    AbstractMediaPlayerController controller = widget.controller;
    return FutureBuilder<double>(
        future: controller.getSpeed(),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return _buildProgressIndicator();
          }
          return Row(children: [
            Ink(
                child: InkWell(
              child: const Icon(Icons.speed, size: 24),
              onTap: () {
                var speedSlideVisible = controller.speedSlideVisible;
                controller.speedSlideVisible = !speedSlideVisible;
              },
            )),
            Text(snapshot.data!.toStringAsFixed(1)),
            Visibility(
                visible: controller.speedSlideVisible,
                child: _buildSliderWidget(
                  context: context,
                  divisions: 10,
                  min: 0.5,
                  max: 1.5,
                  value: snapshot.data!,
                  onChanged: controller.setSpeed,
                ))
          ]);
        });
  }

  ///简单播放控制面板，包含音量，简单播放按钮，
  Widget _buildSimpleControlPanel(BuildContext context) {
    AbstractMediaPlayerController controller = widget.controller;
    PlayerStatus status = controller.status;
    List<Widget> widgets = [];

    if (status == PlayerStatus.init ||
        status == PlayerStatus.pause ||
        status == PlayerStatus.stop) {
      widgets.add(Ink(
          child: InkWell(
        onTap: controller.play,
        child: const Icon(Icons.play_arrow, size: 36),
      )));
    } else if (status == PlayerStatus.playing) {
      widgets.add(Ink(
          child: InkWell(
        onTap: controller.pause,
        child: const Icon(Icons.pause, size: 36),
      )));
    } else if (status == PlayerStatus.completed) {
      widgets.add(Ink(
          child: InkWell(
        child: const Icon(Icons.replay, size: 36),
        onTap: () => controller.seek(Duration.zero),
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

  Widget _buildComplexControlPanel(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVolumeButton(context),
        // const SizedBox(
        //   width: 25,
        // ),
        _buildComplexPlayPanel(context),
        // const SizedBox(
        //   width: 25,
        // ),
        _buildSpeedButton(context),
      ],
    );
  }

  ///复杂播放按钮面板
  Widget _buildComplexPlayPanel(BuildContext context) {
    AbstractMediaPlayerController controller = widget.controller;
    PlayerStatus status = controller.status;
    List<Widget> widgets = [];
    widgets.add(Ink(
        child: InkWell(
      onTap: controller.stop,
      child: const Icon(Icons.stop, size: 36),
    )));
    widgets.add(Ink(
        child: InkWell(
      onTap: controller.previous,
      child: const Icon(Icons.skip_previous, size: 36),
    )));
    if (status == PlayerStatus.init ||
        status == PlayerStatus.pause ||
        status == PlayerStatus.stop ||
        status == PlayerStatus.completed) {
      widgets.add(Ink(
          child: InkWell(
        onTap: controller.play,
        child: const Icon(Icons.play_arrow, size: 36),
      )));
    } else if (status == PlayerStatus.playing) {
      widgets.add(Ink(
          child: InkWell(
        onTap: controller.pause,
        child: const Icon(Icons.pause, size: 36),
      )));
    } else if (status == PlayerStatus.completed) {
      widgets.add(Ink(
          child: InkWell(
        child: const Icon(Icons.replay, size: 24),
        onTap: () => controller.seek(Duration.zero),
      )));
    }
    widgets.add(Ink(
        child: InkWell(
      onTap: controller.next,
      child: const Icon(Icons.skip_next, size: 36),
    )));
    return Row(
      children: widgets,
    );
  }

  Future<PositionData> _getPositionState(BuildContext context) async {
    AbstractMediaPlayerController controller = widget.controller;
    var duration = await controller.getDuration();
    duration = duration ?? Duration.zero;
    var position = await controller.getPosition();
    position = position ?? Duration.zero;
    return PositionData(position, Duration.zero, duration);
  }

  ///播放进度条
  Widget _buildPlayerSlider(BuildContext context) {
    AbstractMediaPlayerController controller = widget.controller;
    return FutureBuilder<PositionData>(
      future: _getPositionState(context),
      builder: (context, snapshot) {
        PositionData? positionData = snapshot.data;
        if (positionData != null) {
          return MediaPlayerSlider(
            duration: positionData.duration,
            position: positionData.position,
            bufferedPosition: positionData.bufferedPosition,
            onChangeEnd: controller.seek,
          );
        } else {
          return _buildProgressIndicator();
        }
      },
    );
  }

  Container _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      width: 24.0,
      height: 24.0,
      child: const CircularProgressIndicator(),
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

  Widget _buildMediaPlayer(BuildContext context) {
    AbstractMediaPlayerController controller = widget.controller;
    List<Widget> controls = [];
    if (widget.showPlaylist) {
      var view = VisibilityDetector(
          key: ObjectKey(controller),
          onVisibilityChanged: (visiblityInfo) {
            if (visiblityInfo.visibleFraction > 0.9) {
              controller.play();
            }
          },
          child: Stack(children: [
            Visibility(
                visible: widget.showMediaView,
                child: _buildMediaView(
                    controller: controller,
                    color: widget.color,
                    width: widget.width,
                    height: widget.height)),
            Visibility(
              visible: widget.showPlaylist,
              child: _buildPlaylist(context),
            )
          ]));
      controls.add(Expanded(child: view));
    }
    if (!widget.showControls) {
      Widget controllerPanel;
      if (widget.showPlaylist) {
        controllerPanel = _buildSimpleControllerPanel(context);
      } else {
        controllerPanel = _buildComplexControllerPanel(context);
      }
      controls.add(controllerPanel);
    }
    return Column(children: controls);
  }

  @override
  Widget build(BuildContext context) {
    return _buildMediaPlayer(context);
  }
}
