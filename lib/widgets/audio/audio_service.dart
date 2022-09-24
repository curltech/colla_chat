import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';

///add the following initialization code to your app's main method:
///初始化音频后台服务，add background playback support and remote controls
///(notification, lock screen, headset buttons, smart watches, Android Auto and CarPlay)
///ios：	<key>UIBackgroundModes</key>
/// 	<array>
/// 		<string>audio</string>
/// 	</array>
class AudioBackground {
  Future<void> init() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );

    ///runApp(MyApp());
  }
}

///自定义音频后台服务处理器的模板
class PlatformAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  @override
  Future<void> play() async {
    ///后台服务的播放请求将转发到这里，可以调用自己的播放器进行播放
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  setSpeed(double speed) async {}

  @override
  playMediaItem(MediaItem mediaItem) async {}

  @override
  Future<void> skipToQueueItem(int index) async {}
}

///音频的后台服务
class PlatformAudioService {
  static PlatformAudioHandler? _audioHandler;

  ///注册音频后台服务的处理器，所有的操作都转发到自定义实现的处理器
  static init() async {
    _audioHandler = await AudioService.init<PlatformAudioHandler>(
      builder: () => PlatformAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.mycompany.myapp.channel.audio',
        androidNotificationChannelName: 'Music playback',
      ),
    );

    ///runApp(new MyApp());
  }
}

///音频会话的初始话处理
class AudioSessionUtil {
  static bool initStatus = false;

  ///初始化全局音频会话，设置参数
  static initCustom() async {
    if (initStatus) {
      return;
    }
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    initStatus = true;
  }

  static initMusic() async {
    if (initStatus) {
      return;
    }
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  static initSpeech() async {
    if (initStatus) {
      return;
    }
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  ///判断是否激活
  static Future<bool> setActive(AudioSession session) async {
    return await session.setActive(true);
  }

  static void handleInterruptions(
      AudioSession audioSession,
      Function()? becomingNoisyEventStream,
      Function(AudioInterruptionEvent)? interruptionEventStream,
      Function(AudioDevicesChangedEvent)? devicesChangedEventStream) {
    audioSession.becomingNoisyEventStream.listen((_) {
      becomingNoisyEventStream!();
    });

    ///event.begin,event.type,AudioInterruptionType.duck,AudioInterruptionType.pause
    audioSession.interruptionEventStream.listen((event) {
      interruptionEventStream!(event);
    });
    audioSession.devicesChangedEventStream.listen((event) {
      devicesChangedEventStream!(event);
    });
  }
}
