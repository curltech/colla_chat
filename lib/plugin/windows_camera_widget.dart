// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:colla_chat/widgets/common/simple_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget for Camera Windows plugin.
class WindowsCameraWidget extends StatefulWidget {
  const WindowsCameraWidget({Key? key}) : super(key: key);

  @override
  State<WindowsCameraWidget> createState() => _WindowsCameraWidgetState();
}

class _WindowsCameraWidgetState extends State<WindowsCameraWidget> {
  String _cameraInfo = 'Unknown';
  List<CameraDescription> _cameras = <CameraDescription>[];
  int _cameraIndex = 0;
  int _cameraId = -1;
  bool _initialized = false;
  bool _recording = false;
  bool _recordingTimed = false;
  bool _recordAudio = true;
  bool _previewPaused = false;
  Size? _previewSize;
  ResolutionPreset _resolutionPreset = ResolutionPreset.veryHigh;
  StreamSubscription<CameraErrorEvent>? _errorStreamSubscription;
  StreamSubscription<CameraClosingEvent>? _cameraClosingStreamSubscription;

  @override
  void initState() {
    super.initState();
    _fetchCameras();
  }

  @override
  void dispose() {
    _disposeCurrentCamera();
    _errorStreamSubscription?.cancel();
    _errorStreamSubscription = null;
    _cameraClosingStreamSubscription?.cancel();
    _cameraClosingStreamSubscription = null;
    super.dispose();
  }

  /// Fetches list of available cameras from camera_windows plugin.
  Future<void> _fetchCameras() async {
    String cameraInfo;
    List<CameraDescription> cameras = <CameraDescription>[];

    int cameraIndex = 0;
    try {
      cameras = await CameraPlatform.instance.availableCameras();
      if (cameras.isEmpty) {
        cameraInfo = 'No available cameras';
      } else {
        cameraIndex = _cameraIndex % cameras.length;
        cameraInfo = 'Found camera: ${cameras[cameraIndex].name}';
      }
    } on PlatformException catch (e) {
      cameraInfo = 'Failed to get cameras: ${e.code}: ${e.message}';
    }

    if (mounted) {
      setState(() {
        _cameraIndex = cameraIndex;
        _cameras = cameras;
        _cameraInfo = cameraInfo;
      });
    }
  }

  /// Initializes the camera on the device.
  Future<void> _initializeCamera() async {
    assert(!_initialized);

    if (_cameras.isEmpty) {
      return;
    }

    int cameraId = -1;
    try {
      final int cameraIndex = _cameraIndex % _cameras.length;
      final CameraDescription camera = _cameras[cameraIndex];

      cameraId = await CameraPlatform.instance.createCamera(
        camera,
        _resolutionPreset,
        enableAudio: _recordAudio,
      );

      _errorStreamSubscription?.cancel();
      _errorStreamSubscription = CameraPlatform.instance
          .onCameraError(cameraId)
          .listen(_onCameraError);

      _cameraClosingStreamSubscription?.cancel();
      _cameraClosingStreamSubscription = CameraPlatform.instance
          .onCameraClosing(cameraId)
          .listen(_onCameraClosing);

      final Future<CameraInitializedEvent> initialized =
          CameraPlatform.instance.onCameraInitialized(cameraId).first;

      await CameraPlatform.instance.initializeCamera(
        cameraId,
      );

      final CameraInitializedEvent event = await initialized;
      _previewSize = Size(
        event.previewWidth,
        event.previewHeight,
      );

      if (mounted) {
        setState(() {
          _initialized = true;
          _cameraId = cameraId;
          _cameraIndex = cameraIndex;
          _cameraInfo = 'Capturing camera: ${camera.name}';
        });
      }
    } on CameraException catch (e) {
      try {
        if (cameraId >= 0) {
          await CameraPlatform.instance.dispose(cameraId);
        }
      } on CameraException catch (e) {
        debugPrint('Failed to dispose camera: ${e.code}: ${e.description}');
      }

      // Reset state.
      if (mounted) {
        setState(() {
          _initialized = false;
          _cameraId = -1;
          _cameraIndex = 0;
          _previewSize = null;
          _recording = false;
          _recordingTimed = false;
          _cameraInfo =
              'Failed to initialize camera: ${e.code}: ${e.description}';
        });
      }
    }
  }

