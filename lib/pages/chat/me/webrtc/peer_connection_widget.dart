import 'dart:core';

import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// 连接建立示例
class PeerConnectionWidget extends StatefulWidget with TileDataMixin {
  final String? peerId;
  final String? clientId;
  final Conference? conference;

  PeerConnectionWidget({Key? key, this.conference, this.peerId, this.clientId})
      : super(key: key);

  @override
  State createState() => _PeerConnectionWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'peer_connection';

  @override
  IconData get iconData => Icons.screen_rotation;

  @override
  String get title => 'PeerConnection';
}

class _PeerConnectionWidgetState extends State<PeerConnectionWidget> {
  //本地媒体流
  MediaStream? _localStream;

  //远端媒体流
  MediaStream? _remoteStream;

  //本地连接
  BasePeerConnection? _localConnection;

  //远端连接
  BasePeerConnection? _remoteConnection;

  //本地视频渲染对象
  final _localRenderer = RTCVideoRenderer();

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
  final Map<String, dynamic> sdpConstraints = {
    "mandatory": {
      //是否接收语音数据
      "OfferToReceiveAudio": true,
      //是否接收视频数据
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };

  //PeerConnection约束
  final Map<String, dynamic> pcConstraints = {
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

  //远端Ice连接状态
  _onRemoteIceConnectionState(RTCIceConnectionState state) {
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
  _onLocalCandidate(RTCIceCandidate candidate) {
    logger.i('LocalCandidate: ${candidate.candidate!}');
    //将本地Candidate添加至远端连接
    _remoteConnection!.addIceCandidate([candidate]);
  }

  //远端Candidate数据回调
  _onRemoteCandidate(RTCIceCandidate candidate) {
    logger.i('RemoteCandidate: ${candidate.candidate!}');
    //将远端Candidate添加至本地连接
    _localConnection!.addIceCandidate([candidate]);
  }

  _open() async {
    //如果本地与远端连接创建则返回
    if (_localConnection != null || _remoteConnection != null) return;

    try {
      //创建本地连接对象
      _localConnection = BasePeerConnection();
      var extension = SignalExtension('', '',
          name: '', iceServers: configuration['iceServers']!);
      await _localConnection!.init(true, extension);
      //添加本地Candidate事件监听
      _localConnection!.on(WebrtcEventType.iceCandidate, _onLocalCandidate);
      //添加本地Ice连接状态事件监听
      _localConnection!
          .on(WebrtcEventType.iceConnectionState, _onLocalIceConnectionState);

      //创建远端连接对象
      _remoteConnection = BasePeerConnection();
      await _remoteConnection!.init(false, extension);
      //监听获取到远端视频流事件
      _remoteConnection!.on(WebrtcEventType.addTrack, _onRemoteAddStream);
      //添加远端Candidate事件监听
      _remoteConnection!.on(WebrtcEventType.iceCandidate, _onRemoteCandidate);
      //添加远端Ice连接状态事件监听
      _remoteConnection!
          .on(WebrtcEventType.iceConnectionState, _onRemoteIceConnectionState);

      await _negotiate();
    } catch (e) {
      logger.e(e.toString());
    }
    if (!mounted) return;

    //设置为连接状态
    setState(() {
      _isConnected = true;
    });
  }

  _negotiate() async {
    RTCSessionDescription? sdp =
        await _localConnection!.peerConnection!.getLocalDescription();
    if (sdp != null) {
      logger.i("_localConnection getLocalDescription exist");
    }
    //本地连接创建提议Offer
    RTCSessionDescription offer =
        await _localConnection!.peerConnection!.createOffer(sdpConstraints);
    if (sdp != null && sdp.sdp != offer.sdp) {
      logger.i("_localConnection getLocalDescription changed");
    }
    logger.i("offer:${offer.sdp!}");
    //本地连接设置本地sdp信息
    _localConnection!.peerConnection!.setLocalDescription(offer);
    //远端连接设置远端sdp信息
    _remoteConnection!.peerConnection!.setRemoteDescription(offer);

    sdp = await _remoteConnection!.peerConnection!.getLocalDescription();
    if (sdp != null) {
      logger.i("_remoteConnection getLocalDescription exist");
    }
    //远端连接创建应答Answer
    RTCSessionDescription answer =
        await _remoteConnection!.peerConnection!.createAnswer(sdpConstraints);
    if (sdp != null && sdp.sdp != answer.sdp) {
      logger.i("_remoteConnection getLocalDescription changed");
    }
    logger.i("answer:${answer.sdp!}");
    //远端连接设置本地sdp信息
    _remoteConnection!.peerConnection!.setLocalDescription(answer);
    //本地连接设置远端sdp信息
    _localConnection!.peerConnection!.setRemoteDescription(answer);
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
      //关闭远端连接
      await _remoteConnection!.close();
      //将本地连接置为空
      _localConnection = null;
      //将远端连接置为空
      _remoteConnection = null;
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

  _addStream() async {
    //根据媒体约束获取本地媒体流
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    //将本地媒体流与本地视频对象绑定
    _localRenderer.srcObject = _localStream;
    await _localConnection!.peerConnection!.addStream(_localStream!);
    await _negotiate();
    setState(() {});
  }

  Widget _buildIconButton(BuildContext context) {
    List<Widget> buttons = [];
    Widget add = IconButton(
      onPressed: _isConnected ? _close : _open,
      icon: Icon(_isConnected ? Icons.close : Icons.add),
    );
    buttons.add(add);
    Widget addStream = IconButton(
      onPressed: () {
        _addStream();
      },
      icon: const Icon(Icons.add_circle),
    );
    buttons.add(addStream);

    return Row(
      children: buttons,
    );
  }

  //重写 build方法
  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      rightWidgets: [_buildIconButton(context)],
      child: _buildBody(context),
    );
  }
}
