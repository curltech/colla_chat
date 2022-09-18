import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

///音频媒体的来源
enum AudioMedia {
  file,
  buffer,
  asset,
  stream,
}

///音频状态
enum AudioState {
  isPlaying,
  isPaused,
  isStopped,
  isRecording,
  isRecordingPaused,
}

class AudioUtil {
  static bool initStatus = false;

  ///初始化全局音频会话，设置参数
  static initAudioSession() async {
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
}

///声音的记录
class PlatformSoundRecorder {
  //缺省录音编码
  Codec codec;

  //AudioMedia media = AudioMedia.stream;
  FlutterSoundRecorder recorder = FlutterSoundRecorder();

  //录音流数据的监听器
  StreamSubscription? recorderSubscription;
  StreamSubscription? recordingDataSubscription;

  //录音数据控制器
  StreamController<Food>? recordingDataController;

  IOSink? sink;

  bool encoderSupported = false;

  PlatformSoundRecorder({this.codec = Codec.opusWebM});

  //初始化录音器
  init() async {
    //录音器的监听频率
    await recorder.setSubscriptionDuration(const Duration(milliseconds: 10));
    await initializeDateFormatting();
    //申请麦克风权限
    if (!platformParams.web) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    recordingDataController = StreamController<Food>();
    await recorder.openRecorder();
    encoderSupported = await recorder.isEncoderSupported(codec);

    if (!encoderSupported && platformParams.web) {
      codec = Codec.opusWebM;
    }
    await AudioUtil.initAudioSession();
  }

  void cancelRecorderSubscriptions() {
    if (recorderSubscription != null) {
      recorderSubscription!.cancel();
      recorderSubscription = null;
    }
  }

  void cancelRecordingDataSubscription() {
    if (recordingDataSubscription != null) {
      recordingDataSubscription!.cancel();
      recordingDataSubscription = null;
    }
    recordingDataController = null;
    if (sink != null) {
      sink!.close();
      sink = null;
    }
  }

  Future<void> close() async {
    try {
      await recorder.closeRecorder();
    } on Exception {
      logger.e('Released unsuccessful');
    }
  }

  Future<IOSink?> createTemporarySink() async {
    var dir = await getTemporaryDirectory();
    var path = '${dir.path}/flutter_sound${ext[codec.index]}';
    if (!platformParams.web) {
      var outputFile = File(path);
      if (outputFile.existsSync()) {
        await outputFile.delete();
      }
      sink = outputFile.openWrite();
    } else {
      path = '_flutter_sound${ext[codec.index]}';
    }
    return sink;
  }

  ///开始录音，path为带路径的文件或者不带路径的文件名（临时目录），表示写入文件
  ///否则写入控制器的流
  Future<void> startRecorder({
    String? filename,
  }) async {
    try {
      if (filename == null) {
        //录音数据写入流
        sink = await createTemporarySink();
        recordingDataController = StreamController<Food>();
        recordingDataSubscription =
            recordingDataController!.stream.listen((buffer) {
          if (buffer is FoodData) {
            sink!.add(buffer.data!);
          }
        });
        await recorder.startRecorder(
          toStream: recordingDataController!.sink,
          codec: codec,
          numChannels: 1,
          sampleRate: 44000,
        );
      } else {
        //录音数据写入指定文件
        await recorder.startRecorder(
          toFile: filename,
          codec: codec,
          bitRate: 8000,
          numChannels: 1,
          sampleRate: (codec == Codec.pcm16) ? 44000 : 8000,
        );
      }
      logger.d('startRecorder');

      recorderSubscription =
          recorder.onProgress!.listen((RecordingDisposition e) {
        var date = DateTime.fromMillisecondsSinceEpoch(
            e.duration.inMilliseconds,
            isUtc: true);
        var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
      });
    } on Exception catch (err) {
      logger.e('startRecorder error: $err');
      stopRecorder();
      cancelRecordingDataSubscription();
      cancelRecorderSubscriptions();
    }
  }

  Future<void> stopRecorder() async {
    try {
      await recorder.stopRecorder();
      recorder.logger.d('stopRecorder');
      cancelRecorderSubscriptions();
      cancelRecordingDataSubscription();
    } on Exception catch (err) {
      logger.d('stopRecorder error: $err');
    }
  }

  Future<void> pauseResumeRecorder() async {
    try {
      if (recorder.isPaused) {
        await recorder.resumeRecorder();
      } else {
        await recorder.pauseRecorder();
        assert(recorder.isPaused);
      }
    } on Exception catch (err) {
      recorder.logger.e('error: $err');
    }
  }

