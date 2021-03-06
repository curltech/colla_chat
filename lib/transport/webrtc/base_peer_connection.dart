import 'dart:typed_data';

import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:colla_chat/transport/webrtc/peer_video_render.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../crypto/cryptography.dart';
import '../../provider/app_data_provider.dart';

enum SignalType { renegotiate, transceiverRequest, candidate, sdp }

class WebrtcSignal {
  late String signalType;
  bool? renegotiate; //是否需要重新协商
  Map<String, dynamic>? transceiverRequest; //收发器请求
  //ice candidate信息，ice服务器的地址
  RTCIceCandidate? candidate;

  // sdp信息，peer的信息
  RTCSessionDescription? sdp;
  SignalExtension? extension;

  WebrtcSignal(this.signalType,
      {this.renegotiate,
      this.transceiverRequest,
      this.candidate,
      this.sdp,
      this.extension});

  WebrtcSignal.fromJson(Map json) {
    signalType = json['signalType'];
    renegotiate = json['renegotiate'];
    transceiverRequest = json['transceiverRequest'];
    Map<String, dynamic> iceCandidate = json['candidate'];
    candidate = RTCIceCandidate(iceCandidate['candidate'],
        iceCandidate['sdpMid'], iceCandidate['sdpMLineIndex']);
    Map<String, dynamic> sessionDescription = json['sdp'];
    sdp = RTCSessionDescription(
        sessionDescription['sdp'], sessionDescription['type']);
    var extension = json['extension'];
    this.extension = SignalExtension.fromJson(extension);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'signalType': signalType,
      'renegotiate': renegotiate,
      'transceiverRequest': transceiverRequest,
    });
    var sdp = this.sdp;
    if (sdp != null) {
      json['sdp'] = sdp.toMap();
    }
    var candidate = this.candidate;
    if (candidate != null) {
      json['candidate'] = candidate.toMap();
    }
    var extension = this.extension;
    if (extension != null) {
      json['extension'] = extension.toJson();
    }
    return json;
  }
}

///加入的房间号
class Room {
  String? id;
  String? type;
  String? action;
  String? roomId;
  String? identity;

  Room(this.roomId, {this.id, this.type, this.action, this.identity});

  Room.fromJson(Map json) {
    id = json['id'];
    roomId = json['roomId'];
    type = json['type'];
    action = json['action'];
    identity = json['identity'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'id': id,
      'roomId': roomId,
      'type': type,
      'action': action,
      'identity': identity,
    });
    return json;
  }
}

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

///可以注册的事件
enum WebrtcEventType {
  create, //创建被叫连接
  signal,
  connect,
  close,
  message,
  stream,
  track,
  error,
  connectionState,
  iceConnectionState,
  iceGatheringState,
  signalingState,
  iceComplete,
  dataChannelState,
}

enum PeerConnectionStatus {
  created,
  negotiating,
  failed,
  connected,
  closed,
  //激活和失活状态是连接被关闭，但是保存了sdp和candidate信息的情况下，快速恢复连接的操作，省去了协商过程
  active,
  inactive,
}

/// 基础的PeerConnection，实现建立连接和sdp协商
/// 代表一个本地与远程的webrtc连接，这个类不含业务含义，不包含与信号服务器的交互部分
/// 有两个子类，分别代表主动发起连接的，和被动接受连接的，在两种场景下，协商过程中的行为稍有不同
abstract class BasePeerConnection {
  //唯一随机码，代表webrtc的连接
  late String id;

  //webrtc连接，在失活状态下为空，init后不为空
  RTCPeerConnection? peerConnection;

  //远程传来的sdp，
  RTCSessionDescription? sdp;

  //本地产生的candidate
  RTCIceCandidate? localCandidate;

  //远程传入的candidate信息，可能先于offer或者answer到来，缓存起来
  //对主叫方来说，等待answer到来以后统一处理
  //对被叫方来说，等待offer到来以后统一处理
  List<RTCIceCandidate> remoteCandidates = [];

  //主动发送数据的通道
  RTCDataChannel? dataChannel;

