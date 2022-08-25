import 'dart:core';

import 'package:colla_chat/pages/chat/chat/controller/local_media_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/localization.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';

class GetUserMediaWidget extends StatefulWidget with TileDataMixin {
  const GetUserMediaWidget({Key? key}) : super(key: key);

  @override
  State createState() => _GetUserMediaWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'get_user_media';

  @override
  Icon get icon => const Icon(Icons.videocam);

  @override
  String get title => 'GetUserMedia';
}

class _GetUserMediaWidgetState extends State<GetUserMediaWidget> {
  bool _inCalling = false;
  bool _isTorchOn = false;

  bool get _isRec => localMediaController.userRender.mediaRecorder != null;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void _makeCall() async {
    try {
      await localMediaController.userRender.createUserMedia();
      await localMediaController.userRender.enumerateDevices();
      await localMediaController.userRender.bindRTCVideoRender();
    } catch (e) {
      logger.e(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _inCalling = true;
    });
  }

  void _hangUp() async {
    try {
      localMediaController.userRender.dispose();
      setState(() {
        _inCalling = false;
      });
    } catch (e) {
      logger.e(e.toString());
    }
  }

  void _startRecording() async {
    localMediaController.userRender.startRecording();
    setState(() {});
  }

  void _stopRecording() async {
    localMediaController.userRender.stopRecording();
    setState(() {});
  }

  void _toggleTorch() async {
    if (localMediaController.userRender.mediaStream == null) {
      throw 'Stream is not initialized';
    }

    final videoTrack = localMediaController.userRender.mediaStream!
        .getVideoTracks()
        .firstWhere((track) => track.kind == 'video');
    final has = await videoTrack.hasTorch();
    if (has) {
      logger.i('[TORCH] Current camera supports torch mode');
      setState(() => _isTorchOn = !_isTorchOn);
      await videoTrack.setTorch(_isTorchOn);
      logger.i('[TORCH] Torch state is now ${_isTorchOn ? 'on' : 'off'}');
    } else {
      logger.e('[TORCH] Current camera does not support torch mode');
    }
  }

  void _toggleCamera() async {
    if (localMediaController.userRender.mediaStream == null) {
      throw 'Stream is not initialized';
    }
    localMediaController.userRender.switchCamera();
  }

  void _captureFrame() async {
    if (localMediaController.userRender.mediaStream == null) {
      throw 'Stream is not initialized';
    }
    final frame = await localMediaController.userRender.captureFrame();
    if (frame != null) {
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                content: Image.memory(frame!.asUint8List(),
                    height: 720, width: 1280),
                actions: <Widget>[
                  TextButton(
                    onPressed: Navigator.of(context, rootNavigator: true).pop,
                    child: Text('OK'),
                  )
                ],
              ));
    }
  }

  Widget _buildVideoView(BuildContext context) {
    return localMediaController.userRender.createVideoView(mirror: true);
  }

  List<Widget>? _buildActions(BuildContext context) {
    var mediaDevicesList = localMediaController.userRender.mediaDevicesList;
    return _inCalling
        ? <Widget>[
            IconButton(
              icon: Icon(_isTorchOn ? Icons.flash_off : Icons.flash_on),
              tooltip: 'toggleTorch',
              onPressed: _toggleTorch,
            ),
            IconButton(
              icon: Icon(Icons.switch_video),
              tooltip: 'toggleCamera',
              onPressed: _toggleCamera,
            ),
            IconButton(
              icon: Icon(Icons.camera),
              tooltip: 'captureFrame',
              onPressed: _captureFrame,
            ),
            IconButton(
              icon: Icon(_isRec ? Icons.stop : Icons.fiber_manual_record),
              tooltip: 'Recording',
              onPressed: _isRec ? _stopRecording : _startRecording,
            ),
            PopupMenuButton<String>(
              onSelected: _selectAudioOutput,
              itemBuilder: (BuildContext context) {
                if (mediaDevicesList != null) {
                  return mediaDevicesList!
                      .where((device) => device.kind == 'audiooutput')
                      .map((device) {
                    return PopupMenuItem<String>(
                      value: device.deviceId,
                      child: Text(device.label),
                    );
                  }).toList();
                }
                return [];
              },
            ),
          ]
        : null;
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
      title: Text(AppLocalizations.t(widget.title)),
      withLeading: widget.withLeading,
      rightWidgets: _buildActions(context),
      rightPopupMenus: [_buildAppBarPopupMenu()],
      child: _buildVideoView(context),
    );
    return appBarView;
  }

  AppBarPopupMenu _buildAppBarPopupMenu() {
    return AppBarPopupMenu(
      onPressed: _inCalling ? _hangUp : _makeCall,
      title: _inCalling ? 'Hangup' : 'Call',
      icon: Icon(_inCalling ? Icons.call_end : Icons.phone,
          color: appDataProvider.themeData!.colorScheme.primary),
    );
  }

  void _selectAudioOutput(String deviceId) {
    localMediaController.userRender.renderer!.audioOutput(deviceId);
  }

  @override
  void dispose() {
    if (_inCalling) {
      _hangUp();
    }
    super.dispose();
  }
}
