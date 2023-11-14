import 'dart:core';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/media_stream_util.dart';
import 'package:colla_chat/transport/webrtc/p2p/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/p2p/p2p_media_render_view.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class GetUserMediaWidget extends StatefulWidget with TileDataMixin {
  const GetUserMediaWidget({Key? key}) : super(key: key);

  @override
  State createState() => _GetUserMediaWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'get_user_media';

  @override
  IconData get iconData => Icons.videocam;

  @override
  String get title => 'GetUserMedia';
}

class _GetUserMediaWidgetState extends State<GetUserMediaWidget> {
  bool _inCalling = false;
  bool _isTorchOn = false;
  PeerMediaStream? peerMediaStream;
  List<MediaDeviceInfo>? mediaDevicesList;
  MediaRecorder? mediaRecorder;

  bool get _isRec {
    if (peerMediaStream != null) {
      return mediaRecorder != null;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    if (peerMediaStream != null) {
      MediaStreamUtil.enumerateDevices().then((value) {
        mediaDevicesList = value;
      });
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void _makeCall() async {
    try {
      await localPeerMediaStreamController.createMainPeerMediaStream();
      List<PeerMediaStream> renders =
          localPeerMediaStreamController.peerMediaStreams;
      if (renders.isNotEmpty) {
        peerMediaStream = renders[0];
        await MediaStreamUtil.enumerateDevices();
      }
    } catch (e) {
      logger.e('$e');
    }
    if (!mounted) return;

    setState(() {
      _inCalling = true;
    });
  }

  void _hangUp() async {
    try {
      localPeerMediaStreamController.closeAll();
      setState(() {
        _inCalling = false;
      });
    } catch (e) {
      logger.e('$e');
    }
  }

  void _startRecording() async {
    if (peerMediaStream != null) {
      mediaRecorder =
          await MediaStreamUtil.startRecording(peerMediaStream!.mediaStream!);
      setState(() {});
    }
  }

  void _stopRecording() async {
    if (peerMediaStream != null) {
      await MediaStreamUtil.stopRecording(mediaRecorder!);
      setState(() {});
    }
  }

  void _toggleTorch() async {
    if (peerMediaStream != null) {
      return;
    }

    if (peerMediaStream!.mediaStream == null) {
      logger.e('Stream is not initialized');
      return;
    }

    final videoTrack = peerMediaStream!.mediaStream!
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
    if (peerMediaStream != null) {
      return;
    }
    if (peerMediaStream!.mediaStream == null) {
      throw 'Stream is not initialized';
    }
    MediaStreamUtil.switchCamera(peerMediaStream!.mediaStream!);
  }

  void _captureFrame() async {
    if (peerMediaStream != null) {
      return;
    }
    if (peerMediaStream!.mediaStream == null) {
      throw 'Stream is not initialized';
    }
    final frame =
        await MediaStreamUtil.captureFrame(peerMediaStream!.mediaStream!);
    if (mounted && frame != null) {
      await showDialog(
          context: context,
          builder: (context) => AlertDialog(
                content:
                    Image.memory(frame.asUint8List(), height: 720, width: 1280),
                actions: <Widget>[
                  TextButton(
                    onPressed: Navigator.of(context, rootNavigator: true).pop,
                    child: const CommonAutoSizeText('Ok'),
                  )
                ],
              ));
    }
  }

  Widget _buildVideoView(BuildContext context) {
    if (peerMediaStream == null) {
      return Container();
    }
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return P2pMediaRenderView(
      peerMediaStream: peerMediaStream!,
      width: width,
      height: height,
    );
  }

  List<Widget>? _buildActions(BuildContext context) {
    return _inCalling
        ? <Widget>[
            IconButton(
              icon: Icon(_isTorchOn ? Icons.flash_off : Icons.flash_on),
              tooltip: 'toggleTorch',
              onPressed: _toggleTorch,
            ),
            IconButton(
              icon: const Icon(Icons.switch_video),
              tooltip: 'toggleCamera',
              onPressed: _toggleCamera,
            ),
            IconButton(
              icon: const Icon(Icons.camera),
              tooltip: 'captureFrame',
              onPressed: _captureFrame,
            ),
            IconButton(
              icon: Icon(_isRec ? Icons.stop : Icons.fiber_manual_record),
              tooltip: 'Recording',
              onPressed: _isRec ? _stopRecording : _startRecording,
            ),
            PopupMenuButton<String>(
              onSelected: null,
              itemBuilder: (BuildContext context) {
                if (mediaDevicesList != null) {
                  return mediaDevicesList!
                      .where((device) => device.kind == 'audiooutput')
                      .map((device) {
                    return PopupMenuItem<String>(
                      value: device.deviceId,
                      child: CommonAutoSizeText(device.label),
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
      title: widget.title,
      withLeading: widget.withLeading,
      rightWidgets: _buildAppBarButton(),
      child: _buildVideoView(context),
    );
    return appBarView;
  }

  List<Widget> _buildAppBarButton() {
    return [
      IconButton(
        onPressed: _inCalling ? _hangUp : _makeCall,
        tooltip: _inCalling ? 'Hangup' : 'Call',
        icon: Icon(_inCalling ? Icons.call_end : Icons.phone),
      )
    ];
  }

  @override
  void dispose() {
    if (_inCalling) {
      _hangUp();
    }
    super.dispose();
  }
}
