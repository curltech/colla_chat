import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/abstract_audio_player_controller.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

class BlueFireAudioPlayer {
  AudioPlayer player = AudioPlayer();

  Source _audioSource({required String filename}) {
    Source source;
    if (filename.startsWith('assets/')) {
      source = AssetSource(filename);
    } else if (filename.startsWith('http')) {
      source = UrlSource(filename);
    } else {
      source = DeviceFileSource(filename);
    }

    return source;
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
      Source source = _audioSource(filename: filename);
      await player.play(source,
          volume: volume,
          balance: balance,
          ctx: ctx,
          position: position,
          mode: mode);
    } catch (e) {
      logger.e('$e');
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
}

class BlueFireAudioSource {
  static Source mediaStream(
      {required Uint8List data, required MimeType mediaFormat}) {
    Source source = BytesSource(data);

    return source;
  }

  static Source audioSource({required String filename}) {
    Source source;
    if (filename.startsWith('assets/')) {
      source = AssetSource(filename);
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

///音频播放器，Android, iOS, Linux, macOS, Windows, and web.
class BlueFireAudioPlayerController extends AbstractAudioPlayerController {
  late AudioPlayer player;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  BlueFireAudioPlayerController() {
    player = AudioPlayer();
    _initStreams();
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      value = VideoPlayerValue(duration: duration);
    });

    _positionSubscription = player.onPositionChanged.listen((position) {
      value = VideoPlayerValue(duration: value.duration, position: position);
    });

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      value = VideoPlayerValue(
        duration: value.duration,
      );
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        value = VideoPlayerValue(
          duration: value.duration,
          isPlaying: false,
        );
      } else if (state == PlayerState.playing) {
        value = VideoPlayerValue(
          duration: value.duration,
          isPlaying: true,
        );
      } else if (state == PlayerState.paused) {
        value = VideoPlayerValue(
          duration: value.duration,
          isPlaying: false,
        );
      } else if (state == PlayerState.stopped) {
        value = VideoPlayerValue(
          duration: value.duration,
          isPlaying: false,
        );
      }
    });
  }

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  @override
  play() async {
    if (currentIndex >= 0 && currentIndex < playlist.length) {
      PlatformMediaSource? currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        Source source = BlueFireAudioSource.fromMediaSource(currentMediaSource);
        try {
          await player.play(source);
          playlistVisible = false;
          notifyListeners();
        } catch (e) {
          logger.e('$e');
        }
      }
    }
  }

  @override
  pause() async {
    await player.pause();
    notifyListeners();
  }

  @override
  stop() async {
    await player.stop();
    playlistVisible = true;
  }

  @override
  resume() async {
    await player.resume();
    notifyListeners();
  }

  @override
  dispose() async {
    await player.release();
    super.dispose();
  }

  Future<Duration?> getDuration() async {
    return await player.getDuration();
  }

  Future<Duration?> getPosition() async {
    return await player.getCurrentPosition();
  }

  Future<Duration?> getBufferedPosition() async {
    return null;
  }

  @override
  seek(Duration position, {int? index}) async {
    await setCurrentIndex(index!);
    await player.seek(position);
  }

  @override
  Future<double> getVolume() async {
    return Future.value(value.volume);
  }

  @override
  setVolume(double volume) async {
    await player.setVolume(volume);
    await super.setVolume(volume);
  }

  @override
  Future<double> getSpeed() async {
    return Future.value(value.playbackSpeed);
  }

  @override
  setSpeed(double speed) async {
    await player.setPlaybackRate(speed);
    await super.setSpeed(speed);
  }

  setPlayerMode(PlayerMode playerMode) async {
    await player.setPlayerMode(playerMode); // half speed
  }

  setReleaseMode(ReleaseMode releaseMode) async {
    await player.setReleaseMode(releaseMode); // half speed
  }

  setGlobalAudioContext(AudioContext ctx) async {
    AudioPlayer.global.setGlobalAudioContext(ctx);
  }

  setAudioContext(AudioContext ctx) async {
    player.setAudioContext(ctx);
  }

  onPositionChanged(Function(Duration duration) fn) {
    player.onPositionChanged.listen((Duration duration) {
      fn(duration);
    });
  }

  onPlayerComplete(Function(dynamic event) fn) {
    player.onPlayerComplete.listen((dynamic event) {
      fn(event);
    });
  }

  onDurationChanged(Function(Duration duration) fn) {
    player.onDurationChanged.listen((Duration duration) {
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
    return Container();
  }
}
