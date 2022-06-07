import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../crypto/cryptography.dart';
import '../../provider/app_data.dart';
import '../../tool/util.dart';

//sdp约束
final Map<String, dynamic> sdpConstraints = {
  "mandatory": {
    //不接收语音数据
    "OfferToReceiveAudio": true,
    //不接收视频数据
    "OfferToReceiveVideo": true,
  },
  "optional": [],
};

//核心的Peer，实现建立连接和sdp协商
abstract class WebrtcCorePeer {
  late String id;
  late RTCPeerConnection peerConnection;

  late RTCDataChannel dataChannel;
  bool needDataChannel = true;
  bool dataChannelReady = false;
  late String dataChannelLabel;

  late List<MediaStream> streams;
  List<Map<String, dynamic>> remoteTracks = [];
  List<MediaStream> remoteStreams = [];
  Map<MediaStreamTrack, Map<MediaStream, RTCRtpSender>> trackSenders = {};

  Map<String, Function> handlers = {};

  bool firstNegotiation = true;
  bool isNegotiating = false;
  bool trickle = true;
  bool allowHalfTrickle = false;
  bool iceComplete = false;

  //sdp扩展属性，由外部传入
  Map<String, dynamic> extension = {};

  String Function(String sdp)? sdpTransform;
  bool _connected = false;
  List<String> pendingCandidates = [];

  bool destroying = false;
  bool destroyed = false;

  Map<String, dynamic> configuration = {};

  //PeerConnection约束
  Map<String, dynamic> pcConstraints = {
    "mandatory": {},
    "optional": [
      //如果要与浏览器互通开启DtlsSrtpKeyAgreement,此处不开启
      {"DtlsSrtpKeyAgreement": true},
    ],
  };

  WebrtcCorePeer();

  ///初始化连接，可以传入外部视频流
  Future<bool> init(
      {List<MediaStream> streams = const [],
      Map<String, dynamic> extension = const {}}) async {
    id = await cryptoGraphy.getRandomAsciiString(length: 8);
    this.extension = extension;
    var appDataProvider = AppDataProvider.instance;
    var iceServers = appDataProvider.defaultNodeAddress.iceServers;
    try {
      configuration['iceServers'] = iceServers;
      //1.创建连接
      peerConnection = await createPeerConnection(configuration, pcConstraints);
    } catch (err) {
      logger.e('createPeerConnection:$err');
      return false;
    }

    ///2.注册连接的事件监听器
    peerConnection.onIceConnectionState =
        (RTCIceConnectionState state) => {onIceConnectionState(state)};
    peerConnection.onIceGatheringState =
        (RTCIceGatheringState state) => {onIceGatheringState(state)};
    peerConnection.onConnectionState =
        (RTCPeerConnectionState state) => {onConnectionState(state)};
    peerConnection.onSignalingState =
        (RTCSignalingState state) => {onSignalingState(state)};
    peerConnection.onIceCandidate =
        (RTCIceCandidate candidate) => {onIceCandidate(candidate)};
    //peerConnection.onRenegotiationNeeded = () => {};

    //3.建立发送数据通道和接受数据通道
    if (needDataChannel) {
      var dataChannelDict = RTCDataChannelInit();
      //创建RTCDataChannel对象时设置的通道的唯一id
      dataChannelDict.id = 1;
      //表示通过RTCDataChannel的信息的到达顺序需要和发送顺序一致
      dataChannelDict.ordered = true;
      //最大重传时间
      dataChannelDict.maxRetransmitTime = -1;
      //最大重传次数
      dataChannelDict.maxRetransmits = -1;
      //传输协议
      dataChannelDict.protocol = 'sctp';
      //是否由用户代理或应用程序协商频道
      dataChannelDict.negotiated = false;
      dataChannelLabel = await cryptoGraphy.getRandomAsciiString(length: 20);
      dataChannel = await peerConnection.createDataChannel(
          dataChannelLabel, dataChannelDict);

      //建立数据通道的监听器
      peerConnection.onDataChannel = (RTCDataChannel dataChannel) => {
            dataChannel.onDataChannelState =
                (RTCDataChannelState state) => {onDataChannelState(state)},
            dataChannel.onMessage =
                (RTCDataChannelMessage message) => {onMessage(message)}
          };
    }

    /// 4.把本地的现有的视频流加入到连接中，这个流可以由参数传入
    this.streams = streams;
    if (streams != null && streams.isNotEmpty) {
      for (var stream in streams) {
        addStream(stream);
      }
    }

    /// 5.建立连接的监听轨道到来的监听器，当远方由轨道来的时候执行
    peerConnection.onTrack = (RTCTrackEvent event) => {onTrack(event)};

    logger.i('initial negotiation');

    /// 6. 开始协商，满足条件的话开始创建offer(状态合适，主叫或者被叫第二次)
    /// 或者被叫收到协商请求
    negotiate();

    return true;
  }

