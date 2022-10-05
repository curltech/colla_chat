import 'dart:async';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/audio/audio_service.dart';
import 'package:colla_chat/widgets/media/audio/just_audio_player_controller.dart';
import 'package:colla_chat/widgets/media/media_player_slider.dart';
import 'package:colla_chat/widgets/media/platform_media_player_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class JustAudioPlayer extends StatefulWidget {
  late final JustAudioPlayerController controller;

  //自定义简单控制器模式
  final bool simple;

  //是否显示播放列表
  final bool showPlayerList;
  final String? filename;
  final Uint8List? data;

  JustAudioPlayer(
      {Key? key,
      JustAudioPlayerController? controller,
      this.simple = false,
      this.showPlayerList = true,
      this.filename,
      this.data})
      : super(key: key) {
    this.controller = controller ?? JustAudioPlayerController();
  }

  @override
  State createState() => _JustAudioPlayerState();
}

class _JustAudioPlayerState extends State<JustAudioPlayer>
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
    if (widget.filename != null || widget.data != null) {
      widget.controller.add(filename: widget.filename, data: widget.data);
    }
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

  ///复杂控制器面板，包含播放列表，进度条和复杂播放面板
  Widget _buildComplexControllerPanel(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PlatformMediaPlayerUtil.buildPlaylist(context, widget.controller),
        _buildPlayerSlider(context),
        _buildComplexControlPanel(context),
      ],
    );
  }

  ///简单播放控制面板，包含音量，简单播放按钮，
  Widget _buildSimpleControlPanel(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<double>(
            stream: widget.controller.player.volumeStream,
            builder: (context, snapshot) {
              return PlatformMediaPlayerUtil.buildVolumeButton(
                  context, widget.controller);
            },
          ),
          StreamBuilder<PlayerState>(
              stream: widget.controller.player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  return PlatformMediaPlayerUtil.buildProgressIndicator();
                } else {
                  return PlatformMediaPlayerUtil.buildSimpleControlPanel(
                      context, widget.controller);
                }
              }),
        ]);
  }

  ///复杂控制器按钮面板，包含音量，速度和播放按钮
  Widget _buildComplexControlPanel(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<double>(
          stream: widget.controller.player.volumeStream,
          builder: (context, snapshot) {
            return PlatformMediaPlayerUtil.buildVolumeButton(
                context, widget.controller);
          },
        ),
        // const SizedBox(
        //   width: 50,
        // ),
        _buildComplexPlayPanel(),
        // const SizedBox(
        //   width: 50,
        // ),
        StreamBuilder<double>(
          stream: widget.controller.player.speedStream,
          builder: (context, snapshot) {
            return PlatformMediaPlayerUtil.buildSpeedButton(
                context, widget.controller);
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
          if (processingState == ProcessingState.loading ||
              processingState == ProcessingState.buffering) {
            return PlatformMediaPlayerUtil.buildProgressIndicator();
          } else {
            return PlatformMediaPlayerUtil.buildComplexPlayPanel(
                context, widget.controller);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.simple) {
      return _buildSimpleControllerPanel(context);
    }
    return _buildComplexControllerPanel(context);
  }
}
