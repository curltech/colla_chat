import 'dart:async';
import 'dart:io';

import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

///仅支持移动设备
class AnotherAudioRecorderController {
  AnotherAudioRecorder? recorder;
  Recording? _current;
  RecordingStatus _status = RecordingStatus.Unset;

  AnotherAudioRecorderController();

  Future<void> start(
    String path, {
    AudioFormat? audioFormat,
    int sampleRate = 16000,
  }) async {
    try {
      bool hasPermission = await AnotherAudioRecorder.hasPermissions;
      if (hasPermission) {
        recorder = AnotherAudioRecorder(path,
            audioFormat: audioFormat, sampleRate: sampleRate);
        await recorder!.initialized;
        await recorder!.start();
      }
      _current = recorder!.recording;
      _status = _current!.status!;
    } catch (e) {
      logger.e('recorder start $e');
    }
  }

  Future<Recording?> stop() async {
    _current = await recorder!.stop();
    _current = recorder!.recording;
    _status = _current!.status!;

    return _current;
  }

  Future<void> pause() async {
    await recorder!.pause();
    _current = recorder!.recording;
    _status = _current!.status!;
  }

  Future<void> resume() async {
    await recorder!.resume();
    _current = recorder!.recording;
    _status = _current!.status!;
  }

  RecordingStatus get status {
    return _status;
  }

  Recording? get current {
    return _current;
  }

  dispose() async {
    await recorder!.stop();
    _current = recorder!.recording;
    _status = _current!.status!;
  }
}

class AnotherAudioRecorderWidget extends StatefulWidget {
  late final AnotherAudioRecorderController controller;

  AnotherAudioRecorderWidget(
      {AnotherAudioRecorderController? controller, super.key}) {
    controller = controller ?? AnotherAudioRecorderController();
  }

  @override
  State<StatefulWidget> createState() => _AnotherAudioRecorderWidgetState();
}

class _AnotherAudioRecorderWidgetState
    extends State<AnotherAudioRecorderWidget> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _init();
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
                          case RecordingStatus.Initialized:
                            {
                              _start();
                              break;
                            }
                          case RecordingStatus.Recording:
                            {
                              _pause();
                              break;
                            }
                          case RecordingStatus.Paused:
                            {
                              _resume();
                              break;
                            }
                          case RecordingStatus.Stopped:
                            {
                              _init();
                              break;
                            }
                          default:
                            break;
                        }
                      },
                      child: _buildText(widget.controller.status),
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
        await widget.controller.start(customPath, audioFormat: AudioFormat.WAV);
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
      await widget.controller?.start('');
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
    var result = await widget.controller?.stop();
    print("Stop recording: ${result?.path}");
    print("Stop recording: ${result?.duration}");
    File file = File(result!.path!);
    print("File length: ${await file.length()}");
    setState(() {});
  }

  Widget _buildText(RecordingStatus status) {
    var text = "";
    switch (widget.controller?.status) {
      case RecordingStatus.Initialized:
        {
          text = 'Start';
          break;
        }
      case RecordingStatus.Recording:
        {
          text = 'Pause';
          break;
        }
      case RecordingStatus.Paused:
        {
          text = 'Resume';
          break;
        }
      case RecordingStatus.Stopped:
        {
          text = 'Init';
          break;
        }
      default:
        break;
    }
    return Text(text, style: TextStyle(color: Colors.white));
  }
}
