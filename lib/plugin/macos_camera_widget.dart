import 'dart:io';

import 'package:camera_macos/camera_macos_controller.dart';
import 'package:camera_macos/camera_macos_device.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_macos/camera_macos_view.dart';
import 'package:camera_macos/exceptions.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class MacosCameraWidget extends StatefulWidget {
  final Function(XFile file)? onFile;
  final Function(Uint8List data, String mimeType)? onData;

  const MacosCameraWidget({super.key, this.onFile, this.onData});

  @override
  MacosCameraWidgetState createState() => MacosCameraWidgetState();
}

class MacosCameraWidgetState extends State<MacosCameraWidget> {
  GlobalKey cameraKey = GlobalKey();
  ValueNotifier<CameraMacOSController?> cameraController =
      ValueNotifier<CameraMacOSController?>(null);
  ValueNotifier<CameraMacOSMode> cameraMacOSMode =
      ValueNotifier<CameraMacOSMode>(CameraMacOSMode.photo);
  late TextEditingController durationController;
  late double durationValue;
  Uint8List? lastImagePreviewData;
  Uint8List? lastRecordedVideoData;
  XFile? mediaFile;
  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  ValueNotifier<List<CameraMacOSDevice>> videoDevices =
      ValueNotifier<List<CameraMacOSDevice>>([]);
  int selectedVideoIndex = -1;

  List<CameraMacOSDevice> audioDevices = [];
  int selectedAudioIndex = -1;

  ValueNotifier<bool> enableAudio = ValueNotifier<bool>(true);
  bool usePlatformView = false;

  @override
  void initState() {
    super.initState();
    durationValue = 15;
    durationController = TextEditingController(text: "$durationValue");
    durationController.addListener(() {
      setState(() {
        double? textFieldContent = double.tryParse(durationController.text);
        if (textFieldContent == null) {
          durationValue = 15;
          durationController.text = "$durationValue";
        } else {
          durationValue = textFieldContent;
        }
      });
    });
    _initVideoDevices();
    _initAudioDevices();
  }

  String get cameraButtonText {
    String label = AppLocalizations.t("Do something");
    if (cameraMacOSMode.value == CameraMacOSMode.photo) {
      label = AppLocalizations.t("Take Picture");
    } else {
      if (cameraController.value?.isRecording ?? false) {
        label = AppLocalizations.t("Stop recording");
      } else {
        label = AppLocalizations.t("Record video");
      }
    }
    return label;
  }

  Future<String> get videoFilePath async =>
      p.join((await getApplicationDocumentsDirectory()).path, "output.mp4");

