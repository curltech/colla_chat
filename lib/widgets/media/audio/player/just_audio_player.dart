import 'dart:async';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/audio/audio_service.dart';
import 'package:colla_chat/widgets/media/audio/player/just_audio_player_controller.dart';
import 'package:colla_chat/widgets/media/media_player_slider.dart';
import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:visibility_detector/visibility_detector.dart';

class JustAudioPlayer extends StatefulWidget {
  late final JustAudioPlayerController controller;

  //自定义简单控制器模式
  final bool showVolume;
  final bool showSpeed;

  //是否显示播放列表
  final bool showPlaylist;

  //是否显示音频波形界面
  final bool showMediaView;
  final String? filename;
  final List<int>? data;

  JustAudioPlayer(
      {Key? key,
      JustAudioPlayerController? controller,
      this.showVolume = true,
      this.showSpeed = false,
      this.showPlaylist = true,
      this.showMediaView = false,
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

  @override
  Widget build(BuildContext context) {
    AbstractMediaPlayerController controller = widget.controller;
    List<Widget> columns = [];
    List<Widget> rows = [];
    if (widget.showMediaView) {}
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
    Widget controllerPanel = PlatformJustAudioControllerPanel(
      controller: widget.controller,
      showVolume: widget.showVolume,
      showSpeed: widget.showSpeed,
      showPlaylist: widget.showPlaylist,
    );
    columns.add(Expanded(child: controllerPanel));
    return Column(children: columns);
  }
}

///视频播放器的控制面板
class PlatformJustAudioControllerPanel extends StatefulWidget {
  late final JustAudioPlayerController controller;

  ///如果是外置控件，是否显示简洁版
  final bool showVolume;
  final bool showSpeed;
  final bool showPlaylist;

  PlatformJustAudioControllerPanel({
    Key? key,
    JustAudioPlayerController? controller,
    this.showVolume = true,
    this.showSpeed = false,
    this.showPlaylist = true,
  }) : super(key: key) {
    this.controller = controller ?? JustAudioPlayerController();
  }

  @override
  State createState() => _PlatformJustAudioControllerPanelState();
}

class _PlatformJustAudioControllerPanelState
    extends State<PlatformJustAudioControllerPanel> {
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
      rows.add(StreamBuilder<double>(
        stream: widget.controller.player.volumeStream,
        builder: (context, snapshot) {
          return PlatformMediaPlayerUtil.buildVolumeButton(
              context, widget.controller);
        },
      ));
    }
    rows.add(StreamBuilder<PlayerState>(
        stream: widget.controller.player.playerStateStream,
        builder: (context, snapshot) {
          final playerState = snapshot.data;
          final processingState = playerState?.processingState;
          PlayerStatus status;
          if (playerState == null) {
            status = PlayerStatus.init;
          } else if (playerState.playing) {
            status = PlayerStatus.playing;
          } else if (processingState == ProcessingState.completed) {
            status = PlayerStatus.completed;
          } else {
            status = widget.controller.status;
          }
          Widget playback = PlatformMediaPlayerUtil.buildPlaybackButton(
              context, widget.controller, status, widget.showPlaylist);

          return playback;
        }));
    if (widget.showSpeed) {
      rows.add(StreamBuilder<double>(
        stream: widget.controller.player.speedStream,
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
