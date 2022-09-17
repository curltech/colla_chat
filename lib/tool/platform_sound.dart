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
  remoteExampleFile,
}

///音频状态
enum AudioState {
  isPlaying,
  isPaused,
  isStopped,
  isRecording,
  isRecordingPaused,
}

///声音的记录
class PlatformSoundRecorder {
  Codec codec = Codec.opusWebM;
  AudioMedia media = AudioMedia.stream;
  FlutterSoundRecorder recorder = FlutterSoundRecorder();

  StreamSubscription? recorderSubscription;
  StreamSubscription? recordingDataSubscription;

  StreamController<Food>? recordingDataController;
  IOSink? sink;

  bool encoderSupported = false;
  bool decoderSupported = false;

  PlatformSoundRecorder();

  init() async {
    await recorder.setSubscriptionDuration(const Duration(milliseconds: 10));
    await initializeDateFormatting();
    if (!platformParams.web) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await recorder.openRecorder();
    encoderSupported = await recorder.isEncoderSupported(codec);

    if (!await recorder.isEncoderSupported(codec) && platformParams.web) {
      codec = Codec.opusWebM;
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

  void startRecorder({
    AudioMedia? audioMedia,
    String? path,
  }) async {
    try {
      // Request Microphone permission if needed
      if (!platformParams.web) {
        var status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          throw RecordingPermissionException(
              'Microphone permission not granted');
        }
      }
      if (path == null) {
        if (!platformParams.web) {
          var tempDir = await getTemporaryDirectory();
          path = '${tempDir.path}/flutter_sound${ext[codec.index]}';
        } else {
          path = '_flutter_sound${ext[codec.index]}';
        }
      }

      if (audioMedia == AudioMedia.stream) {
        assert(codec == Codec.pcm16);
        if (!platformParams.web) {
          var outputFile = File(path);
          if (outputFile.existsSync()) {
            await outputFile.delete();
          }
          sink = outputFile.openWrite();
        } else {
          sink = null; // TODO
        }
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
          sampleRate: 44000, //tSAMPLERATE,
        );
      } else {
        await recorder.startRecorder(
          toFile: path,
          codec: codec,
          bitRate: 8000,
          numChannels: 1,
          sampleRate: (codec == Codec.pcm16) ? 44000 : 8000,
        );
      }
      logger.d('startRecorder');

      recorderSubscription = recorder.onProgress!.listen((e) {
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

  void stopRecorder() async {
    try {
      await recorder.stopRecorder();
      recorder.logger.d('stopRecorder');
      cancelRecorderSubscriptions();
      cancelRecordingDataSubscription();
    } on Exception catch (err) {
      logger.d('stopRecorder error: $err');
    }
  }

  void pauseResumeRecorder() async {
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

  void Function()? onPauseResumeRecorderPressed() {
    if (recorder.isPaused || recorder.isRecording) {
      return pauseResumeRecorder;
    }
    return null;
  }

  void startStopRecorder() {
    if (recorder.isRecording || recorder.isPaused) {
      stopRecorder();
    } else {
      startRecorder();
    }
  }

  void Function()? onStartRecorderPressed() {
    // Disable the button if the selected codec is not supported
    if (!encoderSupported!) return null;
    if (media == AudioMedia.stream && codec != Codec.pcm16) return null;
    return startStopRecorder;
  }
}

///音频的播放
class PlatformSoundPlayer {
  Codec codec = Codec.opusWebM;
  AudioMedia media = AudioMedia.stream;
  FlutterSoundPlayer player = FlutterSoundPlayer();

  StreamSubscription? playerSubscription;

  IOSink? sink;

  bool encoderSupported = false;
  bool decoderSupported = false;

  PlatformSoundPlayer();

  init() async {
    await player.closePlayer();
    await player.openPlayer();
    await player.setSubscriptionDuration(const Duration(milliseconds: 10));
    await initializeDateFormatting();
    if (!platformParams.web) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    decoderSupported = await player.isDecoderSupported(codec);

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

  Future<void> startPlayer({Uint8List? data, String? filename}) async {
    try {
      if (filename != null) {
        await player.startPlayer(
            fromURI: filename,
            codec: codec,
            sampleRate: 44000,
            whenFinished: () {
              player.logger.d('Play finished');
            });
      } else if (data != null) {
        if (codec == Codec.pcm16) {
          data = await flutterSoundHelper.pcmToWaveBuffer(
            inputBuffer: data,
            numChannels: 1,
            sampleRate: (codec == Codec.pcm16 && media == AudioMedia.asset)
                ? 48000
                : 8000,
          );
          codec = Codec.pcm16WAV;
        }
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
          codec: Codec.pcm16, //_codec,
          numChannels: 1,
          sampleRate: 44000, //tSAMPLERATE,
        );
        await player.feedFromStream(data!);
      }
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

  void pauseResumePlayer() async {
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
    //playerModule.logger.d('-->seekToPlayer');
    try {
      if (player.isPlaying) {
        await player.seekToPlayer(Duration(milliseconds: milliSecs));
      }
    } on Exception catch (err) {
      player.logger.e('error: $err');
    }
  }

  void Function()? onPauseResumePlayerPressed() {
    if (player.isPaused || player.isPlaying) {
      return pauseResumePlayer;
    }
    return null;
  }
}