  ///连接状态事件
  onConnectionState(RTCPeerConnectionState state) {
    if (destroyed) return;
    if (peerConnection.connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      destroy('Connection failed.ERR_CONNECTION_FAILURE');
    }
  }

  ///ice连接状态事件
  onIceConnectionState(RTCIceConnectionState state) {
    if (destroyed) {
      return;
    }

    logger.i('onIceConnectionState (connection: $state)');
    emit('onIceConnectionState', state);

    if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
        state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
      _connected = true;
    }
    if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
      destroy('Ice connection failed.,ERR_ICE_CONNECTION_FAILURE');
    }
    if (state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
      destroy('Ice connection closed.,ERR_ICE_CONNECTION_CLOSED');
    }
  }

  onIceGatheringState(RTCIceGatheringState state) {
    if (destroyed) {
      return;
    }

    logger.i('onIceGatheringState (gathering: $state)');
    emit('onIceGatheringState', state);
  }

  /// signal状态事件
  onSignalingState(RTCSignalingState state) {
    if (destroyed) {
      return;
    }

    if (state == RTCSignalingState.RTCSignalingStateStable) {
      isNegotiating = false;
    }

    logger.i('signalingState %s', peerConnection.signalingState);
    emit('signalingState', state);
  }

  ///onIceCandidate事件表示candidate准备好，可以发送IceCandidate到远端
  onIceCandidate(RTCIceCandidate candidate) {
    if (destroyed) {
      return;
    }
    if (candidate.candidate != null && trickle) {
      emit('signal', {
        'type': 'candidate',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'sdpMid': candidate.sdpMid
        }
      });
    } else if (candidate.candidate == null && !iceComplete) {
      iceComplete = true;
      emit('iceComplete', '');
    }
  }

  //主叫方的数据通道状态事件
  onDataChannelState(RTCDataChannelState state) {
    if (_connected || destroyed) {
      return;
    }
    //数据通道打开
    if (state == RTCDataChannelState.RTCDataChannelOpen) {
      logger.i('on channel open');
      dataChannelReady = true;
    }
    //数据通道关闭
    if (state == RTCDataChannelState.RTCDataChannelClosed) {
      logger.i('on channel close');
      destroy('');
    }
  }

  //被叫方的数据传输事件
  onMessage(RTCDataChannelMessage message) {
    if (destroyed) {
      return;
    }
    var data = message.binary;
    logger.i(message.text);
  }

  /// 把流加入到连接中，比如把本地的视频流加入到连接中，从而让远程peer能够接收到
  /// @param {MediaStream} stream
  addStream(MediaStream stream) {
    if (destroying) return;
    if (destroyed) {
      throw 'cannot addStream after peer is destroyed,ERR_DESTROYED';
    }
    logger.i('addStream()');

    var tracks = stream.getTracks();
    for (var track in tracks) {
      addTrack(track, stream);
    }
  }

  /// 把轨道加入到流中，其目的是为了把流加入到连接中
  /// @param {MediaStreamTrack} track
  /// @param {MediaStream} stream
  addTrack(MediaStreamTrack track, MediaStream stream) async {
    if (destroying) return;
    if (destroyed) {
      throw 'cannot addTrack after peer is destroyed,ERR_DESTROYED';
    }
    logger.i('addTrack()');

    var streamSenders = trackSenders[track];
    if (streamSenders == null) {
      streamSenders = {};
      trackSenders[track] = streamSenders;
    }
    RTCRtpSender? sender = streamSenders[stream];
    if (sender == null) {
      sender = await peerConnection.addTrack(track, stream);
      streamSenders[stream] = sender;
      negotiate();
    } else {
      throw 'Track has already been added to that stream.,ERR_SENDER_ALREADY_ADDED';
    }
  }

  /// 在连接中用一个轨道取代另一个轨道
  /// @param {MediaStreamTrack} oldTrack
  /// @param {MediaStreamTrack} newTrack
  /// @param {MediaStream} stream
  replaceTrack(MediaStreamTrack oldTrack, MediaStreamTrack newTrack,
      MediaStream stream) async {
    if (destroying) return;
    if (destroyed) {
      throw 'cannot replaceTrack after peer is destroyed,ERR_DESTROYED';
    }
    logger.i('replaceTrack()');

    var streamSenders = trackSenders[oldTrack];
    if (streamSenders != null) {
      RTCRtpSender? sender = streamSenders[stream];
      if (sender == null) {
        throw 'Cannot replace track that was never added.,ERR_TRACK_NOT_ADDED';
      }
      if (newTrack != null) {
        trackSenders[newTrack] = streamSenders!;
      }
      if (sender.replaceTrack != null) {
        await sender.replaceTrack(newTrack);
      } else {
        destroy(
            'replaceTrack is not supported in this browser,ERR_UNSUPPORTED_REPLACETRACK');
      }
    }
  }

  /// 从连接中移除一个轨道
  /// @param {MediaStreamTrack} track
  /// @param {MediaStream} stream
  removeTrack(MediaStreamTrack track, MediaStream stream) async {
    if (destroying) return;
    if (destroyed) {
      throw 'cannot removeTrack after peer is destroyed,ERR_DESTROYED';
    }
    logger.i('removeSender()');

    var streamSenders = trackSenders[track];
    if (streamSenders != null) {
      RTCRtpSender? sender = streamSenders[stream];
      if (sender == null) {
        throw 'Cannot remove track that was never added.,ERR_TRACK_NOT_ADDED';
      }
      try {
        //sender.removed = true;
        await peerConnection.removeTrack(sender);
      } catch (err) {
        destroy('ERR_REMOVE_TRACK');
      }
      negotiate();
    }
  }

  /// 从连接中移除流
  /// @param {MediaStream} stream
  removeStream(MediaStream stream) {
    if (destroying) return;
    if (destroyed) {
      throw 'cannot removeStream after peer is destroyed,ERR_DESTROYED';
    }
    logger.i('removeSenders()');
    var tracks = stream.getTracks();
    for (var track in tracks) {
      removeTrack(track, stream);
    }
  }

  ///连接的监听轨道到来的监听器，当远方由轨道来的时候执行
  onTrack(RTCTrackEvent event) {
    if (destroyed) return;

    for (var eventStream in event.streams) {
      logger.i('on track');
      emit('track', {'track': event.track, 'stream': eventStream});

      remoteTracks.add({'track': event.track, 'stream': eventStream});

      if (remoteStreams != null && remoteStreams.isNotEmpty) {
        if (remoteStreams[0].id == eventStream.id) {
          return;
        }
      } // Only fire one 'stream' event, even though there may be multiple tracks per stream

      remoteStreams.add(eventStream);
      logger.i('on stream');
      emit('stream', eventStream);
    }
  }

  /// 注册一组回调函数，内部可以调用外部注册事件的方法
  /// name包括'signal','stream','track'
  /// 内部通过调用emit方法调用外部注册的方法
  on(String name, Function(dynamic event)? fn) {
    if (fn != null) {
      handlers[name] = fn;
    } else {
      handlers.remove(name);
    }
  }

  /// 调用外部事件注册方法
  emit(String name, dynamic event) {
    var handler = handlers[name];
    if (handler != null) {
      handler(event);
    }
  }

  ///被叫不能在第一次的时候主动发起协议过程，主叫或者被叫不在第一次的时候可以发起协商过程
  negotiate() async {}

  signal(dynamic data) async {}

  /// Filter trickle lines when trickle is disabled #354
  filterTrickle(sdp) {
    return sdp.replace('/a=ice-options:trickle\s\n/g', '');
  }

  //数据通道的缓冲区大小
  get bufferSize {
    final dataChannel = this.dataChannel;
    if (dataChannel != null) {
      return dataChannel.bufferedAmount;
    }
    return 0;
  }

  // 连接状态
  get connected {
    return (_connected &&
        dataChannel != null &&
        dataChannel.state == RTCDataChannelState.RTCDataChannelOpen);
  }

  //为连接加上候选的服务器
  addIceCandidate(Map<String, dynamic> candidate) async {
    var iceCandidate = RTCIceCandidate(candidate['candidate'],
        candidate['sdpMid'], candidate['sdpMLineIndex']);
    await peerConnection.addCandidate(iceCandidate);
  }

  /// 发送二进制消息 text/binary data to the remote peer.
  send(Uint8List message) {
    if (destroying) {
      return;
    }
    if (destroyed) {
      throw 'cannot send after peer is destroyed,ERR_DESTROYED';
    }
    if (dataChannel != null) {
      var dataChannelMessage = RTCDataChannelMessage.fromBinary(message);
      dataChannel?.send(dataChannelMessage);
    }
  }

  destroy(String err) {
    if (destroyed || destroying) return;
    logger.i('destroying (error: $err)');
    destroyed = true;
    destroying = false;
    _connected = false;
    remoteTracks = [];
    remoteStreams = [];
    trackSenders = {};

    final dataChannel = this.dataChannel;
    if (dataChannel != null) {
      try {
        dataChannel.close();
        dataChannelReady = false;
      } catch (err) {
        logger.e('close dataChannel err:$err');
      }

      // allow events concurrent with destruction to be handled
      dataChannel.onMessage = null;
      dataChannel.onDataChannelState = null;
    }
    final peerConnection = this.peerConnection;
    if (peerConnection != null) {
      try {
        peerConnection.close();
      } catch (err) {
        logger.e('close peerConnection err:$err');
      }

      // allow events concurrent with destruction to be handled
      peerConnection.onIceConnectionState = null;
      peerConnection.onIceGatheringState = null;
      peerConnection.onSignalingState = null;
      peerConnection.onIceCandidate = null;
      peerConnection.onTrack = null;
      peerConnection.onDataChannel = null;
    }
    // this.peerConnection = null;
    // this.dataChannel = null;

    emit('error', err);
    emit('close', '');
  }
}

