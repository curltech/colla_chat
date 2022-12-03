import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/audio/audio_service.dart';
import 'package:colla_chat/widgets/media/audio/waveforms_audio_player_controller.dart';
import 'package:colla_chat/widgets/media/media_player_slider.dart';
import 'package:colla_chat/widgets/media/abstract_media_controller.dart';
import 'package:colla_chat/widgets/media/platform_media_player_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

class WaveformsAudioPlayer extends StatefulWidget {
  late final WaveformsAudioPlayerController controller;

  //自定义简单控制器模式
  final bool showVolume;
  final bool showSpeed;

  //是否显示播放列表
  final bool showPlaylist;

  //是否显示音频波形界面
  final bool showMediaView;
  final String? filename;
  final List<int>? data;

  WaveformsAudioPlayer(
      {Key? key,
      WaveformsAudioPlayerController? controller,
      this.showVolume = true,
      this.showSpeed = false,
      this.showPlaylist = true,
      this.showMediaView = false,
      this.filename,
      this.data})
      : super(key: key) {
    this.controller = controller ?? WaveformsAudioPlayerController();
  }

  @override
  State createState() => _WaveformsAudioPlayerState();
}

class _WaveformsAudioPlayerState extends State<WaveformsAudioPlayer>
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
    widget.controller.playerController.onCurrentDurationChanged.listen(
        (int position) {
      logger.i('A stream onCurrentDurationChanged occurred: $position');
    }, onError: (Object e, StackTrace stackTrace) {
      logger.e('A stream error occurred: $e');
    });
    widget.controller.playerController.onPlayerStateChanged.listen(
        (playerState) {
      logger.i('A stream onPlayerStateChanged occurred: ${playerState.name}');
      if (playerState == PlayerState.initialized) {
        widget.controller.status = PlayerStatus.init;
      } else if (playerState == PlayerState.playing) {
        widget.controller.status = PlayerStatus.playing;
      } else if (playerState == PlayerState.paused) {
        widget.controller.status = PlayerStatus.pause;
      } else if (playerState == PlayerState.stopped) {
        widget.controller.status = PlayerStatus.stop;
      } else if (playerState == PlayerState.readingComplete) {
        widget.controller.status = PlayerStatus.completed;
      }
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
    Widget controllerPanel = WaveformsAudioControllerPanel(
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
class WaveformsAudioControllerPanel extends StatefulWidget {
  late final WaveformsAudioPlayerController controller;

  ///如果是外置控件，是否显示简洁版
  final bool showVolume;
  final bool showSpeed;
  final bool showPlaylist;

  WaveformsAudioControllerPanel({
    Key? key,
    WaveformsAudioPlayerController? controller,
    this.showVolume = true,
    this.showSpeed = false,
    this.showPlaylist = true,
  }) : super(key: key) {
    this.controller = controller ?? WaveformsAudioPlayerController();
  }

  @override
  State createState() => _WaveformsAudioControllerPanelState();
}

class _WaveformsAudioControllerPanelState
    extends State<WaveformsAudioControllerPanel> {
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
      rows.add(PlatformMediaPlayerUtil.buildVolumeButton(
          context, widget.controller));
    }
    rows.add(PlatformMediaPlayerUtil.buildPlayback(context, widget.controller,
        widget.controller.status, widget.showPlaylist));

    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: rows);
  }

  ///播放进度条
  Widget _buildPlayerSlider(BuildContext context) {
    return StreamBuilder<int>(
      stream: widget.controller.playerController.onCurrentDurationChanged,
      builder: (context, snapshot) {
        final positionData = snapshot.data;
        return MediaPlayerSlider(
          duration: Duration(
              milliseconds: widget.controller.playerController.maxDuration),
          position: positionData != 0
              ? Duration(milliseconds: positionData!)
              : Duration.zero,
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
