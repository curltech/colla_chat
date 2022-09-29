import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/platform_media_controller.dart';

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
      duration = duration;
    });

    _positionSubscription = player.onPositionChanged.listen((p) {
      position = p;
    });

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      position = Duration.zero;
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {});
  }

  @override
  play() async {
    if (currentIndex != null) {
      MediaSource? currentMediaSource = this.currentMediaSource;
      if (currentMediaSource != null) {
        Source source = BlueFireAudioSource.fromMediaSource(currentMediaSource);
        try {
          await player.play(source);
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
  }

  @override
  stop() async {
    await player.stop();
  }

  @override
  resume() async {
    await player.resume();
  }

  @override
  dispose() async {
    super.dispose();
    await player.release();
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
  Future<double> getVolume() {
    return Future.value(1);
  }

  @override
  setVolume(double volume) async {
    await player.setVolume(volume);
  }

  @override
  Future<double> getSpeed() {
    return Future.value(1);
  }

  @override
  setSpeed(double speed) async {
    await player.setPlaybackRate(speed); // half speed
  }

  setPlayerMode(PlayerMode playerMode) async {
    await player.setPlayerMode(playerMode); // half speed
  }

  setReleaseMode(ReleaseMode releaseMode) async {
    await player.setReleaseMode(releaseMode); // half speed
  }

  PlayerState get state {
    return player.state;
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
}
