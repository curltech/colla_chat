import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/abstract_audio_player_controller.dart';
import 'package:flutter/material.dart';

///简单地播放音频文件，没有控制器按钮和状态
class BlueFireAudioPlayer {
  AudioPlayer player = AudioPlayer();

  BlueFireAudioPlayer();

  ///所有的音频播放器的配置
  setGlobalAudioContext({
    AudioContextConfigRoute? route,
    AudioContextConfigFocus? focus,
    bool? respectSilence,
    bool? stayAwake,
  }) async {
    GlobalAudioScope global = AudioPlayer.global;
    await global.setAudioContext(_buildAudioContextConfig(
        route: route,
        focus: focus,
        respectSilence: respectSilence,
        stayAwake: stayAwake));
  }

  setAudioContext({
    AudioContextConfigRoute? route,
    AudioContextConfigFocus? focus,
    bool? respectSilence,
    bool? stayAwake,
  }) async {
    AudioContext audioContext = _buildAudioContextConfig(
        route: route,
        focus: focus,
        respectSilence: respectSilence,
        stayAwake: stayAwake);
    if (platformParams.mobile) {
      await player.setAudioContext(audioContext);
    }
  }

  AudioContext _buildAudioContextConfig({
    AudioContextConfigRoute? route,
    AudioContextConfigFocus? focus,
    bool? respectSilence,
    bool? stayAwake,
  }) {
    AudioContextConfig audioContextConfig = AudioContextConfig();
    AudioContextConfig config = audioContextConfig.copy(
        route: route,
        focus: focus,
        respectSilence: respectSilence,
        stayAwake: stayAwake);

    return config.build();
  }

  play(
    String filename, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    try {
      Source source = BlueFireAudioSource.audioSource(filename: filename);
      await player.play(source,
          volume: volume,
          balance: balance,
          ctx: ctx,
          position: position,
          mode: mode);
    } catch (e) {
      logger.e('blue fire audio player play failure:$e');
      player.stop();
      player.release();
    }
  }

  pause() async {
    await player.pause();
  }

  resume() async {
    await player.resume();
  }

  stop() async {
    await player.stop();
  }

  release() async {
    await player.release();
  }

  setLoopMode(bool mode) async {
    await player.setReleaseMode(mode ? ReleaseMode.loop : ReleaseMode.stop);
  }
}

///全局的BlueFireAudioPlayer音频播放器，可以直接播放音频文件
final BlueFireAudioPlayer globalBlueFireAudioPlayer = BlueFireAudioPlayer();

///BlueFire的音频源类，提供将其他形式比如文件转换成BlueFire音频源的静态方法
class BlueFireAudioSource {
  static Source mediaStream(
      {required Uint8List data, required ChatMessageMimeType mediaFormat}) {
    Source source = BytesSource(data);

    return source;
  }

  static Source audioSource({required String filename}) {
    Source source;
    if (filename.startsWith('assets/')) {
      source = AssetSource(filename.substring(7));
    } else if (filename.startsWith('http')) {
      source = UrlSource(filename);
    } else {
      source = DeviceFileSource(filename);
    }

    return source;
  }

  static Source fromMediaSource(PlatformMediaSource mediaSource) {
    return audioSource(filename: mediaSource.filename);
  }
}

///完整的音频播放器，Android, iOS, Linux, macOS, Windows, and web.
///带有控制器按钮和状态跟踪
class BlueFireAudioPlayerController extends AbstractAudioPlayerController {
  BlueFireAudioPlayer? player;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  BlueFireAudioPlayerController({this.player}) : super() {
    _initStreams();
  }

  void _initStreams() {
    this.player ??= BlueFireAudioPlayer();
    var player = this.player!.player;
    _durationSubscription = player.onDurationChanged.listen((duration) {
      mediaPlayerState.duration = duration;
    });

    _positionSubscription = player.onPositionChanged.listen((position) {
      mediaPlayerState.position = position;
      notifyListeners();
    });

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      mediaPlayerState.position = mediaPlayerState.duration;
      mediaPlayerState.mediaPlayerStatus = MediaPlayerStatus.completed;
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        mediaPlayerState.mediaPlayerStatus = MediaPlayerStatus.completed;
      } else if (state == PlayerState.playing) {
        mediaPlayerState.mediaPlayerStatus = MediaPlayerStatus.playing;
      } else if (state == PlayerState.paused) {
        mediaPlayerState.mediaPlayerStatus = MediaPlayerStatus.pause;
      } else if (state == PlayerState.stopped) {
        mediaPlayerState.mediaPlayerStatus = MediaPlayerStatus.stop;
      }
    });
  }

  @override
  setCurrentIndex(int index) async {
    if (index >= -1 && index < playlist.length && currentIndex != index) {
      close();
      await super.setCurrentIndex(index);
      notifyListeners();
      if (autoplay) {
        play();
      }
    }
  }

  @override
  close() {
    player!.stop();
    player!.release();
  }

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  @override
  play() async {
    if (currentIndex >= 0 && currentIndex < playlist.length) {
      PlatformMediaSource? currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        try {
          await player!.play(currentMediaSource.filename);
        } catch (e) {
          logger.e('$e');
        }
      }
    }
  }

  @override
  pause() async {
    await player!.pause();
    notifyListeners();
  }

  @override
  stop() async {
    await player!.stop();
    playlistVisible = true;
  }

  @override
  resume() async {
    await player!.resume();
    notifyListeners();
  }

  @override
  dispose() async {
    await player!.release();
    super.dispose();
  }

  Future<Duration?> getDuration() async {
    return await player!.player.getDuration();
  }

  Future<Duration?> getPosition() async {
    return await player!.player.getCurrentPosition();
  }

  Future<Duration?> getBufferedPosition() async {
    return null;
  }

  @override
  seek(Duration position, {int? index}) async {
    await setCurrentIndex(index!);
    await player!.player.seek(position);
  }

  @override
  setVolume(double volume) async {
    await player!.player.setVolume(volume);
    await super.setVolume(volume);
  }

  @override
  setSpeed(double speed) async {
    await player!.player.setPlaybackRate(speed);
    await super.setSpeed(speed);
  }

  setPlayerMode(PlayerMode playerMode) async {
    await player!.player.setPlayerMode(playerMode); // half speed
  }

  setReleaseMode(ReleaseMode releaseMode) async {
    await player!.player.setReleaseMode(releaseMode); // half speed
  }

  setAudioContext(AudioContext ctx) async {
    player!.player.setAudioContext(ctx);
  }

  onPositionChanged(Function(Duration duration) fn) {
    player!.player.onPositionChanged.listen((Duration duration) {
      fn(duration);
    });
  }

  onPlayerComplete(Function(dynamic event) fn) {
    player!.player.onPlayerComplete.listen((dynamic event) {
      fn(event);
    });
  }

  onDurationChanged(Function(Duration duration) fn) {
    player!.player.onDurationChanged.listen((Duration duration) {
      fn(duration);
    });
  }

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    return super.buildMediaPlayer(
        key: key,
        showClosedCaptionButton: showClosedCaptionButton,
        showFullscreenButton: showFullscreenButton,
        showVolumeButton: showVolumeButton);
  }
}

final BlueFireAudioPlayerController globalBlueFireAudioPlayerController =
    BlueFireAudioPlayerController();
