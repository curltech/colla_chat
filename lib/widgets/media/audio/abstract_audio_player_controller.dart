import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:video_player/video_player.dart';

abstract class AbstractAudioPlayerController
    extends AbstractMediaPlayerController {
  ///基本的视频控制功能使用平台自定义的控制面板才需要，比如音频
  play();

  pause();

  resume();

  stop();

  seek(Duration position, {int? index});

  Future<double> getSpeed();

  setSpeed(double speed);

  Future<double> getVolume();

  setVolume(double volume);

  VideoPlayerValue? get value;

  bool get closedCaptionFile;
}
