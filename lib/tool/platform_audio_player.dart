import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';


///音频播放器，Android, iOS, Linux, macOS, Windows, and web.
class PlatformAudioPlayer {
  late AudioPlayer player;

  PlatformAudioPlayer(
      {required String url, ReleaseMode releaseMode = ReleaseMode.stop}) {
    player = AudioPlayer();
    player.setReleaseMode(releaseMode);
  }

  setSource(Source source) async {
    await player.setSource(source);
  }

  setAssetSource(String filename) async {
    await player.setSource(AssetSource(filename));
  }

  setSourceUrl(String url) async {
    await player.setSourceUrl(url);
  }

  setSourceDeviceFile(String filename) async {
    await player.setSource(DeviceFileSource(filename));
  }

  setSourceBytes(Uint8List data) async {
    //final bytes = await AudioCache.instance.loadAsBytes(filename);
    await player.setSource(BytesSource(data));
  }

  setSourceFilePicker() async {
    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path != null) {
      setSource(DeviceFileSource(path));
    }
  }

  play(String filename) async {
    await player.play(DeviceFileSource(filename));
  }

  pause() async {
    await player.pause(); // will resume where left off
  }

  stop() async {
    await player.stop(); // will resume from beginning
  }

  resume() async {
    await player.resume();
  }

  release() async {
    await player.release();
  }

  Future<Duration?> getDuration() async {
    return await player.getDuration();
  }

  Future<Duration?> getCurrentPosition() async {
    return await player.getCurrentPosition();
  }

  seek(Duration position) async {
    await player.seek(position);
  }

  setVolume(double volume) async {
    await player.setVolume(volume);
  }

  setPlaybackRate(double playbackRate) async {
    await player.setPlaybackRate(playbackRate); // half speed
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
}