///主动发起连接的一方
class MasterWebrtcCorePeer extends WebrtcCorePeer {
  MasterWebrtcCorePeer();

  ///主叫发起协商过程
  @override
  negotiate() async {
    if (destroying) {
      return;
    }
    if (destroyed) {
      throw 'cannot negotiate after peer is destroyed,ERR_DESTROYED';
    }
    firstNegotiation = false;
    if (isNegotiating) {
      logger.i('already negotiating');
      return;
    }
    logger.i('start negotiation');
    await createOffer();
    isNegotiating = true;
  }

  ///创建offer，设置到本地会话描述，并发送offer
  createOffer() async {
    if (destroyed) return;

    RTCSessionDescription offer =
        await peerConnection.createOffer(sdpConstraints);
    String? sdp = offer.sdp;
    if (destroyed) {
      return;
    }
    if (!trickle && !allowHalfTrickle && sdp != null) {
      offer.sdp = filterTrickle(sdp);
    }
    //传入的sdp的处理方法
    if (sdpTransform != null && sdp != null) {
      offer.sdp = sdpTransform!(sdp);
    }

    await peerConnection.setLocalDescription(offer);
    logger.i('createOffer success');
    if (destroyed) {
      return;
    }
    if (trickle || iceComplete) {
      await sendOffer(offer);
    }
  }

