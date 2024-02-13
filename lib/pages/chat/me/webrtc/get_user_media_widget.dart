import 'dart:core';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/tool/media_stream_util.dart';
import 'package:colla_chat/transport/webrtc/local_peer_media_stream_controller.dart';
import 'package:colla_chat/transport/webrtc/peer_media_render_view.dart';
import 'package:colla_chat/transport/webrtc/peer_media_stream.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class GetUserMediaWidget extends StatefulWidget with TileDataMixin {
  const GetUserMediaWidget({super.key});

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
  bool _isSpeakerOn = false;
  bool _isMicrophoneOn = false;
  double _volume = 0;
  double _zoomLevel = 0;
  PeerMediaStream? peerMediaStream;
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
  }

  Future<List<TileData>> _buildDeviceTileData() async {
    List<MediaDeviceInfo>? mediaDeviceInfos =
        await MediaStreamUtil.enumerateDevices();
    List<TileData> tiles = [];
    if (mediaDeviceInfos != null) {
      for (var mediaDeviceInfo in mediaDeviceInfos) {
        tiles.add(TileData(
          title: mediaDeviceInfo.label,
          subtitle: mediaDeviceInfo.deviceId,
          titleTail: mediaDeviceInfo.kind,
          onTap: (int index, String title, {String? subtitle}) async {
            if (mediaDeviceInfo.kind == 'audiooutput') {
              await MediaStreamUtil.selectAudioOutput(mediaDeviceInfo.deviceId);
            }
            if (mediaDeviceInfo.kind == 'audioinput') {
              await MediaStreamUtil.selectAudioInput(mediaDeviceInfo.deviceId);
            }
          },
        ));
      }
    }

    return tiles;
  }

  Widget _buildDeviceView(BuildContext context) {
    return FutureBuilder(
        future: _buildDeviceTileData(),
        builder:
            (BuildContext context, AsyncSnapshot<List<TileData>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return DataListView(tileData: snapshot.data!);
            }
          }

          return LoadingUtil.buildLoadingIndicator();
        });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void _makeCall() async {
    try {
      await localPeerMediaStreamController.createMainPeerMediaStream();
      List<PeerMediaStream> renders =
          localPeerMediaStreamController.peerMediaStreams;
      if (renders.isNotEmpty) {
        peerMediaStream = renders[0];
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
    var height = MediaQuery.of(context).size.height * 0.6;
    return PeerMediaRenderView(
      peerMediaStream: peerMediaStream!,
      width: width,
      height: height,
    );
  }

  List<ActionData> _buildVideoActionData() {
    List<ActionData> videoActionData = [];
    videoActionData.add(
      ActionData(label: 'Camera switch', icon: const Icon(Icons.cameraswitch)),
    );
    videoActionData.add(
      ActionData(
          label: 'Torch switch',
          icon: Icon(_isTorchOn ? Icons.flash_off : Icons.flash_on)),
    );
    videoActionData.add(
      ActionData(
          label: 'Speaker switch',
          icon: Icon(
            Icons.speaker_phone,
            color: _isSpeakerOn ? Colors.green : Colors.grey,
          )),
    );
    videoActionData.add(
      ActionData(
          label: 'Microphone mute switch',
          icon: Icon(
            _isMicrophoneOn ? Icons.mic : Icons.mic_off,
          )),
    );
    videoActionData.add(
      ActionData(label: 'Capture frame', icon: const Icon(Icons.camera)),
    );
    videoActionData.add(
      ActionData(
          label: 'Recording',
          icon: Icon(_isRec ? Icons.stop : Icons.fiber_manual_record)),
    );
    if (_volume > 0) {
      videoActionData.add(
        ActionData(label: 'Volume mute', icon: const Icon(Icons.volume_mute)),
      );
    }
    if (_volume > 0) {
      videoActionData.add(
        ActionData(
            label: 'Volume decrease', icon: const Icon(Icons.volume_down)),
      );
    }
    videoActionData.add(
      ActionData(label: 'Volume increase', icon: const Icon(Icons.volume_up)),
    );
    if (platformParams.mobile) {
      videoActionData.add(
        ActionData(label: 'Zoom in', icon: const Icon(Icons.zoom_in_map)),
      );
      videoActionData.add(
        ActionData(label: 'Zoom out', icon: const Icon(Icons.zoom_out_map)),
      );
    }
    videoActionData.add(
      ActionData(
          label: 'Close',
          // actionType: ActionType.inkwell,
          icon: const Icon(Icons.closed_caption_disabled)),
    );

    return videoActionData;
  }

  Future<void> _onAction(BuildContext context, int index, String name,
      {String? value}) async {
    switch (name) {
      case 'Camera switch':
        _toggleCamera();
        break;
      case 'Torch switch':
        _toggleTorch();
        break;
      case 'Capture frame':
        _captureFrame();
        break;
      case 'Recording':
        _isRec ? _stopRecording() : _startRecording();
        break;
      case 'Speaker switch':
        _isSpeakerOn = !_isSpeakerOn;
        await peerMediaStream?.switchSpeaker(_isSpeakerOn);
        break;
      case 'Microphone mute switch':
        _isMicrophoneOn = !_isMicrophoneOn;
        await peerMediaStream?.setMicrophoneMute(_isMicrophoneOn);
        break;
      case 'Volume increase':
        double val = _volume + 0.1;
        val = val > 1 ? 1 : val;
        _volume = val;
        await peerMediaStream?.setVolume(val);
        break;
      case 'Volume decrease':
        double val = _volume - 0.1;
        val = val < 0 ? 0 : val;
        _volume = val;
        await peerMediaStream?.setVolume(val);
        break;
      case 'Volume mute':
        double val = _volume;
        if (val == 0) {
          _volume = 1;
        } else {
          _volume = 0;
        }
        peerMediaStream?.setVolume(_volume);
        break;
      case 'Zoom out':
        double val = _zoomLevel + 0.1;
        //val = val > 1 ? 1 : val;
        _zoomLevel = val;
        await peerMediaStream?.setZoom(val);
        break;
      case 'Zoom in':
        double val = _zoomLevel - 0.1;
        //val = val < 0 ? 0 : val;
        _zoomLevel = val;
        await peerMediaStream?.setZoom(val);
        break;
      case 'Close':
        _hangUp();
        break;
      default:
        break;
    }
  }

  Future<dynamic> _showActionCard(BuildContext context) {
    return DialogUtil.popModalBottomSheet(context, builder: (context) {
      List<ActionData> actions = _buildVideoActionData();
      int level = (actions.length / 4).ceil();
      double height = 100.0 * level;
      return Card(
          child: DataActionCard(
              onPressed: (int index, String label, {String? value}) {
                _onAction(context, index, label, value: value);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              showLabel: true,
              showTooltip: true,
              crossAxisCount: 3,
              actions: actions,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              height: height,
              width: 350,
              iconSize: 30));
    });
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      rightWidgets: _buildAppBarButton(),
      child: Column(
        children: [
          _buildVideoView(context),
          Expanded(child: _buildDeviceView(context)),
        ],
      ),
    );
    return appBarView;
  }

  List<Widget> _buildAppBarButton() {
    return [
      IconButton(
        onPressed: () async {
          await _showActionCard(context);
        },
        tooltip: 'Action',
        icon: const Icon(Icons.menu),
      ),
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