  Future<void> _disposeCurrentCamera() async {
    if (_cameraId >= 0 && _initialized) {
      try {
        await CameraPlatform.instance.dispose(_cameraId);

        if (mounted) {
          setState(() {
            _initialized = false;
            _cameraId = -1;
            _previewSize = null;
            _recording = false;
            _recordingTimed = false;
            _previewPaused = false;
            _cameraInfo = 'Camera disposed';
          });
        }
      } on CameraException catch (e) {
        if (mounted) {
          setState(() {
            _cameraInfo =
                'Failed to dispose camera: ${e.code}: ${e.description}';
          });
        }
      }
    }
  }

  ///预览窗口
  Widget _buildPreview() {
    Widget preview = Container();
    if (_initialized && _cameraId > 0 && _previewSize != null) {
      preview = Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        child: Align(
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 500,
            ),
            child: AspectRatio(
              aspectRatio: _previewSize!.width / _previewSize!.height,
              child: CameraPlatform.instance.buildPreview(_cameraId),
            ),
          ),
        ),
      );
    }
    return preview;
  }

  _buildPreviewText() {
    Widget previewText = Container();
    if (_previewSize != null) {
      previewText = Center(
        child: Text(
          'Size: ${_previewSize!.width.toStringAsFixed(0)}x${_previewSize!.height.toStringAsFixed(0)}',
        ),
      );
    }
    return previewText;
  }

  Future<void> _takePicture() async {
    final XFile file = await CameraPlatform.instance.takePicture(_cameraId);
    _showInSnackBar('Picture captured to: ${file.path}');
  }

  Future<void> _recordTimed(int seconds) async {
    if (_initialized && _cameraId > 0 && !_recordingTimed) {
      CameraPlatform.instance
          .onVideoRecordedEvent(_cameraId)
          .first
          .then((VideoRecordedEvent event) async {
        if (mounted) {
          setState(() {
            _recordingTimed = false;
          });

          _showInSnackBar('Video captured to: ${event.file.path}');
        }
      });

      await CameraPlatform.instance.startVideoRecording(
        _cameraId,
        maxVideoDuration: Duration(seconds: seconds),
      );

      if (mounted) {
        setState(() {
          _recordingTimed = true;
        });
      }
    }
  }

  Future<void> _toggleRecord() async {
    if (_initialized && _cameraId > 0) {
      if (_recordingTimed) {
        /// Request to stop timed recording short.
        await CameraPlatform.instance.stopVideoRecording(_cameraId);
      } else {
        if (!_recording) {
          await CameraPlatform.instance.startVideoRecording(_cameraId);
        } else {
          final XFile file =
              await CameraPlatform.instance.stopVideoRecording(_cameraId);

          _showInSnackBar('Video captured to: ${file.path}');
        }

        if (mounted) {
          setState(() {
            _recording = !_recording;
          });
        }
      }
    }
  }

  Future<void> _togglePreview() async {
    if (_initialized && _cameraId >= 0) {
      if (!_previewPaused) {
        await CameraPlatform.instance.pausePreview(_cameraId);
      } else {
        await CameraPlatform.instance.resumePreview(_cameraId);
      }
      if (mounted) {
        setState(() {
          _previewPaused = !_previewPaused;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.isNotEmpty) {
      // select next index;
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
      if (_initialized && _cameraId >= 0) {
        await _disposeCurrentCamera();
        await _fetchCameras();
        if (_cameras.isNotEmpty) {
          await _initializeCamera();
        }
      } else {
        await _fetchCameras();
      }
    }
  }

  Future<void> _onResolutionChange(ResolutionPreset newValue) async {
    setState(() {
      _resolutionPreset = newValue;
    });
    if (_initialized && _cameraId >= 0) {
      // Re-inits camera with new resolution preset.
      await _disposeCurrentCamera();
      await _initializeCamera();
    }
  }

  Future<void> _onAudioChange(bool recordAudio) async {
    setState(() {
      _recordAudio = recordAudio;
    });
    if (_initialized && _cameraId >= 0) {
      // Re-inits camera with new record audio setting.
      await _disposeCurrentCamera();
      await _initializeCamera();
    }
  }

  void _onCameraError(CameraErrorEvent event) {
    if (mounted) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error: ${event.description}')));

      // Dispose camera on camera error as it can not be used anymore.
      _disposeCurrentCamera();
      _fetchCameras();
    }
  }

  void _onCameraClosing(CameraClosingEvent event) {
    if (mounted) {
      _showInSnackBar('Camera is closing');
    }
  }

  void _showInSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ));
  }

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  _buildPreviewButton() {
    Widget previewButton = Row(children: [
      ///打开关闭摄像头按钮
      ElevatedButton(
        onPressed: _initialized ? _disposeCurrentCamera : _initializeCamera,
        child: Text(_initialized ? 'Dispose camera' : 'Create camera'),
      ),

      ///拍照和摄像按钮
      Center(
          child: Container(
        padding: const EdgeInsets.all(15.0),
        child: WidgetUtil.buildCircleButton(
          onPressed: () {
            if (_initialized) {
              _takePicture();
            }
          },
          elevation: 2.0,
          backgroundColor: Colors.red,
          padding: const EdgeInsets.all(15.0),
          child: const Icon(
            Icons.call_end,
            size: 48.0,
            color: Colors.white,
          ),
        ),
      )),

      ///声音开关
      Switch(
          value: _recordAudio,
          onChanged: (bool state) => _onAudioChange(state)),

      ///预览开关
      ElevatedButton(
        onPressed: _initialized ? _togglePreview : null,
        child: Text(
          _previewPaused ? 'Resume preview' : 'Pause preview',
        ),
      ),

      ///摄像开关
      ElevatedButton(
        onPressed: _initialized ? _toggleRecord : null,
        child: Text(
          (_recording || _recordingTimed) ? 'Stop recording' : 'Record Video',
        ),
      ),

      ///5秒摄像按钮，快捷
      ElevatedButton(
        onPressed: (_initialized && !_recording && !_recordingTimed)
            ? () => _recordTimed(5)
            : null,
        child: const Text(
          'Record 5 seconds',
        ),
      ),

      ///镜头切换按钮
      if (_cameras.length > 1) ...<Widget>[
        const SizedBox(width: 5),
        ElevatedButton(
          onPressed: _switchCamera,
          child: const Text(
            'Switch camera',
          ),
        ),
      ],

      ///返回按钮
    ]);

    return previewButton;
  }

  _buildResolutionPreset() {
    final List<DropdownMenuItem<ResolutionPreset>> resolutionItems =
        ResolutionPreset.values
            .map<DropdownMenuItem<ResolutionPreset>>((ResolutionPreset value) {
      return DropdownMenuItem<ResolutionPreset>(
        value: value,
        child: Text(value.toString()),
      );
    }).toList();
    Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
        horizontal: 10,
      ),
      child: Text(_cameraInfo),
    );
    if (_cameras.isNotEmpty) {
      DropdownButton<ResolutionPreset>(
        value: _resolutionPreset,
        onChanged: (ResolutionPreset? value) {
          if (value != null) {
            _onResolutionChange(value);
          }
        },
        items: resolutionItems,
      );
    } else {
      ElevatedButton(
        onPressed: _fetchCameras,
        child: const Text('Re-check available cameras'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildPreview(),
        _buildPreviewText(),
        _buildPreviewButton(),
      ],
    );
  }
}
