import 'dart:async';
import 'dart:io';

import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/audio/platform_audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

///仅支持移动设备
class AnotherAudioRecorderController extends AbstractAudioRecorderController {
  AnotherAudioRecorder? recorder;
  Recording? _current;
  RecordingStatus _status = RecordingStatus.Unset;

  AnotherAudioRecorderController();

  @override
  Future<bool> hasPermission() async {
    bool hasPermission = await AnotherAudioRecorder.hasPermissions;

    return hasPermission;
  }

  @override
  RecorderStatus get status {
    if (_status == RecordingStatus.Recording) {
      return RecorderStatus.recording;
    }
    if (_status == RecordingStatus.Paused) {
      return RecorderStatus.pause;
    }
    if (_status == RecordingStatus.Stopped) {
      return RecorderStatus.stop;
    }

    return RecorderStatus.none;
  }

  @override
  Future<void> start({String? filename}) async {
    AudioFormat audioFormat = AudioFormat.AAC;
    int sampleRate = 16000;
    try {
      bool permission = await hasPermission();
      if (permission) {
        if (filename == null) {
          final dir = await getTemporaryDirectory();
          var name = DateUtil.currentDate();
          filename = '${dir.path}/$name.mp3';
        }
        recorder = AnotherAudioRecorder(filename,
            audioFormat: audioFormat, sampleRate: sampleRate);
        await recorder!.initialized;
        await recorder!.start();
        await super.start();
      }
      _current = recorder!.recording;
      _status = _current!.status!;
    } catch (e) {
      logger.e('recorder start $e');
    }
  }

  @override
  Future<String?> stop() async {
    _current = await recorder!.stop();
    _current = recorder!.recording;
    _status = _current!.status!;

    var filename = _current!.path;
    await super.stop();

    return filename;
  }

  @override
  Future<void> pause() async {
    await recorder!.pause();
    _current = recorder!.recording;
    _status = _current!.status!;
  }

  @override
  Future<void> resume() async {
    await recorder!.resume();
    _current = recorder!.recording;
    _status = _current!.status!;
  }

  Recording? get current {
    return _current;
  }

  @override
  dispose() async {
    await recorder!.stop();
    _current = recorder!.recording;
    _status = _current!.status!;
    super.dispose();
  }
}

class PlatformAnotherAudioRecorder extends StatefulWidget {
  late final AnotherAudioRecorderController controller;

  PlatformAnotherAudioRecorder(
      {AnotherAudioRecorderController? controller, super.key}) {
    controller = controller ?? AnotherAudioRecorderController();
  }

  @override
  State<StatefulWidget> createState() => _PlatformAnotherAudioRecorderState();
}

class _PlatformAnotherAudioRecorderState
    extends State<PlatformAnotherAudioRecorder> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    try {
      if (await AnotherAudioRecorder.hasPermissions) {
        String customPath = '/another_audio_recorder_';
        Directory appDocDirectory;
//        io.Directory appDocDirectory = await getApplicationDocumentsDirectory();
        if (platformParams.ios) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = (await getExternalStorageDirectory())!;
        }

        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath = appDocDirectory.path +
            customPath +
            DateTime.now().millisecondsSinceEpoch.toString();

        // .wav <---> AudioFormat.WAV
        // .mp4 .m4a .aac <---> AudioFormat.AAC
        // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
        await widget.controller.start();
        // after initialization
        var current = widget.controller?.current;
        print(current);
        // should be "Initialized", if all working fine
        setState(() {});
      } else {
        DialogUtil.error(context, content: "You must accept permissions");
      }
    } catch (e) {
      logger.e(e);
    }
  }

  _start() async {
    try {
      await widget.controller?.start();
      var recording = widget.controller?.current;
      setState(() {});

      const tick = Duration(milliseconds: 50);
      Timer.periodic(tick, (Timer t) async {
        if (widget.controller?.status == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = widget.controller?.current;
        // print(current.status);
        setState(() {});
      });
    } catch (e) {
      print(e);
    }
  }

  _resume() async {
    await widget.controller?.resume();
    setState(() {});
  }

  _pause() async {
    await widget.controller?.pause();
    setState(() {});
  }

  _stop() async {
    var filename = await widget.controller?.stop();
    logger.i("Stop recording: $filename");
    setState(() {});
  }

  Widget _buildText() {
    var text = "";
    switch (widget.controller?.status) {
      case RecorderStatus.none:
        {
          text = 'Start';
          break;
        }
      case RecorderStatus.recording:
        {
          text = 'Pause';
          break;
        }
      case RecorderStatus.pause:
        {
          text = 'Resume';
          break;
        }
      case RecorderStatus.stop:
        {
          text = 'Init';
          break;
        }
      default:
        break;
    }
    return Text(text, style: TextStyle(color: Colors.white));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton(
                      onPressed: () async {
                        var status = widget.controller.status;
                        switch (status) {
                          case RecorderStatus.none:
                            {
                              _start();
                              break;
                            }
                          case RecorderStatus.recording:
                            {
                              _pause();
                              break;
                            }
                          case RecorderStatus.pause:
                            {
                              _resume();
                              break;
                            }
                          case RecorderStatus.stop:
                            {
                              _init();
                              break;
                            }
                          default:
                            break;
                        }
                      },
                      child: _buildText(),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.controller.status != RecordingStatus.Unset
                        ? _stop
                        : null,
                    child:
                        new Text("Stop", style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                ],
              ),
              new Text("Status : ${widget.controller.status}"),
              new Text(
                  'Avg Power: ${widget.controller.current?.metering?.averagePower}'),
              new Text(
                  'Peak Power: ${widget.controller.current?.metering?.peakPower}'),
              new Text(
                  "File path of the record: ${widget.controller.current?.path}"),
              new Text("Format: ${widget.controller.current?.audioFormat}"),
              new Text(
                  "isMeteringEnabled: ${widget.controller.current?.metering?.isMeteringEnabled}"),
              new Text("Extension : ${widget.controller.current?.extension}"),
              new Text(
                  "Audio recording duration : ${widget.controller.current?.duration.toString()}")
            ]),
      ),
    );
  }
}
