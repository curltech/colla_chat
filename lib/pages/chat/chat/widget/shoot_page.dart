import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:colla_chat/tool/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../provider/app_data_provider.dart';

class ShootPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  ShootPage(this.cameras);

  @override
  _ShootPageState createState() => _ShootPageState();
}

class _ShootPageState extends State<ShootPage> with WidgetsBindingObserver {
  late Timer _timer;
  int _timing = 0;

  late CameraController controller;
  String? imagePath;
  late String videoPath;
  VideoPlayerController? videoController;
  late VoidCallback videoPlayerListener;

  bool isReverse = false;
  bool isOnPress = false;

  CameraDescription? cameraDescription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.cameras.isNotEmpty) {
      cameraDescription = widget.cameras[!isReverse ? 0 : 1];
      onNewCameraSelected(cameraDescription!);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);

    var callback = (timer) => {
          setState(() {
            if (_timing >= 17) {
              isOnPress = false;
              onStopButtonPressed();
              if (_timer != null) {
                _timer.cancel();
              }
            } else {
              _timing = _timing + 1;
              print('当前：$_timing');
            }
          })
        };

    _timer = Timer.periodic(oneSec, callback);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: <Widget>[
        Container(
          child: Center(child: _cameraPreviewWidget()),
          color: Colors.black,
        ),
        Positioned(
          right: 10,
          top: MediaQuery.of(context).size.height / 2,
          child: _thumbnailWidget(),
        ),
        Positioned(
          left: 0.0,
          right: 0.0,
          top: 30.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              InkWell(
                child: Container(
                  width: 60.0,
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Icon(CupertinoIcons.back, color: Colors.white),
                ),
                onTap: () => Navigator.of(context).maybePop(),
              ),
              checkWidget(),
            ],
          ),
        ),
        Positioned(
          bottom: 30.0,
          left: 0,
          right: 0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(width: 40),
              Column(
                children: <Widget>[
                  !isOnPress
                      ? Padding(
                          padding: EdgeInsets.only(bottom: 45.0),
                          child: Text(
                            '轻触拍照，长按摄像',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : Text(
                          '计时: ${_timing ?? 0}',
                          style: TextStyle(color: Colors.white),
                        ),
                  Listener(
                    child: Container(
                      height: isOnPress ? 100 : 80.0,
                      width: isOnPress ? 100 : 80.0,
                      decoration: BoxDecoration(
                        color: Color(0xffe0dce2),
                        borderRadius: BorderRadius.all(
                          Radius.circular(isOnPress ? 50 : 40.0),
                        ),
                      ),
                      padding: EdgeInsets.all(isOnPress ? 30 : 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(30.0)),
                        ),
                        height: 60.0,
                        width: 60.0,
                      ),
                    ),
                    onPointerDown: (v) {
                      setState(() {
                        //开始计时
                        _timing = 0;
                        startTimer();

                        if (isOnPress) return;
                        isOnPress = true;
                        onVideoRecordButtonPressed();
                      });
                    },
                    onPointerUp: (v) {
                      setState(() {
                        if (!isOnPress) return;
                        isOnPress = false;
                        if (_timing < 2) {
                          DialogUtil.showToast('录制时间过短');
                          stopVideoRecording();
                          if (_timer != null) {
                            _timer.cancel();
                          }
                          return;
                        }
                        onStopButtonPressed();
                        if (_timer != null) {
                          _timer.cancel();
                        }
                      });
                    },
                  ),
//              onTap: () {
//                if (controller != null &&
//                    controller.value.isInitialized &&
//                    !controller.value.isRecordingVideo) {
//                  onTakePictureButtonPressed();
//                }
//              },
                ],
              ),
              Container(width: 40.0),
            ],
          ),
        )
      ],
    ));
  }

  Widget checkWidget() {
    if (widget.cameras.isEmpty) return const Text('No camera found');

    cameraDescription = widget.cameras[isReverse ? 0 : 1];
    return InkWell(
      child: Container(
        alignment: Alignment.topRight,
        width: 60.0,
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Image.asset('assets/images/chat/flip_camera_icon_nor.webp',
            fit: BoxFit.cover),
      ),
      onTap: () {
        isReverse = !isReverse;
        onNewCameraSelected(cameraDescription!);
      },
    );
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        '使用相机',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

  Widget _thumbnailWidget() {
    return Container(
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          videoController == null && imagePath == null
              ? Container()
              : SizedBox(
                  child: (videoController == null)
                      ? Image.file(File(imagePath!))
                      : Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red, width: 1.5),
                          ),
                          child: AspectRatio(
                            aspectRatio: videoController!.value.size != null
                                ? videoController!.value.aspectRatio
                                : 1.0,
                            child: VideoPlayer(videoController!),
                          ),
                        ),
                  width: 64.0,
                  height: 64.0,
                ),
          videoController == null && imagePath == null
              ? Container()
              : Container(
                  margin: EdgeInsets.only(top: 10.0),
                  width: 60.0,
                  height: 25.0,
                  child: FlatButton(
                    onPressed: () {},
                    color: Colors.white,
                    padding: EdgeInsets.all(0),
                    child: Text(
                      '发送',
                      style: TextStyle(fontSize: 11.0),
                    ),
                  ),
                )
        ],
      ),
    );
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.camera_alt),
          color: Colors.blue,
          onPressed: controller != null &&
                  controller.value.isInitialized &&
                  !controller.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.videocam),
          color: Colors.blue,
          onPressed: controller != null &&
                  controller.value.isInitialized &&
                  !controller.value.isRecordingVideo
              ? onVideoRecordButtonPressed
              : null,
        ),
        IconButton(
          icon: controller != null && controller.value.isRecordingPaused
              ? Icon(Icons.play_arrow)
              : Icon(Icons.pause),
          color: Colors.blue,
          onPressed: controller != null &&
                  controller.value.isInitialized &&
                  controller.value.isRecordingVideo
              ? (controller != null && controller.value.isRecordingPaused
                  ? onResumeButtonPressed
                  : onPauseButtonPressed)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          color: Colors.red,
          onPressed: controller != null &&
                  controller.value.isInitialized &&
                  controller.value.isRecordingVideo
              ? onStopButtonPressed
              : null,
        )
      ],
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: true,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        DialogUtil.showToast(
            'Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((String? filePath) {
      if (mounted) {
        setState(() {
          imagePath = filePath;
          videoController?.dispose();
          videoController = null;
        });
        if (filePath != null) DialogUtil.showToast('图片保存到$filePath');
      }
    });
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((String? filePath) {
      if (mounted) setState(() {});
      if (filePath != null) DialogUtil.showToast('开始录制');
    });
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((_) {
      if (mounted) setState(() {});
      DialogUtil.showToast('视频记录到$videoPath');
    });
  }

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      if (mounted) setState(() {});
      DialogUtil.showToast('录制视频暂停');
    });
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) setState(() {});
      DialogUtil.showToast('录制视频恢复');
    });
  }

  Future<String?> startVideoRecording() async {
    if (!controller.value.isInitialized) {
      DialogUtil.showToast('异常: 首先选择一个相机');
      return null;
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Movies/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    if (controller.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return null;
    }

    try {
      videoPath = filePath;
      await controller.startVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }

    await _startVideoPlayer();
  }

  Future<void> pauseVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.pauseVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoRecording() async {
    if (!controller.value.isRecordingVideo) {
      return null;
    }

    try {
      await controller.resumeVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _startVideoPlayer() async {
    final VideoPlayerController vcontroller =
        VideoPlayerController.file(File(videoPath));
    videoPlayerListener = () {
      if (videoController != null && videoController?.value.size != null) {
        // Refreshing the state to update video player with the correct ratio.
        if (mounted) setState(() {});
        videoController?.removeListener(videoPlayerListener);
      }
    };
    vcontroller.addListener(videoPlayerListener);
    await vcontroller.setLooping(true);
    await vcontroller.initialize();
    await videoController?.dispose();
    if (mounted) {
      setState(() {
        imagePath = null;
        videoController = vcontroller;
      });
    }
    await vcontroller.play();
  }

  Future<String?> takePicture() async {
    if (!controller.value.isInitialized) {
      DialogUtil.showToast('异常: 首先选择一个相机');
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final XFile filePath; //'$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      filePath = await controller.takePicture();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath.path;
  }

  void _showCameraException(CameraException e) {
    logger.e(e.code, e.description);
    DialogUtil.showToast('Error: ${e.code}\n${e.description}');
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (_timer != null) {
      _timer.cancel();
    }
  }
}
