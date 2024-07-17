import 'dart:async';

import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/sherpa/sherpa_config_util.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'package:sherpa_onnx/sherpa_onnx.dart';

/// 支持在线的录音识别，也支持单独的音频字节识别
class SherpaSpeechToText {
  bool isOffline = true;
  String? text;
  final AudioRecorder audioRecorder = AudioRecorder();
  String _last = '';
  int _index = 0;
  bool _isInitialized = false;

  OnlineRecognizer? _onlineRecognizer;
  OfflineRecognizer? _offlineRecognizer;
  OnlineStream? _onlineStream;
  OfflineStream? _offlineStream;
  final int _sampleRate = 16000;

  StreamSubscription<RecordState>? _recordSub;
  final ValueNotifier<RecordState> recordState =
      ValueNotifier<RecordState>(RecordState.stop);

  SherpaSpeechToText() {
    _recordSub = audioRecorder.onStateChanged().listen((recordState) {
      _updateRecordState(recordState);
    });
  }

  /// 初始化识别器和识别流
  init() async {
    if (!_isInitialized) {
      initBindings();
      if (isOffline) {
        _offlineRecognizer = await SherpaConfigUtil.createOfflineRecognizer();
        _offlineStream = _offlineRecognizer?.createStream();
      } else {
        _onlineRecognizer = await SherpaConfigUtil.createOnlineRecognizer();
        _onlineStream = _onlineRecognizer?.createStream();
      }
      _isInitialized = true;
    }
  }

  /// 识别音频字节
  recognize({List<int>? audioData, String? wavFilename}) async {
    await init();
    Float32List? samples;
    if (wavFilename != null) {
      final WaveData waveData = readWave(wavFilename);
      samples = waveData.samples;
    } else if (audioData != null) {
      samples =
          SherpaConfigUtil.convertBytesToFloat32(Uint8List.fromList(audioData));
    } else {
      return;
    }
    if (_onlineStream != null) {
      _onlineStream!.acceptWaveform(samples: samples, sampleRate: _sampleRate);
      while (_onlineRecognizer!.isReady(_onlineStream!)) {
        _onlineRecognizer!.decode(_onlineStream!);
      }

      /// 识别录入的音频流
      final String text = _onlineRecognizer!.getResult(_onlineStream!).text;
      this.text = _last;
      if (text != '') {
        if (_last == '') {
          this.text = '$_index: $text';
        } else {
          this.text = '$_index: $text\n$_last';
        }
      }

      if (_onlineRecognizer!.isEndpoint(_onlineStream!)) {
        _onlineRecognizer!.reset(_onlineStream!);
        if (text != '') {
          _last = this.text!;
          _index += 1;
        }
      }
    }
    if (_offlineStream != null) {
      _offlineStream!.acceptWaveform(samples: samples, sampleRate: _sampleRate);
      _offlineRecognizer!.decode(_offlineStream!);

      /// 识别录入的音频流
      final String text = _offlineRecognizer!.getResult(_offlineStream!).text;
      this.text = _last;
      if (text != '') {
        if (_last == '') {
          this.text = '$_index: $text';
        } else {
          this.text = '$_index: $text\n$_last';
        }
      }

      if (text != '') {
        _last = this.text!;
        _index += 1;
      }
    }
  }

  /// 启动录制音频, 并进行识别
  Future<void> start() async {
    await init();
    try {
      if (await audioRecorder.hasPermission()) {
        const encoder = AudioEncoder.pcm16bits;

        if (!await _isEncoderSupported(encoder)) {
          return;
        }

        final devs = await audioRecorder.listInputDevices();
        logger.i(devs.toString());

        const config = RecordConfig(
          encoder: encoder,
          sampleRate: 16000,
          numChannels: 1,
        );

        /// 监听录入的音频
        final stream = await audioRecorder.startStream(config);

        stream.listen(
          (data) {
            recognize(audioData: data);
          },
          onDone: () {
            logger.i('stream stopped.');
          },
        );
      }
    } catch (e) {
      logger.e('e');
    }
  }

  /// 停止音频录制
  Future<void> stop() async {
    _onlineStream?.free();
    _onlineStream = _onlineRecognizer?.createStream();

    await audioRecorder.stop();
  }

  /// 暂停音频录制
  Future<void> pause() async {
    await audioRecorder.pause();
  }

  /// 继续音频录制
  Future<void> resume() async {
    await audioRecorder.resume();
  }

  void _updateRecordState(RecordState recordState) {
    this.recordState.value = recordState;
  }

  Future<bool> _isEncoderSupported(AudioEncoder encoder) async {
    final isSupported = await audioRecorder.isEncoderSupported(
      encoder,
    );

    if (!isSupported) {
      logger.i('${encoder.name} is not supported on this platform.');
      logger.i('Supported encoders are:');

      for (final e in AudioEncoder.values) {
        if (await audioRecorder.isEncoderSupported(e)) {
          logger.i('- ${encoder.name}');
        }
      }
    }

    return isSupported;
  }

  void dispose() {
    _recordSub?.cancel();
    audioRecorder.dispose();
    _onlineStream?.free();
    _onlineRecognizer?.free();
    _offlineStream?.free();
    _offlineRecognizer?.free();
  }
}
