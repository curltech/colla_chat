import 'dart:async';

import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/sherpa/sherpa_config_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:record/record.dart';

import 'package:sherpa_onnx/sherpa_onnx.dart';

class OnlineSpeechToText {
  String? text;
  final AudioRecorder audioRecorder = AudioRecorder();
  String _last = '';
  int _index = 0;
  bool _isInitialized = false;

  OnlineRecognizer? _recognizer;
  OnlineStream? _stream;
  final int _sampleRate = 16000;

  StreamSubscription<RecordState>? _recordSub;
  final ValueNotifier<RecordState> recordState =
      ValueNotifier<RecordState>(RecordState.stop);

  OnlineSpeechToText() {
    _recordSub = audioRecorder.onStateChanged().listen((recordState) {
      _updateRecordState(recordState);
    });
  }

  /// 初始化识别器和识别流
  init() async {
    if (!_isInitialized) {
      initBindings();
      _recognizer = await SherpaConfigUtil.createOnlineRecognizer();
      _stream = _recognizer?.createStream();

      _isInitialized = true;
    }
  }

  /// 识别音频字节
  recognize(List<int> audioData) async {
    await init();
    final samplesFloat32 =
        SherpaConfigUtil.convertBytesToFloat32(Uint8List.fromList(audioData));

    _stream!.acceptWaveform(samples: samplesFloat32, sampleRate: _sampleRate);
    while (_recognizer!.isReady(_stream!)) {
      _recognizer!.decode(_stream!);
    }

    /// 识别录入的音频流
    final String text = _recognizer!.getResult(_stream!).text;
    this.text = _last;
    if (text != '') {
      if (_last == '') {
        this.text = '$_index: $text';
      } else {
        this.text = '$_index: $text\n$_last';
      }
    }

    if (_recognizer!.isEndpoint(_stream!)) {
      _recognizer!.reset(_stream!);
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
            recognize(data);
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
    _stream!.free();
    _stream = _recognizer!.createStream();

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
    _stream?.free();
    _recognizer?.free();
  }
}
