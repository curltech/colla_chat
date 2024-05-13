import 'package:audio_session/audio_session.dart';
import 'package:colla_chat/plugin/talker_logger.dart';

///代表本应用的全局音频会话，用于本应用有声音的时候通知其他应用，或者其他应用有声音的时候本应用的处理
///类构建的时候进行初始化
class GlobalAudioSession {
  AudioSession? _session;

  GlobalAudioSession();

  AudioSession? get session {
    return _session;
  }

  ///初始化平台定制的全局音频会话
  init() async {
    _session ??= await AudioSession.instance;
    await _session?.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.defaultToSpeaker,
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
  }

  ///初始化成播放音乐的配置
  initMusic() async {
    await _session?.configure(const AudioSessionConfiguration.music());
  }

  ///初始化成说话的配置
  initSpeech() async {
    await _session?.configure(const AudioSessionConfiguration.speech());
  }

  ///激活或者钝化会话，一般情况下不用直接调用
  Future<bool> setActive(bool active) async {
    return await _session!.setActive(active);
  }

  Future<void> handleInterruptions(
      //处于嘈杂环境下的处理
      Function()? becomingNoisyEventStream,
      //音频被中断的处理
      Function(AudioInterruptionEvent)? interruptionEventStream,
      //音频设备改变的处理
      Function(AudioDevicesChangedEvent)? devicesChangedEventStream) async {
    _session ??= await AudioSession.instance;

    /// 用户打开外置播放，进入吵杂环境
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
        ///begin表示另一个app开始播放声音
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              //自己应该降低音量
              break;
            case AudioInterruptionType.pause:
              //自己应该暂停播放
              break;
            case AudioInterruptionType.unknown:
              //自己应该暂停播放
              break;
          }
        } else {
          ///表示另一个app播放声音结束
          switch (event.type) {
            case AudioInterruptionType.duck:
              //自己应该恢复音量
              break;
            case AudioInterruptionType.pause:
              //自己应该继续播放
              break;
            case AudioInterruptionType.unknown:
              //自己不应该继续播放
              break;
          }
        }
      }
    });

    ///设备改变事件，比如换了耳机和外置播放
    _session?.devicesChangedEventStream.listen((event) {
      logger.i('Devices added:   ${event.devicesAdded}');
      logger.i('Devices removed: ${event.devicesRemoved}');
      if (devicesChangedEventStream != null) {
        devicesChangedEventStream(event);
      }
    });
  }
}

GlobalAudioSession globalAudioSession = GlobalAudioSession();
