import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/media/platform_media_controller.dart';
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

  static Source fromMediaSource(MediaSource mediaSource) {
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
        status = PlayerStatus.completed;
      } else if (state == PlayerState.playing) {
        status = PlayerStatus.playing;
      } else if (state == PlayerState.paused) {
        status = PlayerStatus.pause;
      } else if (state == PlayerState.stopped) {
        status = PlayerStatus.stop;
      }
    });
  }

  @override
  PlayerStatus get status {
    PlayerState state = player.state;
    if (state == PlayerState.completed) {
      return PlayerStatus.completed;
    } else if (state == PlayerState.playing) {
      return PlayerStatus.playing;
    } else if (state == PlayerState.paused) {
      return PlayerStatus.pause;
    } else if (state == PlayerState.stopped) {
      return PlayerStatus.stop;
    }
    return super.status;
  }

  @override
  play() async {
    if (currentIndex != null) {
      MediaSource? currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        Source source = BlueFireAudioSource.fromMediaSource(currentMediaSource);
        try {
          await player.play(source);
          playlistVisible = false;
          status = PlayerStatus.playing;
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
    status = PlayerStatus.pause;
    notifyListeners();
  }

  @override
  stop() async {
    await player.stop();
    status = PlayerStatus.stop;
    playlistVisible = true;
  }

  @override
  resume() async {
    await player.resume();
    status = PlayerStatus.playing;
    notifyListeners();
  }

  @override
  dispose() async {
    super.dispose();
    await player.release();
    status = PlayerStatus.init;
    playlistVisible = true;
  }

  @override
  Future<Duration?> getDuration() async {
    return await player.getDuration();
  }

  @override
  Future<Duration?> getPosition() async {
    return await player.getCurrentPosition();
  }

  @override
  Future<Duration?> getBufferedPosition() async {
    return null;
  }

  @override
  seek(Duration? position, {int? index}) async {
    await setCurrentIndex(index);
    await player.seek(position!);
  }

  @override
  Future<double> getVolume() async {
    return Future.value(volume);
  }

  @override
  setVolume(double volume) async {
    await player.setVolume(volume);
    if (volume != this.volume) {
      this.volume = volume;
      notifyListeners();
    }
  }

  @override
  Future<double> getSpeed() async {
    return Future.value(speed);
  }

  @override
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
  setShuffleModeEnabled(bool enabled) {
    throw UnimplementedError();
  }

  @override
  close() {}

  @override
  Widget buildMediaView({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    double scale = 1.0,
    bool showControls = true,
  }) {
    return Container();
  }
}
