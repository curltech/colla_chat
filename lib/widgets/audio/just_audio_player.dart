import 'dart:async';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/audio/audio_service.dart';
import 'package:colla_chat/widgets/audio/just_audio_player_controller.dart';
import 'package:colla_chat/widgets/common/media_player_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class JustAudioPlayer extends StatefulWidget {
  late final JustAudioPlayerController controller;
  final bool simple;

  JustAudioPlayer(
      {Key? key, JustAudioPlayerController? controller, this.simple = false})
      : super(key: key) {
    this.controller = controller ?? JustAudioPlayerController();
  }

  @override
  JustAudioPlayerState createState() => JustAudioPlayerState();
}

class JustAudioPlayerState extends State<JustAudioPlayer>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();
  }

  Future<void> _init() async {
    widget.controller.addListener(_update);
    AudioSessionUtil.initMusic();
    widget.controller.player.playbackEventStream.listen((PlaybackEvent event) {
      logger.i('A stream PlaybackEvent occurred: ${event.toString()}');
    }, onError: (Object e, StackTrace stackTrace) {
      logger.e('A stream error occurred: $e');
    });
  }

  _update() {
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    widget.controller.removeListener(_update);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
      widget.controller.stop();
    }
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

  ///播放进度条
  Widget _buildPlayerSlider(BuildContext context) {
    return StreamBuilder<PositionData>(
      stream: widget.controller.positionDataStream,
      builder: (context, snapshot) {
        final positionData = snapshot.data;
        return MediaPlayerSlider(
          duration: positionData?.duration ?? Duration.zero,
          position: positionData?.position ?? Duration.zero,
          bufferedPosition: positionData?.bufferedPosition ?? Duration.zero,
          onChangeEnd: widget.controller.seek,
        );
      },
    );
  }

  ///播放列表
  Widget _buildPlaylist(BuildContext context) {
    var playlist = widget.controller.playlist;
    var filenames = widget.controller.filenames;
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.all(4.0),
      child: Container(
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
                        // var filename =
                        //     'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3';
                        // widget.controller.player.setAudioSource(
                        //     AudioSource.uri(Uri.parse(filename)));
                      },
                    ),
                  )
                ],
              ),
            ),
            Container(
              height: 250.0,
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
                        filenames[index],
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
    );
  }

  ///复杂控制器面板，包含播放列表，进度条和复杂播放面板
  Widget _buildComplexControllerPanel(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPlaylist(context),
        _buildPlayerSlider(context),
        // Display play/pause button and volume/speed sliders.
        _buildComplexControlPanel(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.simple) {
      return _buildSimpleControllerPanel(context);
    }
    return _buildComplexControllerPanel(context);
  }

  ///简单播放控制面板，包含音量，简单播放按钮，
  Row _buildSimpleControlPanel(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<double>(
            stream: widget.controller.player.volumeStream,
            builder: (context, snapshot) {
              var label = '${snapshot.data?.toStringAsFixed(1)}';
              return _buildVolumeButton(context, label: label);
            },
          ),
          StreamBuilder<PlayerState>(
              stream: widget.controller.player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = playerState?.playing;
                List<Widget> widgets = [];
                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  widgets.add(Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 24.0,
                    height: 24.0,
                    child: const CircularProgressIndicator(),
                  ));
                } else {
                  if (playing != true) {
                    widgets.add(Ink(
                        child: InkWell(
                      onTap: widget.controller.play,
                      child: const Icon(Icons.play_arrow_rounded, size: 36),
                    )));
                  } else if (processingState != ProcessingState.completed) {
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

  ///音量控制按钮
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
          stream: widget.controller.player.volumeStream,
          onChanged: widget.controller.setVolume,
        );
      },
    ));
  }

  ///速度控制按钮
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
          stream: widget.controller.player.speedStream,
          onChanged: widget.controller.setSpeed,
        );
      },
    ));
  }

  ///复杂控制器按钮面板，包含音量，速度和播放按钮
  Widget _buildComplexControlPanel(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<double>(
          stream: widget.controller.player.volumeStream,
          builder: (context, snapshot) {
            var label = '${snapshot.data?.toStringAsFixed(1)}';
            return _buildVolumeButton(context, label: label);
          },
        ),
        const SizedBox(
          width: 50,
        ),
        _buildComplexPlayPanel(),
        const SizedBox(
          width: 50,
        ),
        StreamBuilder<double>(
          stream: widget.controller.player.speedStream,
          builder: (context, snapshot) {
            var label = '${snapshot.data?.toStringAsFixed(1)}';
            return _buildSpeedButton(context, label: label);
          },
        ),
      ],
    );
  }

  ///复杂播放按钮面板，包含复杂播放按钮
  StreamBuilder<PlayerState> _buildComplexPlayPanel() {
    return StreamBuilder<PlayerState>(
        stream: widget.controller.player.playerStateStream,
        builder: (context, snapshot) {
          final playerState = snapshot.data;
          final processingState = playerState?.processingState;
          final playing = playerState?.playing;
          List<Widget> widgets = [];
          if (processingState == ProcessingState.loading ||
              processingState == ProcessingState.buffering) {
            widgets.add(Container(
              margin: const EdgeInsets.all(8.0),
              width: 24.0,
              height: 24.0,
              child: const CircularProgressIndicator(),
            ));
          } else {
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
            if (playing != true) {
              widgets.add(Ink(
                  child: InkWell(
                onTap: widget.controller.play,
                child: const Icon(Icons.play_arrow_rounded, size: 36),
              )));
            } else if (processingState != ProcessingState.completed) {
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
            widgets.add(Ink(
                child: InkWell(
              onTap: widget.controller.next,
              child: const Icon(Icons.skip_next_rounded, size: 36),
            )));
          }
          return Row(
            children: widgets,
          );
        });
  }
}