  ///调用外部方法发送offer
  sendOffer(RTCSessionDescription offer) async {
    if (destroyed) {
      return;
    }
    var signal = await peerConnection.getLocalDescription();
    if (signal == null) {
      signal = offer;
      logger.i('signal');
      emit('signal',
          {'type': signal.type, 'sdp': signal.sdp, 'extension': extension});
    }
  }

  //从信号服务器传回来远程的webrtcSignal信息，从signalAction回调
  signal(dynamic data) async {
    if (destroying) {
      return;
    }
    if (destroyed) {
      throw 'cannot signal after peer is destroyed,ERR_DESTROYED';
    }
    if (data is String) {
      try {
        data = JsonUtil.toMap(data);
      } catch (err) {
        data = {};
      }
    }
    logger.i('signal()');

    //被要求重新协商，则发起协商
    if (data.renegotiate != null) {
      logger.i('got request to renegotiate');
      negotiate();
    }
    //被要求收发，则加收发器
    else if (data.transceiverRequest != null) {
      logger.i('got request for transceiver');
      // addTransceiver(
      //     kind: data.transceiverRequest.kind,
      //     init: data.transceiverRequest.init);
    }
    //如果是候选信息
    else if (data.candidate != null) {
      RTCSessionDescription? remoteDescription =
          await peerConnection.getRemoteDescription();
      //如果远程描述已经设置，加候选，否则，加入候选清单
      if (remoteDescription != null && remoteDescription.type != null) {
        addIceCandidate(data.candidate);
      } else {
        pendingCandidates.add(data.candidate);
      }
    }
    //如果sdp信息，则设置远程描述，并处理所有的候选清单中候选服务器
    else if (data.sdp != null) {
      await peerConnection.setRemoteDescription(data as RTCSessionDescription);
      if (destroyed) return;

      for (var candidate in pendingCandidates) {
        Map<String, dynamic> map =
            JsonUtil.toMap(candidate) as Map<String, dynamic>;
        addIceCandidate(map);
      }
      pendingCandidates = [];
    }
    //如果什么都不是，报错
    else {
      destroy('signal() called with invalid signal data,ERR_SIGNALING');
    }
  }

