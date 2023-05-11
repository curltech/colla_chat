import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

abstract class AbstractAudioPlayerController
    extends AbstractMediaPlayerController {
  AbstractAudioPlayerController() : super() {
    fileType = FileType.any;
    allowedExtensions = ['mp3', 'wav'];
  }

  VideoPlayerValue _value = const VideoPlayerValue(duration: Duration.zero);
  bool _closedCaptionFile = false;

  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  play();

  pause();

  resume();

  stop();

  seek(Duration position, {int? index});

  Future<double> getSpeed() {
    return Future.value(_value.playbackSpeed);
  }

  setSpeed(double speed) {
    _value = _value.copyWith(duration: _value.duration, playbackSpeed: speed);
  }

  Future<double> getVolume() {
    return Future.value(_value.volume);
  }

  setVolume(double volume) {
    _value = _value.copyWith(duration: _value.duration, volume: volume);
  }

  VideoPlayerValue get value {
    return _value;
  }

  set value(VideoPlayerValue value) {
    _value = _value.copyWith(
        duration: value.duration,
        size: value.size,
        position: value.position,
        caption: value.caption,
        captionOffset: value.captionOffset,
        buffered: value.buffered,
        isInitialized: value.isInitialized,
        isPlaying: value.isPlaying,
        isLooping: value.isLooping,
        isBuffering: value.isBuffering,
        volume: value.volume,
        playbackSpeed: value.playbackSpeed,
        rotationCorrection: value.rotationCorrection,
        errorDescription: value.errorDescription);
  }

  bool get closedCaptionFile {
    return _closedCaptionFile;
  }

  set closedCaptionFile(bool closedCaptionFile) {
    _closedCaptionFile = closedCaptionFile;
    notifyListeners();
  }
}
