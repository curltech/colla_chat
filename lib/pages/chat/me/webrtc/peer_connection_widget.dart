import 'dart:core';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/webrtc/peer_connection_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../entity/dht/peersignal.dart';
import '../../../../plugin/logger.dart';
import '../../../../service/dht/peersignal.dart';
import '../../../../tool/util.dart';
import '../../../../transport/webrtc/advanced_peer_connection.dart';
import '../../../../transport/webrtc/base_peer_connection.dart';
import '../../../../widgets/common/widget_mixin.dart';

/// 连接建立示例
class PeerConnectionWidget extends StatefulWidget with TileDataMixin {
  final String? peerId;
  final String? clientId;
  final Room? room;
  final PeerConnectionPoolController controller = peerConnectionPoolController;

  PeerConnectionWidget({Key? key, this.room, this.peerId, this.clientId})
      : super(key: key);

  @override
  State createState() => _PeerConnectionWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'peer_connection';

  @override
  Icon get icon => const Icon(Icons.screen_rotation);

  @override
  String get title => 'PeerConnection';
}

class _PeerConnectionWidgetState extends State<PeerConnectionWidget> {
  bool initiator = true;

  //本地媒体流
  MediaStream? _localStream;

  //本地连接
  BasePeerConnection? _localConnection;

  //本地视频渲染对象
  final _localRenderer = RTCVideoRenderer();

  //本地candidate signal json
  String? _localCandidateSignal;

  //远程candidate signal json
  String? _remoteCandidateSignal;

  //本地sdp signal json
  String? _localSdpSignal;

  //远端sdp signal json
  String? _remoteSdpSignal;

  //远端媒体流
  MediaStream? _remoteStream;

  //远端视频渲染对象
  final _remoteRenderer = RTCVideoRenderer();

  //是否连接
  bool _isConnected = false;

  //媒体约束
  final Map<String, dynamic> mediaConstraints = {
    //开启音频
    "audio": true,
    "video": {
      "mandatory": {
        //宽度
        "minWidth": '640',
        //高度
        "minHeight": '480',
        //帧率
        "minFrameRate": '30',
      },
      "facingMode": "user",
      "optional": [],
    }
  };

  Map<String, dynamic> configuration = {
    //使用google的服务器
    "iceServers": [
      {"url": "stun:stun.l.google.com:19302"},
    ]
  };

