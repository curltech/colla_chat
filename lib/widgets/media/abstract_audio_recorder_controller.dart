import 'dart:async';

import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/material.dart';

enum RecorderStatus { pause, recording, stop }

///定义音频录音控制器的接口
abstract class AbstractAudioRecorderController {
  String? filename;
  ValueNotifier<RecorderStatus> status =
      ValueNotifier<RecorderStatus>(RecorderStatus.stop);
  Timer? _timer;
  final ValueNotifier<int> duration = ValueNotifier<int>(-1);
  String _durationText = '';

  Future<bool> hasPermission();

  /// 开始录音
  Future<void> start() async {
    // if (filename == null) {
    //   final dir = await getTemporaryDirectory();
    //   var name = DateUtil.currentDate();
    //   filename = '${dir.path}/$name.ma4';
    // }
    startTimer();
  }

  /// 停止录音
  Future<String?> stop() async {
    cancelTimer();

    return null;
  }

  /// 暂停录音
  Future<void> pause();

  /// 继续录音
  Future<void> resume();

  /// 录音开始计时
  void startTimer() {
    cancelTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (status.value == RecorderStatus.recording) {
        duration.value = duration.value + 1;
      }
    });
  }

  /// 停止录音计时
  void cancelTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      duration.value = 0;
    }
  }

  void setDuration(int duration) {
    if (this.duration.value != duration) {
      this.duration.value = duration;
      _changeDurationText();
    }
  }

  String get durationText {
    return _durationText;
  }

  void _changeDurationText() {
    var duration = Duration(seconds: this.duration.value);

    _durationText = StringUtil.durationText(duration);
  }
}
