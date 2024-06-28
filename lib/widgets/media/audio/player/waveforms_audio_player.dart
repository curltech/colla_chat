import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:colla_chat/widgets/media/audio/abstract_audio_player_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';

///WaveformsAudio音频播放器，Android, iOS, Linux, macOS, Windows, and web.
///还可以产生音频播放的波形图形组件
class WaveformsAudioPlayerController extends AbstractAudioPlayerController {
  late PlayerController playerController;
  double _volume = 1.0;

  WaveformsAudioPlayerController(super.playlistController) {
    playerController = PlayerController();
    playerController.onCurrentDurationChanged.listen((event) {});
    playerController.onPlayerStateChanged.listen((state) {});
  }

  ///设置当前的通用MediaSource，并转换成特定实现的媒体源，并进行设置
  @override
  Future<void> playMediaSource(PlatformMediaSource mediaSource) async {
    await close();
    playerController.preparePlayer(path: mediaSource.filename, volume: _volume);
    await playerController.startPlayer();
  }

  @override
  pause() async {
    await playerController.pausePlayer();
  }

  @override
  stop() async {
    await playerController.stopPlayer();
  }

  @override
  resume() async {
    await playerController.startPlayer();
  }

  @override
  dispose() async {
    super.dispose();
    playerController.dispose();
  }

  @override
  seek(Duration position, {int? index}) async {
    if (index != null) {
      playlistController.currentIndex = index;
    }
    try {
      await playerController.seekTo(position.inMilliseconds);
    } catch (e) {
      logger.e('seek failure:$e');
    }
  }

  Future<Duration?> getDuration() async {
    int milliseconds = await playerController.getDuration(DurationType.max);

    return Duration(milliseconds: milliseconds);
  }

  Future<Duration?> getPosition() async {
    int milliseconds = await playerController.getDuration(DurationType.current);

    return Duration(milliseconds: milliseconds);
  }

  Future<Duration?> getBufferedPosition() async {
    return Future.value(const Duration(milliseconds: 0));
  }

  @override
  Future<double> getVolume() async {
    return Future.value(_volume);
  }

  @override
  setVolume(double volume) async {
    if (_volume != volume) {
      bool success = await playerController.setVolume(volume);
      if (success) {
        _volume = volume;
      }
    }
  }

  @override
  Future<double> getSpeed() async {
    return Future.value(1.0);
  }

  @override
  setSpeed(double speed) async {}

  @override
  close() {}

  @override
  Widget buildMediaPlayer({
    Key? key,
    bool showClosedCaptionButton = true,
    bool showFullscreenButton = true,
    bool showVolumeButton = true,
  }) {
    return AudioFileWaveforms(
      key: key,
      playerController: playerController,
      size: const Size(0, 0),
    );
  }
}
