import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class MobileCameraWidget extends StatefulWidget {
  final Function(XFile file)? onFile;

  const MobileCameraWidget({Key? key, this.onFile}) : super(key: key);

  @override
  State<MobileCameraWidget> createState() {
    return _MobileCameraWidgetState();
  }
}

class _MobileCameraWidgetState extends State<MobileCameraWidget>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  List<CameraDescription> cameras = [];
  int cameraIndex = -1;
  bool isPicture = true;
  CameraController? controller;
  XFile? mediaFile;
  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  bool enableAudio = true;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  late AnimationController _flashModeControlRowAnimationController;
  late Animation<double> _flashModeControlRowAnimation;
  late AnimationController _exposureModeControlRowAnimationController;
  late Animation<double> _exposureModeControlRowAnimation;
  late AnimationController _focusModeControlRowAnimationController;
  late Animation<double> _focusModeControlRowAnimation;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  @override
  void initState() {
    super.initState();

    ///监听系统级事件
    WidgetsBinding.instance.addObserver(this);

    ///闪光灯和对焦动画
    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureModeControlRowAnimation = CurvedAnimation(
      parent: _exposureModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _focusModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusModeControlRowAnimation = CurvedAnimation(
      parent: _focusModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _toggleCamera();
  }

  Future<List<CameraDescription>> _fetchCameras() async {
    if (cameras.isEmpty) {
      try {
        cameras = await availableCameras();
        if (cameras.isEmpty) {
          cameraIndex = -1;
          logger.i('No available cameras');
        } else {
          cameraIndex = 0;
          logger.e('Found camera: ${cameras[0].name}');
        }
      } on PlatformException catch (e) {
        logger.e('Failed to fetch cameras: ${e.code}: ${e.message}');
      }
    }

    return cameras;
  }

  /// 系统传来的应用状态事件
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    /// 应用进入后台和回复前台
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _createSelectedCamera(cameraController.description);
    }
  }

  void _logError(String code, String? message) {
    if (message != null) {
      logger.e('Error: $code\nError Message: $message');
    } else {
      logger.e('Error: $code');
    }
  }

  /// 相机的所有控制按钮
  Widget _buildCameraController(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Container(),
        ),
        Container(
            color: Colors.white.withOpacity(0.2),
            child: Center(
                child: Column(children: <Widget>[
              _buildCameraModeWidget(),
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

  /// 预览窗口数据，分辨率，尺寸
  Widget _buildPreviewData() {
    final CameraController? cameraController = controller;
    if (cameraController != null && cameraController.value.isInitialized) {
      Size? previewSize = controller!.value.previewSize;
      var resolutionPreset = controller!.resolutionPreset;
      Widget previewText = Container();
      if (previewSize != null) {
        previewText = Align(
            alignment: Alignment.topRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.t('Resolution') +
                      ': ${resolutionPreset.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  AppLocalizations.t('Size') +
                      ': ${previewSize.width.toStringAsFixed(0)}x${previewSize.height.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ));
      }
      return previewText;
    }

    return Container();
  }

  /// 预览窗口
  Widget _buildPreviewWidget() {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return myself.avatarImage!;
    } else {
      Size? previewSize = controller!.value.previewSize;
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          controller!,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onTapDown: (TapDownDetails details) =>
                  onViewFinderTap(details, constraints),
            );
          }),
        ),
      );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  ///处理放大缩小的手势
  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }

  /// 显示捕获图片和录像的缩略图
  Widget _buildThumbnailWidget() {
    final VideoPlayerController? localVideoController = videoController;

    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (localVideoController == null && mediaFile == null)
              Container()
            else
              SizedBox(
                width: 64.0,
                height: 64.0,
                child: (localVideoController == null)
                    ? (
                        // The captured image on the web contains a network-accessible URL
                        // pointing to a location within the browser. It may be displayed
                        // either with Image.network or Image.memory after loading the image
                        // bytes to memory.
                        kIsWeb
                            ? Image.network(mediaFile!.path)
                            : Image.file(File(mediaFile!.path)))
                    : Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.pink)),
                        child: Center(
                          child: AspectRatio(
                              aspectRatio:
                                  localVideoController.value.size != null
                                      ? localVideoController.value.aspectRatio
                                      : 1.0,
                              child: VideoPlayer(localVideoController)),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  /// 闪光，曝光，旋转开关的工具按钮，只有移动设备才会显示
  Widget _buildCameraModeWidget() {
    var primary = appDataProvider.themeData.colorScheme.primary;
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.flash_on),
              color: primary,
              onPressed: controller != null ? _toggleFlashMode : null,
              tooltip: 'Toggle FlashMode',
            ),
            // The exposure and focus mode are currently not supported on the web.
            ...!kIsWeb
                ? <Widget>[
                    IconButton(
                      icon: const Icon(Icons.exposure),
                      color: primary,
                      onPressed:
                          controller != null ? _toggleExposureMode : null,
                      tooltip: 'Toggle ExposureMode',
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_center_focus),
                      color: primary,
                      onPressed: controller != null ? _toggleFocusMode : null,
                      tooltip: 'Toggle FocusMode',
                    )
                  ]
                : <Widget>[],

            IconButton(
              icon: Icon(controller?.value.isCaptureOrientationLocked ?? false
                  ? Icons.screen_lock_rotation
                  : Icons.screen_rotation),
              color: primary,
              onPressed:
                  controller != null ? _toggleCaptureOrientationLock : null,
              tooltip: 'Toggle CaptureOrientationLock',
            ),
          ],
        ),
        _buildFlashModeWidget(),
        _buildExposureModeWidget(),
        _buildFocusModeWidget(),
      ],
    );
  }

  ///闪光灯按钮
  Widget _buildFlashModeWidget() {
    var primary = appDataProvider.themeData.colorScheme.primary;
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.flash_off),
              color: controller?.value.flashMode == FlashMode.off
                  ? Colors.orange
                  : primary,
              onPressed: controller != null
                  ? () => _setFlashMode(FlashMode.off)
                  : null,
              tooltip: 'Set FlashMode Off',
            ),
            IconButton(
              icon: const Icon(Icons.flash_auto),
              color: controller?.value.flashMode == FlashMode.auto
                  ? Colors.orange
                  : primary,
              onPressed: controller != null
                  ? () => _setFlashMode(FlashMode.auto)
                  : null,
              tooltip: 'Set FlashMode Auto',
            ),
            IconButton(
              icon: const Icon(Icons.flash_on),
              color: controller?.value.flashMode == FlashMode.always
                  ? Colors.orange
                  : primary,
              onPressed: controller != null
                  ? () => _setFlashMode(FlashMode.always)
                  : null,
              tooltip: 'Set FlashMode Always',
            ),
            IconButton(
              icon: const Icon(Icons.highlight),
              color: controller?.value.flashMode == FlashMode.torch
                  ? Colors.orange
                  : primary,
              onPressed: controller != null
                  ? () => _setFlashMode(FlashMode.torch)
                  : null,
              tooltip: 'Set FlashMode Torch',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExposureModeWidget() {
    var primary = appDataProvider.themeData.colorScheme.primary;
    final ButtonStyle styleAuto = TextButton.styleFrom(
      // TODO(darrenaustin): Migrate to new API once it lands in stable: https://github.com/flutter/flutter/issues/105724
      // ignore: deprecated_member_use
      primary: controller?.value.exposureMode == ExposureMode.auto
          ? Colors.orange
          : primary,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      // TODO(darrenaustin): Migrate to new API once it lands in stable: https://github.com/flutter/flutter/issues/105724
      // ignore: deprecated_member_use
      primary: controller?.value.exposureMode == ExposureMode.locked
          ? Colors.orange
          : primary,
    );

    return SizeTransition(
      sizeFactor: _exposureModeControlRowAnimation,
      child: ClipRect(
        child: Container(
          color: Colors.grey.shade50,
          child: Column(
            children: <Widget>[
              Center(
                child: Text(AppLocalizations.t('Exposure Mode')),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    style: styleAuto,
                    onPressed: controller != null
                        ? () => _setExposureMode(ExposureMode.auto)
                        : null,
                    onLongPress: () {
                      if (controller != null) {
                        controller!.setExposurePoint(null);
                        _showInSnackBar(
                            AppLocalizations.t('Resetting exposure point'));
                      }
                    },
                    child: Text(AppLocalizations.t('Auto')),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed: controller != null
                        ? () => _setExposureMode(ExposureMode.locked)
                        : null,
                    child: Text(AppLocalizations.t('Locked')),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed: controller != null
                        ? () => controller!.setExposureOffset(0.0)
                        : null,
                    child: Text(AppLocalizations.t('Reset Offset')),
                  ),
                ],
              ),
              Center(
                child: Text(AppLocalizations.t('Exposure Offset')),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_minAvailableExposureOffset.toString()),
                  Slider(
                    value: _currentExposureOffset,
                    min: _minAvailableExposureOffset,
                    max: _maxAvailableExposureOffset,
                    label: _currentExposureOffset.toString(),
                    onChanged: _minAvailableExposureOffset ==
                            _maxAvailableExposureOffset
                        ? null
                        : _setExposureOffset,
                  ),
                  Text(_maxAvailableExposureOffset.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///对焦模式按钮
  Widget _buildFocusModeWidget() {
    var primary = appDataProvider.themeData.colorScheme.primary;
    final ButtonStyle styleAuto = TextButton.styleFrom(
      // TODO(darrenaustin): Migrate to new API once it lands in stable: https://github.com/flutter/flutter/issues/105724
      // ignore: deprecated_member_use
      primary: controller?.value.focusMode == FocusMode.auto
          ? Colors.orange
          : primary,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      // TODO(darrenaustin): Migrate to new API once it lands in stable: https://github.com/flutter/flutter/issues/105724
      // ignore: deprecated_member_use
      primary: controller?.value.focusMode == FocusMode.locked
          ? Colors.orange
          : primary,
    );

    return SizeTransition(
      sizeFactor: _focusModeControlRowAnimation,
      child: ClipRect(
        child: Container(
          color: Colors.grey.shade50,
          child: Column(
            children: <Widget>[
              Center(
                child: Text(AppLocalizations.t('Focus Mode')),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextButton(
                    style: styleAuto,
                    onPressed: controller != null
                        ? () => _setFocusMode(FocusMode.auto)
                        : null,
                    onLongPress: () {
                      if (controller != null) {
                        controller!.setFocusPoint(null);
                      }
                      _showInSnackBar(
                          AppLocalizations.t('Resetting focus point'));
                    },
                    child: Text(AppLocalizations.t('Auto')),
                  ),
                  TextButton(
                    style: styleLocked,
                    onPressed: controller != null
                        ? () => _setFocusMode(FocusMode.locked)
                        : null,
                    child: Text(AppLocalizations.t('Locked')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 拍照和录像按钮
  Widget _buildCaptureModeWidget() {
    final CameraController? cameraController = controller;
    var primary = appDataProvider.themeData.colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(enableAudio ? Icons.volume_up : Icons.volume_mute),
          color: primary,
          onPressed: controller != null ? _toggleAudioMode : null,
          tooltip: 'Toggle AudioMode',
        ),
        IconButton(
          icon: Icon(isPicture ? Icons.camera_alt : Icons.videocam),
          color: primary,
          onPressed: () {
            setState(() {
              isPicture = !isPicture;
            });
          },
          tooltip: 'Toggle Picture Video',
        ),
        WidgetUtil.buildCircleButton(
          onPressed:
              cameraController != null && cameraController.value.isInitialized
                  ? _captureMedia
                  : null,
          elevation: 2.0,
          backgroundColor: primary,
          padding: const EdgeInsets.all(15.0),
          child: _getCaptureIcon(),
        ),
        IconButton(
          icon: cameraController != null &&
                  cameraController.value.isRecordingPaused
              ? const Icon(Icons.play_arrow)
              : const Icon(Icons.pause),
          color: primary,
          onPressed: cameraController != null &&
                  cameraController.value.isInitialized &&
                  cameraController.value.isRecordingVideo
              ? (cameraController.value.isRecordingPaused)
                  ? _resumeVideoRecording
                  : _pauseVideoRecording
              : null,
          tooltip: 'Play/Pause',
        ),
        IconButton(
          icon: const Icon(Icons.pause_presentation),
          color:
              cameraController != null && cameraController.value.isPreviewPaused
                  ? Colors.red
                  : primary,
          onPressed: cameraController == null ? null : _togglePreview,
          tooltip: 'Toggle Preview',
        ),
      ],
    );
  }

  Icon _getCaptureIcon() {
    var controller = this.controller;
    if (controller != null && controller.value.isInitialized) {
      if (isPicture) {
        return const Icon(
          Icons.camera,
          size: 48.0,
          color: Colors.white,
        );
      } else {
        if (controller.value.isRecordingVideo) {
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

  Future<void> _toggleCamera() async {
    var cameras = await _fetchCameras();
    if (cameras.isNotEmpty) {
      if (cameraIndex < cameras.length - 1) {
        cameraIndex++;
      } else {
        if (cameraIndex != 0) {
          cameraIndex = 0;
        }
      }
      CameraDescription description = cameras[cameraIndex];
      _createSelectedCamera(description);
    }
  }

  Widget _buildBackButton() {
    var iconButton = IconButton(
      icon: const Icon(Icons.arrow_back, size: 32),
      color: appDataProvider.themeData.colorScheme.primary,
      onPressed: () {
        _back();
      },
    );

    return iconButton;
  }

  /// 镜头切换按钮
  Widget _buildCameraToggleWidget() {
    Widget toggleWidget = FutureBuilder<List<CameraDescription>>(
        future: _fetchCameras(),
        builder: (BuildContext context,
            AsyncSnapshot<List<CameraDescription>> snapshot) {
          if (snapshot.hasData) {
            var cameras = snapshot.data;
            if (cameras != null && cameras.length > 1) {
              var iconButton = IconButton(
                icon: const Icon(Icons.cameraswitch),
                color: appDataProvider.themeData.colorScheme.primary,
                onPressed:
                    controller != null && controller!.value.isRecordingVideo
                        ? null
                        : _toggleCamera,
              );

              return iconButton;
            }
          }
          return Container();
        });

    return toggleWidget;
  }

  void _showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
    ));
  }

  ///对焦和曝光手势的处理
  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final CameraController cameraController = controller!;

    final Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  _disposeController() async {
    final CameraController? oldController = controller;
    if (oldController != null) {
      // `controller` needs to be set to null before getting disposed,
      // to avoid a race condition when we use the controller that is being
      // disposed. This happens when camera permission dialog shows up,
      // which triggers `didChangeAppLifecycleState`, which disposes and
      // re-creates the controller.
      controller = null;
      await oldController.dispose();
    }
  }

  /// 摄像头选择和初始化，先关掉原先的摄像头，初始化新的摄像头
  Future<void> _createSelectedCamera(
      CameraDescription cameraDescription) async {
    await _disposeController();

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        _showInSnackBar(
            'Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
      await Future.wait(<Future<Object?>>[
        // The exposure mode is currently not supported on the web.
        ...!kIsWeb
            ? <Future<Object?>>[
                cameraController.getMinExposureOffset().then(
                    (double value) => _minAvailableExposureOffset = value),
                cameraController
                    .getMaxExposureOffset()
                    .then((double value) => _maxAvailableExposureOffset = value)
              ]
            : <Future<Object?>>[],
        cameraController
            .getMaxZoomLevel()
            .then((double value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((double value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          _showInSnackBar('You have denied camera access.');
          break;
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          _showInSnackBar('Please go to Settings app to enable camera access.');
          break;
        case 'CameraAccessRestricted':
          // iOS only
          _showInSnackBar('Camera access is restricted.');
          break;
        case 'AudioAccessDenied':
          _showInSnackBar('You have denied audio access.');
          break;
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          _showInSnackBar('Please go to Settings app to enable audio access.');
          break;
        case 'AudioAccessRestricted':
          // iOS only
          _showInSnackBar('Audio access is restricted.');
          break;
        default:
          _showCameraException(e);
          break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _toggleFlashMode() {
    if (platformParams.desktop) {
      return;
    }
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
      _exposureModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void _toggleExposureMode() {
    if (platformParams.desktop) {
      return;
    }
    if (_exposureModeControlRowAnimationController.value == 1) {
      _exposureModeControlRowAnimationController.reverse();
    } else {
      _exposureModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void _toggleFocusMode() {
    if (platformParams.desktop) {
      return;
    }
    if (_focusModeControlRowAnimationController.value == 1) {
      _focusModeControlRowAnimationController.reverse();
    } else {
      _focusModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _exposureModeControlRowAnimationController.reverse();
    }
  }

  void _toggleAudioMode() {
    enableAudio = !enableAudio;
    if (controller != null) {
      _createSelectedCamera(controller!.description);
    }
  }

  Future<void> _toggleCaptureOrientationLock() async {
    if (platformParams.desktop) {
      return;
    }
    try {
      if (controller != null) {
        final CameraController cameraController = controller!;
        if (cameraController.value.isCaptureOrientationLocked) {
          await cameraController.unlockCaptureOrientation();
          _showInSnackBar('Capture orientation unlocked');
        } else {
          await cameraController.lockCaptureOrientation();
          _showInSnackBar(
              'Capture orientation locked to ${cameraController.value.lockedCaptureOrientation.toString().split('.').last}');
        }
      }
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  Future<void> _togglePreview() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      _showInSnackBar('Error: select a camera first.');
      return;
    }

    if (cameraController.value.isPreviewPaused) {
      await cameraController.resumePreview();
    } else {
      await cameraController.pausePreview();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      _showInSnackBar('Error: select a camera first.');
      return;
    }

    if (cameraController.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return;
    }

    try {
      await cameraController.startVideoRecording();
      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      return;
    }
  }

  Future<XFile?> _stopVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return null;
    }

    try {
      XFile file = await cameraController.stopVideoRecording();
      if (mounted) {
        setState(() {});
      }
      _showInSnackBar('Video recorded to ${file.path}');
      mediaFile = file;
      _startVideoPlayer();
      if (widget.onFile != null) {
        widget.onFile!(file);
      }

      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  Future<void> _pauseVideoRecording() async {
    if (platformParams.desktop) {
      return;
    }
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return;
    }

    try {
      await cameraController.pauseVideoRecording();
      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _resumeVideoRecording() async {
    if (platformParams.desktop) {
      return;
    }
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return;
    }

    try {
      await cameraController.resumeVideoRecording();
      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _setFlashMode(FlashMode mode) async {
    if (platformParams.desktop) {
      return;
    }
    if (controller == null) {
      return;
    }

    try {
      await controller!.setFlashMode(mode);
      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _setExposureMode(ExposureMode mode) async {
    if (platformParams.desktop) {
      return;
    }
    if (controller == null) {
      return;
    }

    try {
      await controller!.setExposureMode(mode);
      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _setExposureOffset(double offset) async {
    if (platformParams.desktop) {
      return;
    }
    if (controller == null) {
      return;
    }

    setState(() {
      _currentExposureOffset = offset;
    });
    try {
      offset = await controller!.setExposureOffset(offset);
      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _setFocusMode(FocusMode mode) async {
    if (platformParams.desktop) {
      return;
    }
    if (controller == null) {
      return;
    }

    try {
      await controller!.setFocusMode(mode);
      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _startVideoPlayer() async {
    if (platformParams.desktop) {
      return;
    }
    if (mediaFile == null) {
      return;
    }

    final VideoPlayerController vController = kIsWeb
        ? VideoPlayerController.network(mediaFile!.path)
        : VideoPlayerController.file(File(mediaFile!.path));

    videoPlayerListener = () {
      if (videoController != null && videoController!.value.size != null) {
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
        mediaFile = null;
        videoController = vController;
      });
    }
    await vController.play();
  }

  /// 拍照或者开始录像
  Future<void> _captureMedia() async {
    var controller = this.controller;

    if (controller != null && controller.value.isInitialized) {
      if (isPicture) {
        _takePicture();
      } else {
        if (controller.value.isRecordingVideo) {
          _stopVideoRecording();
        } else {
          _startVideoRecording();
        }
      }
    }
  }

  /// 拍照
  Future<XFile?> _takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      _showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final XFile file = await cameraController.takePicture();
      if (mounted) {
        setState(() {
          mediaFile = file;
          videoController?.dispose();
          videoController = null;
        });
        _showInSnackBar('Picture saved to ${file.path}');
      }
      if (widget.onFile != null) {
        widget.onFile!(file);
      }
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  _back() {
    Navigator.pop(context, mediaFile);
  }

  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    _showInSnackBar('Error: ${e.code}\n${e.description}');
  }

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
        _buildPreviewData(),
        _buildCameraController(context),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    _exposureModeControlRowAnimationController.dispose();
    _disposeController();
    super.dispose();
  }
}
