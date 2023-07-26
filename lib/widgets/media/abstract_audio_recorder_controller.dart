import 'dart:async';

import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/material.dart';

enum RecorderStatus { pause, recording, stop }

///定义音频录音控制器的接口
abstract class AbstractAudioRecorderController with ChangeNotifier {
  String? filename;
  RecorderStatus _status = RecorderStatus.stop;
  Timer? _timer;
  int _duration = -1;
  String _durationText = '';

  Future<bool> hasPermission();

  RecorderStatus get status {
    return _status;
  }

  set status(RecorderStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }

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
      if (status == RecorderStatus.recording) {
        duration = duration + 1;
        notifyListeners();
      }
    });
  }

  /// 停止录音计时
  void cancelTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
      duration = 0;
    }
  }

  int get duration {
    return _duration;
  }

  set duration(int duration) {
    if (_duration != duration) {
      _duration = duration;
      _changeDurationText();
    }
  }

  String get durationText {
    return _durationText;
  }

  _changeDurationText() {
    var duration = Duration(seconds: _duration);

    _durationText = StringUtil.durationText(duration);
  }
}
