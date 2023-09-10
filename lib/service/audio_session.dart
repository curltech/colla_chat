import 'package:audio_session/audio_session.dart';

///音频会话的初始化服务
class GlobalAudioSession {
  AudioSession? _session;

  GlobalAudioSession() {
    init();
  }

  AudioSession? get session {
    return _session;
  }

  ///初始化平台定制的全局音频会话
  init() async {
    _session ??= await AudioSession.instance;
    await _session?.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
    await _session?.setActive(true);
  }

  initMusic() async {
    _session ??= await AudioSession.instance;
    await _session?.configure(const AudioSessionConfiguration.music());
  }

  initSpeech() async {
    _session ??= await AudioSession.instance;
    await _session?.configure(const AudioSessionConfiguration.speech());
  }

  ///判断是否激活
  Future<bool> setActive() async {
    _session ??= await AudioSession.instance;
    return await _session!.setActive(true);
  }

  Future<void> handleInterruptions(
      //处于嘈杂环境下的处理
      Function()? becomingNoisyEventStream,
      //音频被中断的处理
      Function(AudioInterruptionEvent)? interruptionEventStream,
      //音频设备改变的处理
      Function(AudioDevicesChangedEvent)? devicesChangedEventStream) async {
    _session ??= await AudioSession.instance;
    _session?.becomingNoisyEventStream.listen((_) {
      if (becomingNoisyEventStream != null) {
        becomingNoisyEventStream();
      }
    });

    ///音频被中断的事件：中断开始和中断结束
    _session?.interruptionEventStream.listen((event) {
      if (interruptionEventStream != null) {
        interruptionEventStream(event);
      } else {
        ///例子，begin表示中断开始
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              break;
            case AudioInterruptionType.pause:
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        } else {
          ///表示中断结束
          switch (event.type) {
            case AudioInterruptionType.duck:
              break;
            case AudioInterruptionType.pause:
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      }
    });
    _session?.devicesChangedEventStream.listen((event) {
      if (devicesChangedEventStream != null) {
        devicesChangedEventStream(event);
      }
    });
  }
}

GlobalAudioSession globalAudioSession = GlobalAudioSession();