  //sdp约束
  final Map<String, dynamic> sdp_constraints = {
    "mandatory": {
      //是否接收语音数据
      "OfferToReceiveAudio": true,
      //是否接收视频数据
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };

  //PeerConnection约束
  final Map<String, dynamic> pc_constraints = {
    "mandatory": {},
    "optional": [
      //如果要与浏览器互通开启DtlsSrtpKeyAgreement,此处不开启
      {"DtlsSrtpKeyAgreement": false},
    ],
  };

  @override
  initState() {
    super.initState();
    //初始化视频渲染对象
    initRenderers();
  }

  @override
  deactivate() {
    super.deactivate();
    //挂断
    if (_isConnected) {
      _close();
    }
    //销毁本地视频渲染对象
    _localRenderer.dispose();
    //销毁远端视频渲染对象
    _remoteRenderer.dispose();
  }

  //初始化视频渲染对象
  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  //本地Ice连接状态
  _onLocalIceConnectionState(RTCIceConnectionState state) {
    logger.i(state);
  }

  //远端流添加成功回调
  _onRemoteAddStream(MediaStream stream) {
    logger.i('Remote addStream: ${stream.id}');
    //得到远端媒体流
    _remoteStream = stream;
    //将远端视频渲染对象与媒体流绑定
    _remoteRenderer.srcObject = stream;
  }

  //本地Candidate数据回调
  _onLocalCandidate(RTCIceCandidate candidate) async {
    var signal =
        WebrtcSignal(SignalType.candidate.name, candidates: [candidate]);
    _localCandidateSignal = JsonUtil.toJsonString(signal);
    logger.w('_localCandidateSignal: $_localCandidateSignal');
    //本地连接设置远端sdp信息
    String peerId = 'Gi46PD7Gfc43HvNPX3xszbtJsXriC4Ct3qk4CkKzvkMi';
    //String peerId='9AeL4FqoUf7zWpyo4PAczuE6jbsP4sPEac1evxRAbk75';
    PeerSignal? peerSignal = await peerSignalService.findOneByPeerId(peerId,
        signalType: SignalType.sdp.name);
    if (peerSignal != null) {
      var map = JsonUtil.toJson(peerSignal.content);
      WebrtcSignal signal = WebrtcSignal.fromJson(map);
      for (var candidate in signal.candidates!) {
        await _localConnection!.peerConnection!.addCandidate(candidate);
      }
    } else {
      logger.e('peerSignal is null');
    }
  }

  _open() async {
    //如果本地与远端连接创建则返回
    if (_localConnection != null) return;

    try {
      //根据媒体约束获取本地媒体流
      _localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      //将本地媒体流与本地视频对象绑定
      _localRenderer.srcObject = _localStream;

      //创建本地连接对象
      _localConnection = BasePeerConnection(initiator: initiator);
      var extension =
          SignalExtension('', '', iceServers: configuration['iceServers']!);
      await _localConnection!
          .init(extension: extension, localStreams: [_localStream!]);
      //监听获取到远端视频流事件
      _localConnection!.on(WebrtcEventType.stream, _onRemoteAddStream);
      //添加本地Candidate事件监听
      _localConnection!.on(WebrtcEventType.iceCandidate, _onLocalCandidate);
      //添加本地Ice连接状态事件监听
      _localConnection!
          .on(WebrtcEventType.iceConnectionState, _onLocalIceConnectionState);

      //本地连接创建提议Offer
      RTCSessionDescription sdp;
      if (initiator) {
        sdp = await _localConnection!.peerConnection!
            .createOffer(sdp_constraints);
      } else {
        sdp = await _localConnection!.peerConnection!
            .createAnswer(sdp_constraints);
      }
      var signal = WebrtcSignal(SignalType.sdp.name, sdp: sdp);
      _localSdpSignal = JsonUtil.toJsonString(signal);
      logger.w('_localSdpSignal: $_localSdpSignal');
      //本地连接设置本地sdp信息
      _localConnection!.peerConnection!.setLocalDescription(sdp);
      //本地连接设置远端sdp信息
      String peerId = 'Gi46PD7Gfc43HvNPX3xszbtJsXriC4Ct3qk4CkKzvkMi';
      //String peerId='9AeL4FqoUf7zWpyo4PAczuE6jbsP4sPEac1evxRAbk75';
      PeerSignal? peerSignal = await peerSignalService.findOneByPeerId(peerId,
          signalType: SignalType.sdp.name);
      if (peerSignal != null) {
        var map = JsonUtil.toJson(peerSignal.content);
        WebrtcSignal signal = WebrtcSignal.fromJson(map);
        _localConnection!.peerConnection!.setRemoteDescription(signal.sdp!);
      } else {
        logger.e('peerSignal is null');
      }
    } catch (e) {
      logger.e(e.toString());
    }
    if (!mounted) return;

    //设置为连接状态
    setState(() {
      _isConnected = true;
    });
  }

  //关闭处理
  _close() async {
    try {
      //销毁本地流
      await _localStream!.dispose();
      //销毁远端流
      await _remoteStream!.dispose();
      //关闭本地连接
      await _localConnection!.close();
      //将本地连接置为空
      _localConnection = null;
      //将本地视频源置为空
      _localRenderer.srcObject = null;
      //将远端视频源置为空
      _remoteRenderer.srcObject = null;
    } catch (e) {
      logger.e(e.toString());
    }
    //设置连接状态为false
    setState(() {
      _isConnected = false;
    });
  }

  Widget _buildBody(BuildContext context) {
    return OrientationBuilder(
      //orientation为旋转方向
      builder: (context, orientation) {
        //居中
        return Center(
          //容器
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Stack(
              children: <Widget>[
                Align(
                  //判断是否为垂直方向
                  alignment: orientation == Orientation.portrait
                      ? const FractionalOffset(0.5, 0.1)
                      : const FractionalOffset(0.0, 0.5),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                    width: 320.0,
                    height: 240.0,
                    decoration: const BoxDecoration(color: Colors.black),
                    //本地视频渲染
                    child: RTCVideoView(_localRenderer),
                  ),
                ),
                Align(
                  //判断是否为垂直方向
                  alignment: orientation == Orientation.portrait
                      ? const FractionalOffset(0.5, 0.9)
                      : const FractionalOffset(1.0, 0.5),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                    width: 320.0,
                    height: 240.0,
                    decoration: const BoxDecoration(color: Colors.black),
                    //远端视频渲染
                    child: RTCVideoView(_remoteRenderer),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton(BuildContext context) {
    return IconButton(
      onPressed: _isConnected ? _close : _open,
      icon: Icon(_isConnected ? Icons.close : Icons.add),
    );
  }

  //重写 build方法
  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: Text(AppLocalizations.t('video call')),
      withLeading: widget.withLeading,
      rightWidgets: [_buildIconButton(context)],
      child: _buildBody(context),
    );
  }
}