  Future<void> _initVideoDevices() async {
    try {
      videoDevices.value = await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.video,
      );
      if (videoDevices.value.isNotEmpty) {
        selectedVideoIndex = 0;
      }
    } catch (e) {
      DialogUtil.error(context, content: e.toString());
    }
  }

  Future<void> _initAudioDevices() async {
    try {
      audioDevices = await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.audio,
      );
      if (audioDevices.isNotEmpty) {
        selectedAudioIndex = 0;
      }
    } catch (e) {
      DialogUtil.error(context, content: e.toString());
    }
  }

  ///当视频设备识别后，显示预览界面
  _buildPreviewWidget() {
    return ValueListenableBuilder(
        valueListenable: videoDevices,
        builder: (BuildContext context, List<CameraMacOSDevice> videoDevices,
            Widget? child) {
          if (videoDevices.isNotEmpty) {
            return CameraMacOSView(
              key: cameraKey,
              deviceId: videoDevices[selectedVideoIndex].deviceId,
              audioDeviceId: audioDevices[selectedAudioIndex].deviceId,
              fit: BoxFit.fill,
              cameraMode: cameraMacOSMode.value,
              onCameraInizialized: (CameraMacOSController controller) {
                cameraController.value = controller;
              },
              onCameraDestroyed: () {
                return Text(AppLocalizations.t("Camera Destroyed!"));
              },
              enableAudio: enableAudio.value,
              usePlatformView: usePlatformView,
            );
          }
          return Center(
              child: Text(AppLocalizations.t("Video Devices is empty")));
        });
  }

  _buildLastImagePreviewData() {
    return lastImagePreviewData != null
        ? Container(
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(
                  color: Colors.lightBlue,
                  width: 10,
                ),
              ),
            ),
            child: Image.memory(
              lastImagePreviewData!,
              height: 50,
              width: 90,
            ),
          )
        : Container();
  }

  void _toggleAudioMode() {
    enableAudio.value = !enableAudio.value;
  }

  Future<void> _toggleCamera() async {
    if (videoDevices.value.isNotEmpty) {
      if (selectedVideoIndex < videoDevices.value.length - 1) {
        selectedVideoIndex++;
      } else {
        if (selectedVideoIndex != 0) {
          selectedVideoIndex = 0;
        }
      }
    }
  }

  /// 镜头切换按钮
  Widget _buildCameraToggleWidget() {
    var videoDevices = this.videoDevices.value;
    if (videoDevices.length > 1) {
      var cameraController = this.cameraController.value;
      Widget toggleWidget = IconButton(
        icon: const Icon(Icons.cameraswitch),
        color: myself.primary,
        onPressed: cameraController != null && cameraController.isRecording
            ? null
            : _toggleCamera,
      );

      return toggleWidget;
    }
    return Container();
  }

  Future<void> _startVideoPlayer() async {
    if (platformParams.desktop) {
      return;
    }
    if (mediaFile == null) {
      return;
    }

    final VideoPlayerController vController =
        VideoPlayerController.file(File(mediaFile!.path));

    videoPlayerListener = () {
      if (videoController != null) {
        // Refreshing the state to update video player with the correct ratio.
        if (mounted) {
          setState(() {});
        }
        videoController!.removeListener(videoPlayerListener!);
      }
    };
    vController.addListener(videoPlayerListener!);
    await vController.setLooping(true);
    await vController.initialize();
    await videoController?.dispose();
    if (mounted) {
      setState(() {
        videoController = vController;
      });
    }
    await vController.play();
  }

  /// 显示捕获图片和录像的缩略图
  Widget _buildThumbnailWidget() {
    final VideoPlayerController? videoController = this.videoController;

    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (videoController == null && mediaFile == null)
              Container()
            else
              SizedBox(
                width: 64.0,
                height: 64.0,
                child: (videoController == null)
                    ? Image.file(File(mediaFile!.path))
                    : Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.pink)),
                        child: Center(
                          child: AspectRatio(
                              aspectRatio: videoController.value.size != null
                                  ? videoController.value.aspectRatio
                                  : 1.0,
                              child: VideoPlayer(videoController)),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  /// 相机的所有控制按钮
  Widget _buildCameraController(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Container(),
        ),
        Container(
            color: Colors.grey.withOpacity(AppOpacity.lgOpacity),
            child: Center(
                child: Column(children: <Widget>[
              _buildCaptureModeWidget(),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  children: <Widget>[
                    _buildBackButton(),
                    _buildCameraToggleWidget(),
                    _buildThumbnailWidget(),
                  ],
                ),
              )
            ]))),
      ],
    );
  }

  /// 拍照和录像按钮
  Widget _buildCaptureModeWidget() {
    var primary = myself.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ValueListenableBuilder(
            valueListenable: enableAudio,
            builder: (BuildContext context, bool enableAudio, Widget? child) {
              return IconButton(
                icon: Icon(enableAudio ? Icons.volume_up : Icons.volume_mute),
                color: primary,
                onPressed: _toggleAudioMode,
                tooltip: AppLocalizations.t('Toggle AudioMode'),
              );
            }),
        ValueListenableBuilder(
            valueListenable: cameraController,
            builder: (BuildContext context,
                CameraMacOSController? cameraController, Widget? child) {
              return ValueListenableBuilder(
                  valueListenable: cameraMacOSMode,
                  builder: (BuildContext context,
                      CameraMacOSMode cameraMacOSMode, Widget? child) {
                    return CircleTextButton(
                      onPressed: _captureMedia,
                      elevation: 2.0,
                      backgroundColor: primary,
                      padding: const EdgeInsets.all(15.0),
                      child: _getCaptureIcon(),
                    );
                  });
            }),
        ValueListenableBuilder(
            valueListenable: cameraMacOSMode,
            builder: (BuildContext context, CameraMacOSMode cameraMacOSMode,
                Widget? child) {
              return IconButton(
                icon: Icon(cameraMacOSMode == CameraMacOSMode.photo
                    ? Icons.camera_alt
                    : Icons.videocam),
                color: primary,
                onPressed: () {
                  if (cameraMacOSMode == CameraMacOSMode.photo) {
                    this.cameraMacOSMode.value = CameraMacOSMode.video;
                  } else if (cameraMacOSMode == CameraMacOSMode.video) {
                    this.cameraMacOSMode.value = CameraMacOSMode.photo;
                  }
                },
                tooltip: AppLocalizations.t('Toggle Picture Video'),
              );
            }),
      ],
    );
  }

  Icon _getCaptureIcon() {
    CameraMacOSController? cameraController = this.cameraController.value;
    if (cameraController != null) {
      if (cameraMacOSMode.value == CameraMacOSMode.photo) {
        return const Icon(
          Icons.camera,
          size: 48.0,
          color: Colors.white,
        );
      } else {
        if (cameraController.isRecording) {
          return const Icon(
            Icons.stop,
            size: 48.0,
            color: Colors.white,
          );
        } else {
          return const Icon(
            Icons.play_arrow,
            size: 48.0,
            color: Colors.white,
          );
        }
      }
    } else {
      return const Icon(
        Icons.camera,
        size: 48.0,
        color: Colors.grey,
      );
    }
  }

  Future<void> startRecording() async {
    CameraMacOSController? cameraController = this.cameraController.value;
    if (cameraController != null) {
      try {
        String urlPath = await videoFilePath;
        await cameraController.recordVideo(
          maxVideoDuration: durationValue,
          url: urlPath,
          enableAudio: enableAudio.value,
          onVideoRecordingFinished:
              (CameraMacOSFile? result, CameraMacOSException? exception) {
            setState(() {});
            if (exception != null) {
              DialogUtil.error(context, content: exception.toString());
            } else if (result != null) {
              DialogUtil.info(context,
                  content: AppLocalizations.t('Video saved at ') +
                      (result.url ?? ''));
            }
          },
        );
      } catch (e) {
        DialogUtil.error(context, content: e.toString());
      }
    }
  }

  Future<void> stopRecording() async {
    CameraMacOSController? cameraController = this.cameraController.value;
    if (cameraController != null) {
      if (cameraController.isRecording) {
        CameraMacOSFile? videoData = await cameraController.stopRecording();
        if (videoData != null) {
          lastRecordedVideoData = videoData.bytes;
          lastImagePreviewData = null;
          if (mounted) {
            DialogUtil.info(context,
                content: AppLocalizations.t('Video saved at ') +
                    (videoData.url ?? ''));
          }
        }
      }
    }
  }

  /// 拍照或者开始录像
  Future<void> _captureMedia() async {
    CameraMacOSController? cameraController = this.cameraController.value;
    if (cameraController != null) {
      if (cameraMacOSMode.value == CameraMacOSMode.photo) {
        _takePicture();
      } else {
        if (cameraController.isRecording) {
          stopRecording();
        } else {
          startRecording();
        }
      }
    }
  }

  _takePicture() async {
    CameraMacOSController? cameraController = this.cameraController.value;
    if (cameraController != null) {
      CameraMacOSFile? imageData = await cameraController.takePicture();
      if (imageData != null) {
        lastImagePreviewData = imageData.bytes;
        lastRecordedVideoData = null;
        if (mounted) {
          DialogUtil.info(context,
              content: AppLocalizations.t('Picture saved at ') +
                  (imageData.url ?? ''));
        }
      }
    }
  }

  Widget _buildBackButton() {
    var iconButton = IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 32),
      color: myself.primary,
      onPressed: () async {
        await _back();
      },
    );

    return iconButton;
  }

  _back() async {
    if (widget.onData != null) {
      if (lastImagePreviewData != null) {
        widget.onData!(lastImagePreviewData!, ChatMessageMimeType.jpg.name);
      }
      if (lastRecordedVideoData != null) {
        widget.onData!(lastRecordedVideoData!, ChatMessageMimeType.mp4.name);
      }
    }
    if (widget.onFile != null) {
      if (lastImagePreviewData != null) {
        String? filename = await FileUtil.writeTempFileAsBytes(
            lastImagePreviewData!,
            extension: ChatMessageMimeType.jpg.name);
         mediaFile = XFile(filename!,
            mimeType: ChatMessageMimeType.jpg.name,
            length: lastImagePreviewData!.length);
        widget.onFile!(mediaFile!);
      }
      if (lastRecordedVideoData != null) {
        String? filename = await FileUtil.writeTempFileAsBytes(
            lastRecordedVideoData!,
            extension: ChatMessageMimeType.mp4.name);
        mediaFile = XFile(filename!,
            mimeType: ChatMessageMimeType.mp4.name,
            length: lastRecordedVideoData!.length);
        widget.onFile!(mediaFile!);
      }
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  /// 预览窗口数据，分辨率，尺寸
  // Widget _buildPreviewData() {
  //   if (macOSController != null && macOSController.value.isInitialized) {
  //     Size? previewSize = controller!.value.previewSize;
  //     var resolutionPreset = controller!.resolutionPreset;
  //     Widget previewText = Container();
  //     if (previewSize != null) {
  //       previewText = Align(
  //           alignment: Alignment.topRight,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               CommonAutoSizeText(
  //                 '${AppLocalizations.t('Resolution')}: ${resolutionPreset.name}',
  //                 style: const TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 12.0,
  //                   fontWeight: FontWeight.w400,
  //                 ),
  //               ),
  //               CommonAutoSizeText(
  //                 '${AppLocalizations.t('Size')}: ${previewSize.width.toStringAsFixed(0)}x${previewSize.height.toStringAsFixed(0)}',
  //                 style: const TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 12.0,
  //                   fontWeight: FontWeight.w400,
  //                 ),
  //               ),
  //             ],
  //           ));
  //     }
  //     return previewText;
  //   }
  //
  //   return Container();
  // }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: Colors.black,
              width: 3.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.0),
            child: Center(
              child: _buildPreviewWidget(),
            ),
          ),
        ),
        _buildCameraController(context),
      ],
    );
  }
}
