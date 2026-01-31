import 'dart:async';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/media_stream_util.dart';
import 'package:colla_chat/transport/webrtc/screen_select_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LocalMediaStreamWidget extends StatelessWidget with DataTileMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'local_media_stream';

  @override
  IconData get iconData => Icons.video_call;

  @override
  String get title => 'LocalMediaStream';

  

  LocalMediaStreamWidget({super.key}) {
    videoRenderer.initialize();
    MediaStreamUtil.enumerateDevices()
        .then((List<MediaDeviceInfo> mediaDevices) {
      audioOutputDevices.assignAll(
          mediaDevices.where((device) => device.kind == 'audiooutput'));
      audioInputDevices.assignAll(
          mediaDevices.where((device) => device.kind == 'audiointput'));
      videoOutputDevices.assignAll(
          mediaDevices.where((device) => device.kind == 'videooutput'));
      videoInputDevices.assignAll(
          mediaDevices.where((device) => device.kind == 'videoinput'));
    });

    MediaStreamUtil.onDeviceChange((List<MediaDeviceInfo> mediaDevices) {
      audioOutputDevices.assignAll(
          mediaDevices.where((device) => device.kind == 'audiooutput'));
      audioInputDevices.assignAll(
          mediaDevices.where((device) => device.kind == 'audiointput'));
      videoOutputDevices.assignAll(
          mediaDevices.where((device) => device.kind == 'videooutput'));
      videoInputDevices.assignAll(
          mediaDevices.where((device) => device.kind == 'videoinput'));
    });
  }

  final RxList<MediaDeviceInfo> audioOutputDevices = <MediaDeviceInfo>[].obs;
  final RxList<MediaDeviceInfo> audioInputDevices = <MediaDeviceInfo>[].obs;
  final RxList<MediaDeviceInfo> videoOutputDevices = <MediaDeviceInfo>[].obs;
  final RxList<MediaDeviceInfo> videoInputDevices = <MediaDeviceInfo>[].obs;

  final videoRenderer = RTCVideoRenderer();

  final Rx<MediaStream?> mediaStream = Rx<MediaStream?>(null);

  //呼叫状态
  final RxBool callStatus = false.obs;

  final RxBool displayStatus = false.obs;

  final RxBool torchOn = false.obs;

  final RxBool speakerOn = false.obs;

  final RxBool mute = false.obs;

  final RxDouble volume = 1.0.obs;

  final Rx<MediaRecorder?> mediaRecorder = Rx<MediaRecorder?>(null);

  final RxInt selectedVideoFps = 30.obs;

  final RxDouble selectedVideoWidth = 1280.0.obs;

  final RxDouble selectedVideoHeight = 720.0.obs;

  final Rx<String?> selectedAudioInputDevice = Rx<String?>(null);
  final Rx<String?> selectedAudioOutputDevice = Rx<String?>(null);
  final Rx<String?> selectedVideoInputDevice = Rx<String?>(null);
  final Rx<String?> selectedVideoOutputDevice = Rx<String?>(null);

  List<ActionData> _buildVideoActionData() {
    List<ActionData> actionData = [];

    if (callStatus.value) {
      actionData.add(
        ActionData(
          label: 'toggleTorch',
          tooltip: 'Toggle torch',
          icon: Icon(torchOn.value ? Icons.flash_off : Icons.flash_on),
        ),
      );
    }
    if (callStatus.value) {
      actionData.add(
        ActionData(
          label: 'switchVideo',
          tooltip: 'Switch video',
          icon: const Icon(Icons.switch_video),
        ),
      );
    }
    if (callStatus.value) {
      actionData.add(
        ActionData(
          label: 'switchSpeaker',
          tooltip: 'Switch speaker',
          icon:
              Icon(speakerOn.value ? Icons.speaker_phone_outlined : Icons.mic),
        ),
      );
    }
    if (callStatus.value) {
      actionData.add(
        ActionData(
          label: 'switchMute',
          tooltip: 'Switch mute',
          icon: Icon(mute.value
              ? Icons.volume_off_outlined
              : Icons.record_voice_over_outlined),
        ),
      );
    }
    if (callStatus.value || displayStatus.value) {
      actionData.add(
        ActionData(
          label: 'increaseVolume',
          tooltip: 'Increase volume',
          icon: const Icon(Icons.volume_up_outlined),
        ),
      );
    }
    if (callStatus.value || displayStatus.value) {
      actionData.add(
        ActionData(
          label: 'decreaseVolume',
          tooltip: 'Decrease volume',
          icon: const Icon(Icons.volume_down_outlined),
        ),
      );
    }
    if (callStatus.value || displayStatus.value) {
      actionData.add(
        ActionData(
          label: 'captureFrame',
          tooltip: 'Capture frame',
          icon: const Icon(Icons.camera),
        ),
      );
    }
    if (platformParams.mobile && (callStatus.value || displayStatus.value)) {
      if (mediaRecorder.value == null) {
        actionData.add(
          ActionData(
            label: 'startRecording',
            tooltip: 'Start recording',
            icon: const Icon(Icons.fiber_manual_record),
          ),
        );
      }
      if (mediaRecorder.value != null) {
        actionData.add(
          ActionData(
            label: 'stopRecording',
            tooltip: 'Stop recording',
            icon: const Icon(Icons.stop),
          ),
        );
      }
    }
    return actionData;
  }

  Future<void> _onVideoAction(BuildContext context, int index, String name,
      {String? value}) async {
    switch (name) {
      case 'toggleTorch':
        _toggleTorch();
        break;
      case 'switchVideo':
        _toggleCamera();
        break;
      case 'switchSpeaker':
        _switchSpeaker();
        break;
      case 'switchMute':
        _switchMute();
        break;
      case 'increaseVolume':
        _increaseVolume();
        break;
      case 'decreaseVolume':
        _decreaseVolume();
        break;
      case 'captureFrame':
        _captureFrame(context);
        break;
      case 'startRecording':
        _startRecording();
        break;
      case 'stopRecording':
        _stopRecording();
        break;
      default:
        break;
    }
  }

  Future<void> _showVideoActionCard(BuildContext context) async {
    List<ActionData> actions = _buildVideoActionData();
    if (actions.isEmpty) {
      return;
    }
    await DialogUtil.show(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            elevation: 0.0,
            insetPadding: EdgeInsets.zero,
            child: Container(
              margin: const EdgeInsets.all(0.0),
              padding: const EdgeInsets.only(bottom: 0.0),
              child: DataActionCard(
                actions: actions,
                height: 200,
                width: appDataProvider.secondaryBodyWidth,
                iconSize: 36,
                mainAxisSpacing: 20,
                crossAxisSpacing: 60,
                onPressed: (int index, String name, {String? value}) {
                  _onVideoAction(context, index, name, value: value);
                  Navigator.pop(context);
                },
                crossAxisCount: 4,
              ),
            ),
          );
        });
  }

  List<ActionData> _buildVideoFps(BuildContext context) {
    List<ActionData> actionData = [];
    actionData.add(
      ActionData(
        label: '8 fps',
        tooltip: '8 fps',
        icon: const Icon(Icons.eight_mp_outlined),
        onTap: (int index, String label, {String? value}) {
          selectedVideoFps.value = 8;
          Navigator.pop(context);
        },
      ),
    );
    actionData.add(
      ActionData(
        label: '15 fps',
        tooltip: '15 fps',
        icon: const Icon(Icons.fifteen_mp_outlined),
        onTap: (int index, String label, {String? value}) {
          selectedVideoFps.value = 15;
          Navigator.pop(context);
        },
      ),
    );
    actionData.add(
      ActionData(
        label: '30 fps',
        tooltip: '30 fps',
        icon: const Icon(Icons.thirty_fps_outlined),
        onTap: (int index, String label, {String? value}) {
          selectedVideoFps.value = 30;
          Navigator.pop(context);
        },
      ),
    );
    actionData.add(
      ActionData(
        label: '60 fps',
        tooltip: '60 fps',
        icon: const Icon(Icons.sixty_fps_outlined),
        onTap: (int index, String label, {String? value}) {
          selectedVideoFps.value = 60;
          Navigator.pop(context);
        },
      ),
    );

    return actionData;
  }

  List<ActionData> _buildVideoSize(context) {
    List<ActionData> actionData = [];
    actionData.add(
      ActionData(
        label: '320x180',
        tooltip: '320x180',
        icon: const Icon(Icons.photo_size_select_small_outlined),
        onTap: (int index, String label, {String? value}) {
          selectedVideoWidth.value = 320;
          selectedVideoHeight.value = 180;
          Navigator.pop(context);
        },
      ),
    );
    actionData.add(
      ActionData(
        label: '640x360',
        tooltip: '640x360',
        icon: const Icon(Icons.width_normal_outlined),
        onTap: (int index, String label, {String? value}) {
          selectedVideoWidth.value = 640;
          selectedVideoHeight.value = 360;
          Navigator.pop(context);
        },
      ),
    );
    actionData.add(
      ActionData(
        label: '1280x720',
        tooltip: '1280x720',
        icon: const Icon(Icons.photo_size_select_large_outlined),
        onTap: (int index, String label, {String? value}) {
          selectedVideoWidth.value = 1280;
          selectedVideoHeight.value = 720;
          Navigator.pop(context);
        },
      ),
    );
    actionData.add(
      ActionData(
        label: '1920x1080',
        tooltip: '1920x1080',
        icon: const Icon(Icons.width_full),
        onTap: (int index, String label, {String? value}) {
          selectedVideoWidth.value = 1920;
          selectedVideoHeight.value = 1080;
          Navigator.pop(context);
        },
      ),
    );

    return actionData;
  }

  List<ActionData> _buildAudioInput(BuildContext context) {
    List<ActionData> actionData = [];
    for (var audioInputDevice in audioInputDevices.value) {
      String deviceId = audioInputDevice.deviceId;
      actionData.add(
        ActionData(
          label: audioInputDevice.label,
          icon: const Icon(Icons.settings_voice),
          onTap: (int index, String label, {String? value}) {
            selectedAudioInputDevice.value = deviceId;
            Navigator.pop(context);
          },
        ),
      );
    }

    return actionData;
  }

  List<ActionData> _buildAudioOutput(BuildContext context) {
    List<ActionData> actionData = [];
    for (var audioOutputDevice in audioOutputDevices.value) {
      String deviceId = audioOutputDevice.deviceId;
      actionData.add(
        ActionData(
          label: audioOutputDevice.label,
          icon: const Icon(Icons.volume_down_alt),
          onTap: (int index, String label, {String? value}) {
            selectedAudioOutputDevice.value = deviceId;
            Navigator.pop(context);
          },
        ),
      );
    }

    return actionData;
  }

  List<ActionData> _buildVideoInput(BuildContext context) {
    List<ActionData> actionData = [];
    for (var videoInputDevice in videoInputDevices.value) {
      String deviceId = videoInputDevice.deviceId;
      actionData.add(
        ActionData(
          label: videoInputDevice.label,
          icon: const Icon(Icons.switch_camera),
          onTap: (int index, String label, {String? value}) {
            selectedVideoInputDevice.value = deviceId;
            Navigator.pop(context);
          },
        ),
      );
    }

    return actionData;
  }

  List<ActionData> _buildVideoOutput(BuildContext context) {
    List<ActionData> actionData = [];
    for (var videoOutputDevice in videoOutputDevices.value) {
      String deviceId = videoOutputDevice.deviceId;
      actionData.add(
        ActionData(
          label: videoOutputDevice.label,
          icon: const Icon(Icons.monitor),
          onTap: (int index, String label, {String? value}) {
            selectedVideoOutputDevice.value = deviceId;
            Navigator.pop(context);
          },
        ),
      );
    }

    return actionData;
  }

  List<ActionData> _buildVideoSetting(BuildContext context) {
    List<ActionData> actionData = [];
    actionData.add(
      ActionData(
        label: 'Audio input',
        icon: const Icon(Icons.settings_voice),
        onTap: (int index, String label, {String? value}) {
          List<ActionData> actions = _buildAudioInput(context);
          if (actions.isEmpty) {
            return;
          }
          DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
            return DataActionCard(
              actions: _buildAudioInput(context),
              height: 200,
              width: appDataProvider.secondaryBodyWidth,
              iconSize: 36,
              mainAxisSpacing: 20,
              crossAxisSpacing: 60,
              crossAxisCount: 4,
            );
          });
        },
      ),
    );
    actionData.add(ActionData(
        label: 'Audio output',
        onTap: (int index, String label, {String? value}) {
          List<ActionData> actions = _buildAudioOutput(context);
          if (actions.isEmpty) {
            return;
          }
          DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
            return DataActionCard(
              actions: _buildAudioOutput(context),
              height: 200,
              width: appDataProvider.secondaryBodyWidth,
              iconSize: 36,
              mainAxisSpacing: 20,
              crossAxisSpacing: 60,
              crossAxisCount: 4,
            );
          });
        },
        icon: const Icon(Icons.volume_down_alt)));
    actionData.add(ActionData(
        label: 'Video input',
        onTap: (int index, String label, {String? value}) {
          List<ActionData> actions = _buildVideoInput(context);
          if (actions.isEmpty) {
            return;
          }
          DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
            return DataActionCard(
              actions: _buildVideoInput(context),
              height: 200,
              width: appDataProvider.secondaryBodyWidth,
              iconSize: 36,
              mainAxisSpacing: 20,
              crossAxisSpacing: 60,
              crossAxisCount: 4,
            );
          });
        },
        icon: const Icon(Icons.switch_camera)));
    actionData.add(ActionData(
        label: 'Video output',
        onTap: (int index, String label, {String? value}) {
          List<ActionData> actions = _buildVideoOutput(context);
          if (actions.isEmpty) {
            return;
          }
          DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
            return DataActionCard(
              actions: _buildVideoOutput(context),
              height: 200,
              width: appDataProvider.secondaryBodyWidth,
              iconSize: 36,
              mainAxisSpacing: 20,
              crossAxisSpacing: 60,
              crossAxisCount: 4,
            );
          });
        },
        icon: const Icon(Icons.monitor)));
    actionData.add(ActionData(
        label: 'Video size',
        onTap: (int index, String label, {String? value}) {
          List<ActionData> actions = _buildVideoSize(context);
          if (actions.isEmpty) {
            return;
          }
          DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
            return DataActionCard(
              actions: _buildVideoSize(context),
              height: 200,
              width: appDataProvider.secondaryBodyWidth,
              iconSize: 36,
              mainAxisSpacing: 20,
              crossAxisSpacing: 60,
              crossAxisCount: 4,
            );
          });
        },
        icon: const Icon(Icons.screenshot_monitor)));
    actionData.add(ActionData(
        label: 'Fps',
        onTap: (int index, String label, {String? value}) {
          List<ActionData> actions = _buildVideoFps(context);
          if (actions.isEmpty) {
            return;
          }
          DialogUtil.popModalBottomSheet(builder: (BuildContext context) {
            return DataActionCard(
              actions: _buildVideoFps(context),
              height: 200,
              width: appDataProvider.secondaryBodyWidth,
              iconSize: 36,
              mainAxisSpacing: 20,
              crossAxisSpacing: 60,
              crossAxisCount: 4,
            );
          });
        },
        icon: const Icon(Icons.menu)));

    return actionData;
  }

  Future<void> _showVideoSetting(BuildContext context) async {
    await DialogUtil.show(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            elevation: 0.0,
            insetPadding: EdgeInsets.zero,
            child: Container(
              margin: const EdgeInsets.all(0.0),
              padding: const EdgeInsets.only(bottom: 0.0),
              child: DataActionCard(
                actions: _buildVideoSetting(context),
                height: 200,
                width: appDataProvider.secondaryBodyWidth,
                iconSize: 36,
                mainAxisSpacing: 20,
                crossAxisSpacing: 60,
                crossAxisCount: 4,
              ),
            ),
          );
        });
  }

  Future<void> _makeCall() async {
    mediaStream.value = await MediaStreamUtil.createVideoMediaStream(
      width: selectedVideoWidth.value,
      height: selectedVideoHeight.value,
      frameRate: selectedVideoFps.value,
      videoInputId: selectedVideoInputDevice.value,
      audioInputId: selectedAudioInputDevice.value,
    );
    videoRenderer.srcObject = mediaStream.value;
    callStatus.value = true;
  }

  Future<void> _hangUp() async {
    mediaStream.value?.dispose();
    mediaStream.value = null;
    videoRenderer.srcObject = null;
    callStatus.value = false;
    displayStatus.value = false;
  }

  Future<void> _makeDisplay(BuildContext context) async {
    DesktopCapturerSource? source;
    if (!platformParams.ios) {
      source = await DialogUtil.show<DesktopCapturerSource>(
        context: context,
        builder: (context) => Dialog(child: ScreenSelectDialog()),
      );
    }
    if (source == null) {
      return;
    }
    mediaStream.value = await MediaStreamUtil.createDisplayMediaStream(
        selectedSource: source, frameRate: selectedVideoFps.value);
    videoRenderer.srcObject = mediaStream.value;
    displayStatus.value = true;
  }

  void _startRecording() async {
    if (mediaStream.value == null) throw Exception('Stream is not initialized');
    if (platformParams.ios) {
      logger.e('Recording is not available on iOS');
      return;
    }

    final filePath = await FileUtil.getTempFilename(extension: 'mp4');
    mediaRecorder.value = MediaRecorder();

    final videoTrack = mediaStream.value!
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    await mediaRecorder.value!.start(
      filePath,
      videoTrack: videoTrack,
    );
  }

  void _stopRecording() async {
    await mediaRecorder.value?.stop();
    mediaRecorder.value = null;
  }

  void _toggleTorch() async {
    if (mediaStream.value == null) throw Exception('Stream is not initialized');
    torchOn.value = !torchOn.value;
    MediaStreamUtil.setTorch(mediaStream.value!, torchOn.value);
  }

  void setZoom(double zoomLevel) async {
    if (mediaStream.value == null) throw Exception('Stream is not initialized');
    MediaStreamUtil.setZoom(mediaStream.value!, zoomLevel);
  }

  void _toggleCamera() async {
    if (mediaStream.value == null) throw Exception('Stream is not initialized');
    await MediaStreamUtil.switchCamera(mediaStream.value!);
  }

  void _switchSpeaker() async {
    if (mediaStream.value == null) throw Exception('Stream is not initialized');
    speakerOn.value = !speakerOn.value;
    await MediaStreamUtil.switchSpeaker(mediaStream.value!, speakerOn.value);
  }

  void _switchMute() async {
    if (mediaStream.value == null) throw Exception('Stream is not initialized');
    mute.value = !mute.value;
    await MediaStreamUtil.setMicrophoneMute(mediaStream.value!, mute.value);
  }

  void _increaseVolume() async {
    if (mediaStream.value == null) throw Exception('Stream is not initialized');
    double volume = this.volume.value;
    if (volume <= 0.9) {
      this.volume.value = volume + 0.1;
      await MediaStreamUtil.setVolume(mediaStream.value!, this.volume.value);
    }
  }

  void _decreaseVolume() async {
    if (mediaStream.value == null) throw Exception('Stream is not initialized');
    double volume = this.volume.value;
    if (volume >= 0.1) {
      this.volume.value = volume - 0.1;
      await MediaStreamUtil.setVolume(mediaStream.value!, this.volume.value);
    }
  }

  void _captureFrame(BuildContext context) async {
    if (mediaStream.value == null) throw Exception('Stream is not initialized');
    final frame = await MediaStreamUtil.captureFrame(mediaStream.value!);
    await DialogUtil.show(
        context: context,
        builder: (context) => AlertDialog(
              content:
                  Image.memory(frame.asUint8List(), height: 720, width: 1280),
              actions: <Widget>[
                TextButton(
                  onPressed: Navigator.of(context, rootNavigator: true).pop,
                  child: Text(AppLocalizations.t('Ok')),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      List<Widget>? rightWidgets = [];
      if (callStatus.value || displayStatus.value) {
        rightWidgets.add(IconButton(
            tooltip: AppLocalizations.t('Hang up'),
            onPressed: () {
              _hangUp();
            },
            icon: const Icon(Icons.call_end)));
      } else {
        rightWidgets.add(IconButton(
            tooltip: AppLocalizations.t('Make call'),
            onPressed: () {
              _makeCall();
            },
            icon: const Icon(Icons.phone)));
        rightWidgets.add(IconButton(
            tooltip: AppLocalizations.t('Make display'),
            onPressed: () {
              _makeDisplay(context);
            },
            icon: const Icon(Icons.monitor_outlined)));
      }
      rightWidgets.add(IconButton(
          tooltip: AppLocalizations.t('Video setting'),
          onPressed: () {
            _showVideoSetting(context);
          },
          icon: const Icon(Icons.display_settings_outlined)));

      var appBarView = AppBarView(
          title: title,
          helpPath: routeName,
          withLeading: withLeading,
          rightWidgets: rightWidgets,
          child: GestureDetector(onLongPress: () {
            _showVideoActionCard(context);
          }, child: OrientationBuilder(
            builder: (context, orientation) {
              return Center(
                  child: Container(
                margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                decoration: const BoxDecoration(color: Colors.black),
                child: VisibilityDetector(
                  key: ObjectKey(videoRenderer),
                  onVisibilityChanged: (VisibilityInfo info) {
                    if (info.visibleFraction == 0) {
                      _stopRecording();
                      _hangUp();
                    }
                  },
                  child: RTCVideoView(videoRenderer, mirror: false),
                ),
              ));
            },
          )));

      return appBarView;
    });
  }
}