  /// 为连接加上收发器
  /// @param {String} kind
  /// @param {Object} init
  addTransceiver({
    required MediaStreamTrack track,
    required RTCRtpMediaType kind,
    required RTCRtpTransceiverInit init,
  }) async {
    if (destroying) return;
    if (destroyed) {
      throw 'cannot addTransceiver after peer is destroyed,ERR_DESTROYED';
    }
    logger.i('addTransceiver()');

    //直接加上收发器，并开始协商
    try {
      await peerConnection.addTransceiver(track: track, kind: kind, init: init);
      negotiate();
    } catch (err) {
      logger.e(err);
      //this.destroy(errCode(err, 'ERR_ADD_TRANSCEIVER'))
    }
  }
}

///在收到主动方的signal后，如果不存在，则创建
class FollowWebrtcCorePeer extends WebrtcCorePeer {
  FollowWebrtcCorePeer();

  ///被叫的协商时发送再协商信号给主叫，要求重新发起协商
  @override
  negotiate() async {
    if (destroying) {
      return;
    }
    if (destroyed) {
      throw 'cannot negotiate after peer is destroyed,ERR_DESTROYED';
    }
    //被叫不能在第一次的时候主动发起协议过程
    if (firstNegotiation) {
      logger.e('non-initiator initial negotiation request discarded');
      firstNegotiation = false;
      return;
    }
    firstNegotiation = false;
    if (isNegotiating) {
      logger.i('already negotiating');
      return;
    }
    //被叫收到协商的请求
    logger.i('requesting negotiation from initiator');
    emit('signal', {
      // request initiator to renegotiate
      'type': 'renegotiate',
      'renegotiate': true
    });
    isNegotiating = true;
  }

