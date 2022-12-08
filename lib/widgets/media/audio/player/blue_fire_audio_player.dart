import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';

class BlueFireAudioSource {
  static Source audioSource({String? filename, Uint8List? data}) {
    Source source;
    if (filename != null) {
      if (filename.startsWith('assets/')) {
        source = AssetSource(filename);
      } else if (filename.startsWith('http')) {
        source = UrlSource(filename);
      } else {
        source = DeviceFileSource(filename);
      }
    } else {
      data = data ?? Uint8List.fromList([]);
      source = BytesSource(data);
    }

    return source;
  }

  static Source fromMediaSource(PlatformMediaSource mediaSource) {
    return audioSource(filename: mediaSource.filename);
  }
}

///音频播放器，Android, iOS, Linux, macOS, Windows, and web.
class BlueFireAudioPlayerController extends AbstractMediaPlayerController {
  late AudioPlayer player;
  Duration? duration;
  Duration? position;
  double volume = 1.0;
  double speed = 1.0;
  PlayerStatus _status = PlayerStatus.init;

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
      this.duration = duration;
    });

    _positionSubscription = player.onPositionChanged.listen((position) {
      this.position = position;
      notifyListeners();
    });

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      position = Duration.zero;
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        _status = PlayerStatus.completed;
      } else if (state == PlayerState.playing) {
        _status = PlayerStatus.playing;
      } else if (state == PlayerState.paused) {
        _status = PlayerStatus.pause;
      } else if (state == PlayerState.stopped) {
        _status = PlayerStatus.stop;
      }
    });
  }

  PlayerStatus get status {
    return _status;
  }

  play() async {
    if (currentIndex != null) {
      PlatformMediaSource? currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        Source source = BlueFireAudioSource.fromMediaSource(currentMediaSource);
        try {
          await player.play(source);
          playlistVisible = false;
          _status = PlayerStatus.playing;
          notifyListeners();
        } catch (e) {
          logger.e('$e');
        }
      }
    }
  }

  pause() async {
    await player.pause();
    _status = PlayerStatus.pause;
    notifyListeners();
  }

  stop() async {
    await player.stop();
    _status = PlayerStatus.stop;
    playlistVisible = true;
  }

  resume() async {
    await player.resume();
    _status = PlayerStatus.playing;
    notifyListeners();
  }

  @override
  close() async {
    super.dispose();
    await player.release();
    _status = PlayerStatus.init;
    playlistVisible = true;
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

  seek(Duration? position, {int? index}) async {
    await setCurrentIndex(index);
    await player.seek(position!);
  }

  Future<double> getVolume() async {
    return Future.value(volume);
  }

  setVolume(double volume) async {
    await player.setVolume(volume);
    if (volume != this.volume) {
      this.volume = volume;
      notifyListeners();
    }
  }

  Future<double> getSpeed() async {
    return Future.value(speed);
  }

  setSpeed(double speed) async {
    await player.setPlaybackRate(speed);
    if (speed != this.speed) {
      this.speed = speed;
      notifyListeners();
    }
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