  //是否需要主动建立数据通道
  bool needDataChannel = true;

  //数据通道的状态是否打开
  bool dataChannelOpen = false;

  //数据通道的标签
  late String dataChannelLabel;

  //本地的媒体流渲染器数组，在初始化的时候设置
  List<PeerVideoRenderer> localVideoRenders = [];

  //远程媒体流渲染器数组，在onAddStream,onAddTrack等的回调方法中得到
  List<PeerVideoRenderer> remoteVideoRenders = [];

  //远程媒体流的轨道和对应的流的数组
  List<Map<MediaStreamTrack, MediaStream>> remoteTracks = [];

  //远程媒体流的轨道，流和发送者之间的关系
  Map<MediaStreamTrack, Map<MediaStream, RTCRtpSender>> trackSenders = {};

  //外部使用时注册的回调方法，也就是注册事件
  //WebrtcEvent定义了事件的名称
  Map<WebrtcEventType, Function> handlers = {};

  //是否第一次协商
  bool firstNegotiation = true;

  //是否正在协商，连接创建到连接建立完成的这段时间
  bool isNegotiating = false;

  //连接双方要协商turn的地址和端口，也就是candidate协商过程是否完成
  //这个过程在offer，answer协商之后
  bool iceComplete = false;

  //sdp扩展属性，由外部传入，这个属性用于传递定制的属性
  //一般包括指定的iceServer，room，peerId，clientId
  SignalExtension? extension;

  //连接是否完全建立，即协商过程结束
  bool connected = false;

  //是否关闭连接完成
  bool destroyed = false;

  //建立连接的PeerConnection约束
  Map<String, dynamic> pcConstraints = {
    "mandatory": {},
    "optional": [
      //如果要与浏览器互通开启DtlsSrtpKeyAgreement,此处不开启
      {"DtlsSrtpKeyAgreement": true},
    ],
  };

  BasePeerConnection();

  ///初始化连接，可以传入外部视频流，这是异步的函数，不能在构造里调用
  ///建立连接对象，设置好回调函数，然后如果是master发起协商，如果是follow，在收到offer才开始创建，
  ///只有协商完成，数据通道打开，才算真正完成连接
  ///可输入的参数包括外部媒体流和定制扩展属性
  Future<bool> init(
      {bool getUserMedia = false,
      List<MediaStream> streams = const [],
      required SignalExtension extension}) async {
    id = await cryptoGraphy.getRandomAsciiString(length: 8);
    this.extension = extension;
    var appDataProvider = AppDataProvider.instance;
    var iceServers = appDataProvider.defaultNodeAddress.iceServers;
    try {
      var configuration = {'iceServers': iceServers};
      if (extension != null) {
        var iceServers = extension.iceServers;
        if (iceServers != null) {
          configuration['iceServers'] = iceServers;
        }
      }
      //1.创建连接
      this.peerConnection =
          await createPeerConnection(configuration, pcConstraints);
      logger.i('createPeerConnection end:$id');
    } catch (err) {
      logger.e('createPeerConnection:$err');
      return false;
    }

    RTCPeerConnection peerConnection = this.peerConnection!;

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
    peerConnection.onRenegotiationNeeded = () => {onRenegotiationNeeded()};

    ///3.建立发送数据通道和接受数据通道
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
      //创建发送数据通道
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
      logger.i('createDataChannel and onDataChannel end');
    }

    /// 4.把本地的现有的视频流加入到连接中，这个流可以由参数传入
    if (getUserMedia) {
      var render = PeerVideoRenderer();
      render.getUserMedia();
      render.bindRTCVideoRenderer();
      localVideoRenders.add(render);
      var streamId = render.mediaStream!.id;
      addStream(render.mediaStream!);
      logger.i('add getUserMedia stream $streamId');
    }
    if (streams.isNotEmpty) {
      for (var stream in streams) {
        var render = PeerVideoRenderer(mediaStream: stream);
        render.bindRTCVideoRenderer();
        localVideoRenders.add(render);
        addStream(stream);
        var streamId = stream.id;
        logger.i('add stream $streamId');
      }
    }