  ///创建answer，发生在被叫方，将answer回到主叫方
  createAnswer() async {
    if (destroyed) {
      return;
    }

    RTCSessionDescription answer =
        await peerConnection.createAnswer(sdpConstraints);
    if (destroyed) {
      return;
    }
    var sdp = answer.sdp;
    if (!trickle && !allowHalfTrickle && sdp != null) {
      answer.sdp = filterTrickle(sdp);
    }
    if (sdpTransform != null && sdp != null) {
      answer.sdp = sdpTransform!(sdp);
    }

    if (trickle || iceComplete) {
      sendAnswer(answer);
    }
    await peerConnection.setLocalDescription(answer);
  }

  //发送answer
  sendAnswer(RTCSessionDescription answer) async {
    if (destroyed) {
      return;
    }
    var signal = await peerConnection.getLocalDescription();
    if (signal != null) {
      signal = answer;
    }
    logger.i('signal');
    if (signal != null) {
      emit('signal',
          {'type': signal.type, 'sdp': signal.sdp, 'extension': extension});
    }
    //if (!this.initiator) this._requestMissingTransceivers() //ios unSupport
  }

  //从信号服务器传回来远程的webrtcSignal信息，从signalAction回调
  signal(dynamic data) async {
    if (destroying) return;
    if (destroyed) throw 'cannot signal after peer is destroyed,ERR_DESTROYED';
    if (data is String) {
      try {
        data = JsonUtil.toMap(data);
      } catch (err) {
        data = {};
      }
    }
    logger.i('signal()');

    //如果是候选信息
    if (data.candidate != null) {
      RTCSessionDescription? remoteDescription =
          await peerConnection.getRemoteDescription();
      //如果远程描述已经设置，加候选，否则，加入候选清单
      if (remoteDescription != null && remoteDescription.type != null) {
        addIceCandidate(data.candidate);
      } else {
        pendingCandidates.add(data.candidate);
      }
    }
    //如果sdp信息，则设置远程描述，并处理所有的候选清单中候选服务器
    else if (data.sdp != null) {
      await peerConnection.setRemoteDescription(data as RTCSessionDescription);
      if (destroyed) return;
      for (var candidate in pendingCandidates) {
        Map<String, dynamic> map =
            JsonUtil.toMap(candidate) as Map<String, dynamic>;
        addIceCandidate(map);
      }
      pendingCandidates = [];
      //如果远程描述是offer请求，则创建answer
      var remoteDescription = await peerConnection.getRemoteDescription();
      if (remoteDescription != null && remoteDescription.type == 'offer') {
        createAnswer();
      }
    }
    //如果什么都不是，报错
    else {
      destroy('signal() called with invalid signal data,ERR_SIGNALING');
    }
  }

  /// 为连接加上收发器
  /// @param {String} kind
  /// @param {Object} init
  addTransceiver({
    required MediaStreamTrack track,
    required RTCRtpMediaType kind,
    required RTCRtpTransceiverInit init,
  }) async {
    if (destroying) return;
    if (destroyed) {
      throw 'cannot addTransceiver after peer is destroyed,ERR_DESTROYED';
    }
    logger.i('addTransceiver()');

    emit('signal', {
      // request initiator to renegotiate
      'type': 'transceiverRequest',
      'transceiverRequest': {kind, init}
    });
  }
}
