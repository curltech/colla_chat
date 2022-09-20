import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:colla_chat/widgets/audio/platform_audio_player.dart';
import 'package:file_picker/file_picker.dart';

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

  static List<Source> playlist(List<String> filenames) {
    List<Source> playlist = [];
    for (var filename in filenames) {
      playlist.add(audioSource(filename: filename));
    }

    return playlist;
  }
}

///音频播放器，Android, iOS, Linux, macOS, Windows, and web.
class BlueFireAudioPlayerController extends AbstractAudioPlayerController {
  late AudioPlayer player;
  List<Source> playlist = [];
  Source? _current;
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

  sourceFilePicker() async {
    final result = await FilePicker.platform.pickFiles();
    final filename = result?.files.single.path;
    if (filename != null) {
      add(filename: filename);
    }
  }

  set current(Source? current) {
    _current = current;
    if (current != null) {
      player.setSource(current);
    }
  }

  @override
  play() async {
    await player.play(_current!);
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
    await player.release();
  }

  @override
  Future<Duration?> getDuration() async {
    return await player.getDuration();
  }

  Future<Duration?> getCurrentPosition() async {
    return await player.getCurrentPosition();
  }

  @override
  seek(Duration? position, {int? index}) async {
    await player.seek(position!);
  }

  @override
  setVolume(double volume) async {
    await player.setVolume(volume);
  }

  @override
  setRate(double rate) async {
    await player.setPlaybackRate(rate); // half speed
  }

  setPlayerMode(PlayerMode playerMode) async {
    await player.setPlayerMode(playerMode); // half speed
  }

  setReleaseMode(ReleaseMode releaseMode) async {
    await player.setReleaseMode(releaseMode); // half speed
  }

  @override
  add({String? filename, Uint8List? data}) async {
    Source audioSource =
        BlueFireAudioSource.audioSource(filename: filename, data: data);
    playlist.add(audioSource);
    await player.setSource(audioSource);
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
  int? currentIndex() {
    // TODO: implement currentIndex
    throw UnimplementedError();
  }

  @override
  insert(int index, {String? filename, Uint8List? data}) {
    // TODO: implement insert
    throw UnimplementedError();
  }

  @override
  next() {
    // TODO: implement next
    throw UnimplementedError();
  }

  @override
  open({bool preload = true, int? initialIndex, Duration? initialPosition}) {
    // TODO: implement open
    throw UnimplementedError();
  }

  @override
  previous() {
    // TODO: implement previous
    throw UnimplementedError();
  }

  @override
  remove(int index) {
    // TODO: implement remove
    throw UnimplementedError();
  }


  @override
  setShuffleModeEnabled(bool enabled) {
    // TODO: implement setShuffleModeEnabled
    throw UnimplementedError();
  }
}