    /// 5.建立连接的监听轨道到来的监听器，当远方由轨道来的时候执行
    peerConnection.onAddStream = (MediaStream stream) {
      onAddStream(stream);
    };
    peerConnection.onRemoveStream = (MediaStream stream) {
      onRemoveStream(stream);
    };
    peerConnection.onAddTrack = (MediaStream stream, MediaStreamTrack track) {
      onAddTrack(stream, track);
    };
    peerConnection.onRemoveTrack =
        (MediaStream stream, MediaStreamTrack track) {
      onRemoveTrack(stream, track);
    };
    peerConnection.onTrack = (RTCTrackEvent event) {
      onTrack(event);
    };

    /// 6. 开始协商，满足条件的话开始创建offer(状态合适，主叫或者被叫第二次)
    /// 或者被叫收到协商请求
    logger.i('negotiation start');
    negotiate();
    logger.i('negotiation end');

    return true;
  }

  ///连接状态事件
  onConnectionState(RTCPeerConnectionState state) {
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i(
        'connectionState:${peerConnection.connectionState},onConnectionState event:$state');
    if (destroyed) {
      return;
    }
    emit(WebrtcEventType.connectionState, state);
    if (peerConnection.connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      logger.e('Connection failed.ERR_CONNECTION_FAILURE');
      close();
    }
  }

  ///ice连接状态事件
  onIceConnectionState(RTCIceConnectionState state) {
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i(
        'iceConnectionState:${peerConnection.iceConnectionState},onIceConnectionState event:$state');
    if (destroyed) {
      return;
    }

    emit(WebrtcEventType.iceConnectionState, state);
    if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
        state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
      connected = true;
    }
    if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
      logger.e('Ice connection failed.,ERR_ICE_CONNECTION_FAILURE');
      close();
    }
    if (state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
      logger.e('Ice connection closed.,ERR_ICE_CONNECTION_CLOSED');
      close();
    }
  }

  onIceGatheringState(RTCIceGatheringState state) {
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i(
        'iceGatheringState:${peerConnection.iceGatheringState},onIceGatheringState event:$state');
    if (destroyed) {
      return;
    }
    emit(WebrtcEventType.iceGatheringState, state);
  }

  /// signal状态事件
  onSignalingState(RTCSignalingState state) {
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i(
        'signalingState:${peerConnection.signalingState},onSignalingState event:$state');
    if (destroyed) {
      return;
    }
    if (state == RTCSignalingState.RTCSignalingStateStable) {
      isNegotiating = false;
    }
    emit(WebrtcEventType.signalingState, state);
  }

  ///onIceCandidate事件表示本地candidate准备好，可以发送IceCandidate到远端
  onIceCandidate(RTCIceCandidate candidate) {
    localCandidate = candidate;
    logger.i('onIceCandidate event:${candidate.toMap()}');
    if (destroyed) {
      return;
    }
    if (candidate.candidate != null) {
      //发送candidate信号
      emit(WebrtcEventType.signal,
          WebrtcSignal(SignalType.candidate.name, candidate: candidate));
    } else if (candidate.candidate == null && !iceComplete) {
      iceComplete = true;
      logger.i('onIceCandidate event，iceComplete true');
      emit(WebrtcEventType.iceComplete, '');
    }
  }

  onRenegotiationNeeded() {
    logger.i('onRenegotiationNeeded event');
  }

  //数据通道状态事件
  onDataChannelState(RTCDataChannelState state) {
    logger.i('onDataChannelState event:$state');
    if (destroyed) {
      return;
    }
    //数据通道打开
    if (state == RTCDataChannelState.RTCDataChannelOpen) {
      logger.i('on channel open');
      dataChannelOpen = true;
    }
    //数据通道关闭
    if (state == RTCDataChannelState.RTCDataChannelClosed) {
      logger.i('on channel close');
      close();
    }
  }

  /// 被叫方的数据传输事件
  /// webrtc的数据通道发来的消息可以是ChainMessage，
  /// 也可以是简单的非ChainMessage，比如最简单的文本或者复合文档，也就是ChatMessage
  onMessage(RTCDataChannelMessage message) {
    logger.i('onMessage event:${message.text}');
    if (destroyed) {
      return;
    }
    var data = message.binary;
    emit(WebrtcEventType.message, data);
  }

  /// 把流加入到连接中，比如把本地的视频流加入到连接中，从而让远程peer能够接收到
  /// @param {MediaStream} stream
  addStream(MediaStream stream) {
    logger.i('addStream()');
    if (destroyed) {
      throw 'cannot addStream after peer is destroyed,ERR_DESTROYED';
    }
    var tracks = stream.getTracks();
    for (var track in tracks) {
      addTrack(track, stream);
    }
  }

  /// 把轨道加入到流中，其目的是为了把流加入到连接中
  /// @param {MediaStreamTrack} track
  /// @param {MediaStream} stream
  addTrack(MediaStreamTrack track, MediaStream stream) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i('addTrack()');
    if (destroyed) {
      throw 'cannot addTrack after peer is destroyed,ERR_DESTROYED';
    }
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
    logger.i('replaceTrack()');
    if (destroyed) {
      throw 'cannot replaceTrack after peer is destroyed,ERR_DESTROYED';
    }
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
        logger.e(
            'replaceTrack is not supported in this browser,ERR_UNSUPPORTED_REPLACETRACK');
        close();
      }
    }
  }

  /// 从连接中移除一个轨道
  /// @param {MediaStreamTrack} track
  /// @param {MediaStream} stream
  removeTrack(MediaStreamTrack track, MediaStream stream) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i('removeSender()');
    if (destroyed) {
      throw 'cannot removeTrack after peer is destroyed,ERR_DESTROYED';
    }
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
        logger.e('ERR_REMOVE_TRACK');
        close();
      }
      negotiate();
    }
  }

  /// 从连接中移除流
  /// @param {MediaStream} stream
  removeStream(MediaStream stream) {
    logger.i('removeStream');
    if (destroyed) {
      throw 'cannot removeStream after peer is destroyed,ERR_DESTROYED';
    }
    var tracks = stream.getTracks();
    for (var track in tracks) {
      removeTrack(track, stream);
    }
  }

  ///对远端的连接来说，当有stream或者track到来时触发
  ///此处将流加入到render中
  onAddStream(stream) {
    logger.i('onAddStream event');
  }

  onRemoveStream(stream) {
    logger.i('onRemoveStream event');
  }

  onAddTrack(stream, track) {
    logger.i('onAddTrack event');
  }

  onRemoveTrack(stream, track) {
    logger.i('onRemoveTrack event');
  }

  ///连接的监听轨道到来的监听器，当远方由轨道来的时候执行
  onTrack(RTCTrackEvent event) {
    logger.i('onTrack event');
    if (destroyed) {
      return;
    }

    for (var eventStream in event.streams) {
      logger.i('on track');
      emit(WebrtcEventType.track, {event.track: eventStream});
      remoteTracks.add({event.track: eventStream});

      if (remoteVideoRenders.isNotEmpty) {
        if (remoteVideoRenders[0].id == eventStream.id) {
          return;
        }
      }

      remoteVideoRenders.add(PeerVideoRenderer(mediaStream: eventStream));
      logger.i('on stream');
      emit(WebrtcEventType.stream, eventStream);
    }
  }

  /// 注册一组回调函数，内部可以调用外部注册事件的方法
  /// name包括'signal','stream','track'
  /// 内部通过调用emit方法调用外部注册的方法
  on(WebrtcEventType name, Function? fn) {
    if (fn != null) {
      handlers[name] = fn;
    } else {
      handlers.remove(name);
    }
  }

  /// 调用外部事件注册方法
  emit(WebrtcEventType name, dynamic event) {
    var handler = handlers[name];
    if (handler != null) {
      handler(event);
    }
  }

  ///被叫不能在第一次的时候主动发起协议过程，主叫或者被叫不在第一次的时候可以发起协商过程
  negotiate() async {}

  ///外部在收到信号的时候调用
  signal(WebrtcSignal webrtcSignal) async {}

  ///数据通道的缓冲区大小
  get bufferSize {
    final dataChannel = this.dataChannel;
    if (dataChannel != null) {
      return dataChannel.bufferedAmount;
    }
    return 0;
  }

  ///为连接加上候选的服务器
  addIceCandidate(RTCIceCandidate iceCandidate) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    await peerConnection.addCandidate(iceCandidate);
  }

  /// 发送二进制消息 text/binary data to the remote peer.
  send(Uint8List message) {
    if (destroyed) {
      throw 'cannot send after peer is destroyed,ERR_DESTROYED';
    }
    final dataChannel = this.dataChannel;
    if (dataChannel != null) {
      var dataChannelMessage = RTCDataChannelMessage.fromBinary(message);
      dataChannel.send(dataChannelMessage);
    }
  }

  ///关闭连接
  close() {
    if (destroyed) {
      return;
    }
    destroyed = true;
    connected = false;
    remoteTracks = [];
    remoteVideoRenders = [];
    trackSenders = {};

    final dataChannel = this.dataChannel;
    if (dataChannel != null) {
      try {
        dataChannel.close();
      } catch (err) {
        logger.e('close dataChannel err:$err');
      }
      dataChannelOpen = false;
      // allow events concurrent with destruction to be handled
      dataChannel.onMessage = null;
      dataChannel.onDataChannelState = null;
      this.dataChannel = null;
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
    emit(WebrtcEventType.error, '');
    emit(WebrtcEventType.close, '');
  }
}