  Future<void> startStopRecorder() async {
    if (recorder.isRecording || recorder.isPaused) {
      await stopRecorder();
    } else {
      await startRecorder();
    }
  }
}

///音频的播放
class PlatformSoundPlayer {
  Codec codec;
  FlutterSoundPlayer player = FlutterSoundPlayer();
  StreamSubscription? playerSubscription;
  bool decoderSupported = false;

  //流模式播放的缓冲池
  Uint8List buffer = Uint8List(4096);

  PlatformSoundPlayer({this.codec = Codec.opusWebM});

  init() async {
    await player.setSubscriptionDuration(const Duration(milliseconds: 10));
    decoderSupported = await player.isDecoderSupported(codec);
    await AudioUtil.initAudioSession();
  }

  void cancelPlayerSubscriptions() {
    if (playerSubscription != null) {
      playerSubscription!.cancel();
      playerSubscription = null;
    }
  }

  Future<void> close() async {
    try {
      await player.closePlayer();
    } on Exception {
      logger.e('Released unsuccessful');
    }
  }

  final int blockSize = 4096;

  //用于流模式播放音频数据，写入数据到缓冲池，外部调用的时候可以循环写入
  Future<void> writeBuffer(Uint8List data) async {
    var lnData = 0;
    var totalLength = data.length;
    while (totalLength > 0 && !player.isStopped) {
      var bsize = totalLength > blockSize ? blockSize : totalLength;
      await player.feedFromStream(data.sublist(lnData, lnData + bsize));
      lnData += bsize;
      totalLength -= bsize;
    }
  }

  //播放，数据来源有文件，资产文件，流以及麦克风的回放
  //如果文件名是asset开头，表示是资产文件，采用fromDataBuffer播放
  //否则采用文件方式播放
  //如果data不为空，采用fromDataBuffer播放
  //如果bufferFn
  Future<void> startPlayer({
    String? filename,
    Uint8List? data,
  }) async {
    try {
      if (filename != null) {
        if (filename.startsWith('assets/')) {
          var pos = filename.lastIndexOf('.');
          var ext = filename.substring(pos);
          if (ext.toLowerCase() == 'wav') {
            codec = Codec.pcm16WAV;
          }
          data = (await rootBundle.load(filename)).buffer.asUint8List();
          if (codec == Codec.pcm16) {
            // data = FlutterSoundHelper().waveToPCMBuffer(
            //   inputBuffer: data,
            // );
            //add wav header
            data = await flutterSoundHelper.pcmToWaveBuffer(
              inputBuffer: data,
              numChannels: 1,
              sampleRate: (codec == Codec.pcm16) ? 48000 : 8000,
            );
            codec = Codec.pcm16WAV;
          }
        } else {
          await player.startPlayer(
              fromURI: filename,
              codec: codec,
              sampleRate: 44000,
              whenFinished: () {
                player.logger.d('Play finished');
              });
        }
      }
      if (data != null) {
        await player.startPlayer(
            fromDataBuffer: data,
            sampleRate: 8000,
            codec: codec,
            whenFinished: () {
              logger.d('Play finished');
            });
      } else {
        //stream
        await player.startPlayerFromStream(
          codec: Codec.pcm16,
          numChannels: 1,
          sampleRate: 44000,
        );
        await writeBuffer(buffer);
      }
      //await player.startPlayerFromMic();
    } on Exception catch (err) {
      logger.e('error: $err');
    }
  }

  Future<void> stopPlayer() async {
    try {
      await player.stopPlayer();
      logger.d('stopPlayer');
      if (playerSubscription != null) {
        await playerSubscription!.cancel();
        playerSubscription = null;
      }
    } on Exception catch (err) {
      logger.d('error: $err');
    }
  }

  Future<void> pauseResumePlayer() async {
    try {
      if (player.isPlaying) {
        await player.pausePlayer();
      } else {
        await player.resumePlayer();
      }
    } on Exception catch (err) {
      logger.e('error: $err');
    }
  }

  Future<void> seekToPlayer(int milliSecs) async {
    try {
      if (player.isPlaying) {
        await player.seekToPlayer(Duration(milliseconds: milliSecs));
      }
    } on Exception catch (err) {
      player.logger.e('error: $err');
    }
  }

  Future<void> setSpeed(double speed) async {
    speed = speed > 1.0 ? 1.0 : speed;
    await player.setSpeed(
      speed,
    );
  }

  Future<void> setVolume(double volume) async {
    volume = volume > 1.0 ? 1.0 : volume;
    await player.setVolume(
      volume,
    );
  }
}