///主动发起连接的一方
class MasterPeerConnection extends BasePeerConnection {
  //作为主叫方创建的offer
  RTCSessionDescription? offer;

  MasterPeerConnection();

  ///主叫发起协商过程
  @override
  negotiate() async {
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
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i('start createOffer');
    if (destroyed) {
      return;
    }

    RTCSessionDescription offer =
        await peerConnection.createOffer(sdpConstraints);
    await peerConnection.setLocalDescription(offer);
    logger.i('createOffer success');
    if (destroyed) {
      return;
    }
    if (!iceComplete) {
      logger.i('sendOffer iceComplete false');
    }
    await sendOffer(offer);
  }

  ///调用外部方法发送offer
  sendOffer(RTCSessionDescription offer) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i('sendOffer');
    if (destroyed) {
      return;
    }
    var sdp = await peerConnection.getLocalDescription();
    if (sdp == null) {
      sdp = offer;
      emit(WebrtcEventType.signal,
          WebrtcSignal(SignalType.sdp.name, sdp: sdp, extension: extension));
    }
  }

  ///从信号服务器传回来远程的webrtcSignal信息，从signalAction回调
  @override
  signal(WebrtcSignal webrtcSignal) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    if (destroyed) {
      throw 'cannot signal after peer is destroyed,ERR_DESTROYED';
    }
    String signalType = webrtcSignal.signalType;
    logger.i('signal signalType:$signalType');
    var candidate = webrtcSignal.candidate;
    var sdp = webrtcSignal.sdp;
    //被要求重新协商，则发起协商
    if (signalType == SignalType.renegotiate.name &&
        webrtcSignal.renegotiate != null) {
      logger.i('got request to renegotiate');
      negotiate();
    }
    //被要求收发，则加收发器
    else if (webrtcSignal.transceiverRequest != null) {
      logger.i('got request for transceiver');
      // addTransceiver(
      //     kind: data.transceiverRequest.kind,
      //     init: data.transceiverRequest.init);
    }
    //如果是候选信息
    else if (signalType == SignalType.candidate.name && candidate != null) {
      RTCSessionDescription? remoteDescription =
          await peerConnection.getRemoteDescription();
      //如果远程描述已经设置，加候选，否则，加入候选清单
      if (remoteDescription != null && remoteDescription.type != null) {
        addIceCandidate(candidate);
      } else {
        remoteCandidates.add(candidate);
      }
    }
    //如果sdp信息，则设置远程描述，并处理所有的候选清单中候选服务器
    //对主叫节点来说，sdp应该是answer
    else if (signalType == SignalType.sdp.name && sdp != null) {
      await peerConnection.setRemoteDescription(sdp);
      if (destroyed) {
        return;
      }

      for (var candidate in remoteCandidates) {
        addIceCandidate(candidate);
      }
      remoteCandidates = [];
    }
    //如果什么都不是，报错
    else {
      throw 'signal called with invalid signal type,ERR_SIGNALING';
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
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i('addTransceiver()');
    if (destroyed) {
      throw 'cannot addTransceiver after peer is destroyed,ERR_DESTROYED';
    }

    //直接加上收发器，并开始协商
    try {
      await peerConnection.addTransceiver(track: track, kind: kind, init: init);
      negotiate();
    } catch (err) {
      logger.e(err);
      close();
    }
  }
}

///在收到主动方的signal后，如果不存在，则创建
class SlavePeerConnection extends BasePeerConnection {
  //作为被叫方创建的answer
  RTCSessionDescription? answer;

  SlavePeerConnection();

  ///被叫的协商时发送再协商信号给主叫，要求重新发起协商
  @override
  negotiate() async {
    logger.i('requesting negotiation from initiator');
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
    emit(
        WebrtcEventType.signal, WebrtcSignal('renegotiate', renegotiate: true));
    isNegotiating = true;
  }

  ///创建answer，发生在被叫方，将answer回到主叫方
  createAnswer() async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i('createAnswer');
    if (destroyed) {
      return;
    }

    RTCSessionDescription answer =
        await peerConnection.createAnswer(sdpConstraints);
    await peerConnection.setLocalDescription(answer);
    if (destroyed) {
      return;
    }
    if (!iceComplete) {
      logger.i('sendAnswer iceComplete false');
    }
    await sendAnswer(answer);
  }

  //发送answer
  sendAnswer(RTCSessionDescription answer) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i('sendAnswer');
    if (destroyed) {
      return;
    }
    var sdp = await peerConnection.getLocalDescription();
    if (sdp != null) {
      sdp = answer;
    }
    if (sdp != null) {
      emit(WebrtcEventType.signal,
          WebrtcSignal(SignalType.sdp.name, sdp: sdp, extension: extension));
    }
  }

  ///从信号服务器传回来远程的webrtcSignal信息，从signalAction回调
  @override
  signal(WebrtcSignal webrtcSignal) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i('signal');
    if (destroyed) {
      throw 'cannot signal after peer is destroyed,ERR_DESTROYED';
    }
    String signalType = webrtcSignal.signalType;
    var candidate = webrtcSignal.candidate;
    var sdp = webrtcSignal.sdp;
    //如果是候选信息
    if (signalType == SignalType.candidate.name && candidate != null) {
      RTCSessionDescription? remoteDescription =
          await peerConnection.getRemoteDescription();
      //如果远程描述已经设置，加候选，否则，加入候选清单
      if (remoteDescription != null && remoteDescription.type != null) {
        addIceCandidate(candidate);
      } else {
        remoteCandidates.add(candidate);
      }
    }
    //如果sdp信息，则设置远程描述，并处理所有的候选清单中候选服务器
    else if (signalType == SignalType.sdp.name && sdp != null) {
      await peerConnection.setRemoteDescription(sdp);
      if (destroyed) {
        return;
      }
      for (var candidate in remoteCandidates) {
        addIceCandidate(candidate);
      }
      remoteCandidates = [];
      //如果远程描述是offer请求，则创建answer
      var remoteDescription = await peerConnection.getRemoteDescription();
      if (remoteDescription != null && remoteDescription.type == 'offer') {
        await createAnswer();
      }
    }
    //如果什么都不是，报错
    else {
      throw 'signal called with invalid signal data,ERR_SIGNALING';
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
    if (destroyed) {
      throw 'cannot addTransceiver after peer is destroyed,ERR_DESTROYED';
    }
    logger.i('addTransceiver()');

    emit(
        WebrtcEventType.signal,
        WebrtcSignal(SignalType.transceiverRequest.name,
            transceiverRequest: {'kind': kind, 'init': init}));
  }
}
