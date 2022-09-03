import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/util.dart';
import 'package:colla_chat/transport/webrtc/advanced_peer_connection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../crypto/cryptography.dart';
import '../../provider/app_data_provider.dart';

enum SignalType {
  renegotiate,
  transceiverRequest,
  candidate,
  sdp,
  offer,
  answer
}

class WebrtcSignal {
  late String signalType;
  bool? renegotiate; //是否需要重新协商
  Map<String, dynamic>? transceiverRequest; //收发器请求
  //ice candidate信息
  List<RTCIceCandidate>? candidates;

  // sdp信息，peer的信息
  RTCSessionDescription? sdp;
  SignalExtension? extension;

  WebrtcSignal(this.signalType,
      {this.renegotiate,
      this.transceiverRequest,
      this.candidates,
      this.sdp,
      this.extension});

  WebrtcSignal.fromJson(Map json) {
    signalType = json['signalType'];
    renegotiate = json['renegotiate'];
    transceiverRequest = json['transceiverRequest'];
    List<dynamic>? iceCandidates = json['candidates'];
    if (iceCandidates != null) {
      candidates = [];
      for (var iceCandidate in iceCandidates) {
        var candidate = RTCIceCandidate(iceCandidate['candidate'],
            iceCandidate['sdpMid'], iceCandidate['sdpMLineIndex']);
        candidates!.add(candidate);
      }
    }
    Map<String, dynamic>? sessionDescription = json['sdp'];
    if (sessionDescription != null) {
      sdp = RTCSessionDescription(
          sessionDescription['sdp'], sessionDescription['type']);
    }
    var extension = json['extension'];
    if (extension != null) {
      this.extension = SignalExtension.fromJson(extension);
    }
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
    var candidates = this.candidates;
    if (candidates != null) {
      List<dynamic> iceCandidates = [];
      for (var candidate in candidates) {
        iceCandidates.add(candidate.toMap());
      }
      json['candidates'] = iceCandidates;
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
  created, //创建被叫连接
  signal, //发送信号
  onSignal, //接收到信号
  connected,
  closed,
  status, //状态发生变化
  message, //接收到消息
  stream,
  removeStream,
  track,
  addTrack,
  removeTrack,
  error,
  iceCandidate,
  connectionState,
  iceConnectionState,
  iceGatheringState,
  signalingState,
  iceCompleted,
  dataChannelState,
}

enum PeerConnectionStatus {
  none,
  created,
  init,
  reconnecting,
  negotiating, //协商过程中
  negotiated,
  failed,
  connected, //连接是否完全建立，即协商过程结束
  closed, //是否关闭连接完成
  //激活和失活状态是连接被关闭，但是保存了sdp和candidate信息的情况下，快速恢复连接的操作，省去了协商过程
  active,
  inactive,
}

/// 基础的PeerConnection，实现建立连接和sdp协商
/// 代表一个本地与远程的webrtc连接，这个类不含业务含义，不包含与信号服务器的交互部分
/// 有两个子类，分别代表主动发起连接的，和被动接受连接的，在两种场景下，协商过程中的行为稍有不同
class BasePeerConnection {
  //唯一随机码，代表webrtc的连接
  late String id;
  bool initiator;

  //webrtc连接，在失活状态下为空，init后不为空
  RTCPeerConnection? peerConnection;
  PeerConnectionStatus _status = PeerConnectionStatus.created;

  //数据通道的状态是否打开
  bool dataChannelOpen = false;

  //本地的sdp，
  RTCSessionDescription? localSdp;

  //远程传来的sdp，
  RTCSessionDescription? remoteSdp;

  //本地产生的candidate
  List<RTCIceCandidate> localCandidates = [];

  //远程传入的candidate信息，可能先于offer或者answer到来，缓存起来
  //对主叫方来说，等待answer到来以后统一处理
  //对被叫方来说，等待offer到来以后统一处理
  List<RTCIceCandidate> remoteCandidates = [];

  //主动发送数据的通道
  RTCDataChannel? dataChannel;

  //是否需要主动建立数据通道
  bool needDataChannel = true;

  //本地媒体流渲染器数组，在init方法中传入
  //Map<String, MediaStream> localStreams = {};

  //远程媒体流渲染器数组，在onAddStream,onAddTrack等的回调方法中得到
  Map<String, MediaStream> streams = {};

  //媒体流的轨道，流和发送者之间的关系
  Map<String, Map<String, MediaStreamTrack>> tracks = {};
  Map<String, Map<String, RTCRtpSender>> trackSenders = {};

  //外部使用时注册的回调方法，也就是注册事件
  //WebrtcEvent定义了事件的名称
  Map<WebrtcEventType, Function> handlers = {};

  //signal扩展属性，由外部传入，这个属性用于传递定制的属性
  //一般包括自己的iceServer，room，peerId，clientId，name
  SignalExtension? extension;

  //建立连接的PeerConnection约束
  Map<String, dynamic> pcConstraints = {
    "mandatory": {},
    "optional": [
      //如果要与浏览器互通开启DtlsSrtpKeyAgreement,此处不开启
      {"DtlsSrtpKeyAgreement": true},
    ],
  };

  ///从协商开始计时，连接成功结束，计算连接的时间
  ///如果一直未结束，根据当前状态，可以进行重连操作
  ///对主动方来说，发出candidate和offer后一直未得到answer回应，重发candidate和offer
  ///对被动方来说，收到candidate但一直未收到offer，只能等待，或者发出answer一直未连接，重发answer
  int? start;
  int? end;

  int heartTimes = 3000; // 心跳间隔(毫秒)
  int reconnectTimes = 1;

  BasePeerConnection({required this.initiator}) {
    logger.i('Create initiator:$initiator BasePeerConnection');
  }

  ///初始化连接，可以传入外部视频流，这是异步的函数，不能在构造里调用
  ///建立连接对象，设置好回调函数，然后如果是master发起协商，如果是follow，在收到offer才开始创建，
  ///只有协商完成，数据通道打开，才算真正完成连接
  ///可输入的参数包括外部媒体流和定制扩展属性
  Future<bool> init(
      {required SignalExtension extension,
      List<MediaStream> localStreams = const []}) async {
    start = DateTime.now().millisecondsSinceEpoch;
    id = await cryptoGraphy.getRandomAsciiString(length: 8);
    this.extension = extension;
    try {
      var iceServers = extension.iceServers;
      var appDataProvider = AppDataProvider.instance;
      iceServers = iceServers ?? appDataProvider.defaultNodeAddress.iceServers;
      extension.iceServers = iceServers;
      var configuration = {'iceServers': iceServers};
      //1.创建连接
      this.peerConnection =
          await createPeerConnection(configuration, pcConstraints);
      //logger.i('Create PeerConnection peerConnection end:$id');
    } catch (err) {
      logger.e('createPeerConnection:$err');
      return false;
    }

    RTCPeerConnection peerConnection = this.peerConnection!;
    if (localStreams.isNotEmpty) {
      for (var localStream in localStreams) {
        await addStream(localStream);
      }
    }

    ///2.注册连接的事件监听器
    peerConnection.onIceConnectionState =
        (RTCIceConnectionState state) => {onIceConnectionState(state)};
    peerConnection.onIceGatheringState =
        (RTCIceGatheringState state) => {onIceGatheringState(state)};
    // peerConnection.onConnectionState =
    //     (RTCPeerConnectionState state) => {onConnectionState(state)};
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
      var dataChannelLabel =
          await cryptoGraphy.getRandomAsciiString(length: 20);
      dataChannel = await peerConnection.createDataChannel(
          dataChannelLabel, dataChannelDict);

      //建立数据通道的监听器
      peerConnection.onDataChannel = (RTCDataChannel dataChannel) => {
            dataChannel.onDataChannelState =
                (RTCDataChannelState state) => {onDataChannelState(state)},
            dataChannel.onMessage =
                (RTCDataChannelMessage message) => {onMessage(message)}
          };
      //logger.i('CreateDataChannel and onDataChannel end');
    }

    /// 4.建立连接的监听轨道到来的监听器，当远方由轨道来的时候执行
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
    status = PeerConnectionStatus.init;

    return true;
  }

  PeerConnectionStatus get status {
    return _status;
  }

  set status(PeerConnectionStatus status) {
    _status = status;
    emit(WebrtcEventType.status, {'oldStatus': _status, 'newStatus': status});
  }

  /// 重连方法
  Future<void> reconnect({List<MediaStream> localStreams = const []}) async {
    logger.i(
        'webrtc peerId:${extension!.peerId},clientId:${extension!.clientId} reconnecting');
    await close();
    await init(extension: extension!, localStreams: localStreams);
    status = PeerConnectionStatus.reconnecting;
    var peerConnection = this.peerConnection!;
    if (initiator) {
      peerConnection.setLocalDescription(localSdp!);
      peerConnection.setRemoteDescription(remoteSdp!);
      for (var candidate in remoteCandidates) {
        await addIceCandidate(candidate);
      }
    } else {}
  }

  void connected() {
    if (status == PeerConnectionStatus.connected) {
      logger.i('PeerConnectionStatus has already connected');
      return;
    }
    logger.i('PeerConnectionStatus connected, webrtc connection is completed');
    end = DateTime.now().millisecondsSinceEpoch;
    status = PeerConnectionStatus.connected;
    if (end != null && start != null) {
      var interval = end! - start!;
      logger.i('id:$id connected time:$interval');
    }
    emit(WebrtcEventType.connected, '');
  }

  ///连接状态事件
  onConnectionState(RTCPeerConnectionState state) {
    RTCPeerConnection peerConnection = this.peerConnection!;
    // logger.i(
    //     'connectionState:${peerConnection.connectionState},onConnectionState event:${state.name}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    emit(WebrtcEventType.connectionState, state);
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
      logger.e('Connection failed.');
      close();
    }
    if (peerConnection.connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      connected();
    }
  }

  ///ice连接状态事件
  onIceConnectionState(RTCIceConnectionState state) {
    RTCPeerConnection peerConnection = this.peerConnection!;
    // logger.i(
    //     'iceConnectionState:${peerConnection.iceConnectionState},onIceConnectionState event:${state.name}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }

    emit(WebrtcEventType.iceConnectionState, state);
    if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
        state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
      connected();
    }
    if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
        state == RTCIceConnectionState.RTCIceConnectionStateClosed ||
        state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
      logger.e('Ice connection failed.');
      close();
    }
  }

  onIceGatheringState(RTCIceGatheringState state) {
    RTCPeerConnection peerConnection = this.peerConnection!;
    //logger.i(
    //    'iceGatheringState:${peerConnection.iceGatheringState},onIceGatheringState event:$state');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    emit(WebrtcEventType.iceGatheringState, state);
  }

  /// signal状态事件
  onSignalingState(RTCSignalingState state) {
    RTCPeerConnection peerConnection = this.peerConnection!;
    // logger.i(
    //     'signalingState:${peerConnection.signalingState},onSignalingState event:$state');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    if (state == RTCSignalingState.RTCSignalingStateStable) {
      status = PeerConnectionStatus.negotiated;
    }
    emit(WebrtcEventType.signalingState, state);
  }

  ///onIceCandidate事件表示本地candidate准备好，可以发送IceCandidate到远端
  onIceCandidate(RTCIceCandidate candidate) {
    ///如果注册了iceCandidate事件，则直接执行事件
    var handler = handlers[WebrtcEventType.iceCandidate];
    if (handler != null) {
      handler(candidate);
      return;
    }

    localCandidates.add(candidate);
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    if (candidate.candidate != null) {
      //发送candidate信号
      //logger.i('Send Candidate signal.');
      emit(
          WebrtcEventType.signal,
          WebrtcSignal(SignalType.candidate.name,
              candidates: [candidate], extension: extension));
    }
  }

  onRenegotiationNeeded() {
    //logger.w('onRenegotiationNeeded event');
    //negotiate();
  }

  //数据通道状态事件
  onDataChannelState(RTCDataChannelState state) {
    logger.i('onDataChannelState event:$state');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    //数据通道打开
    if (state == RTCDataChannelState.RTCDataChannelOpen) {
      logger.i('data channel open');
      dataChannelOpen = true;
    }
    //数据通道关闭
    if (state == RTCDataChannelState.RTCDataChannelClosed) {
      logger.i('data channel close');
      close();
    }
  }

  /// 被叫方的数据传输事件
  /// webrtc的数据通道发来的消息可以是ChainMessage，
  /// 也可以是简单的非ChainMessage，比如最简单的文本或者复合文档，也就是ChatMessage
  onMessage(RTCDataChannelMessage message) {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    if (message.isBinary) {
      var data = message.binary;
      emit(WebrtcEventType.message, data);
    } else {
      logger.i('onMessage event:${message.text}');
      var data = message.text;
      emit(WebrtcEventType.message, data.codeUnits);
    }
  }

  ///被叫不能在第一次的时候主动发起协议过程，主叫或者被叫不在第一次的时候可以发起协商过程
  negotiate() async {
    if (initiator) {
      _negotiateOffer();
    } else {
      _negotiateAnswer();
    }
  }

  ///外部在收到信号的时候调用
  onSignal(WebrtcSignal webrtcSignal) async {
    if (initiator) {
      _onOfferSignal(webrtcSignal);
    } else {
      _onAnswerSignal(webrtcSignal);
    }
  }

  addTransceiver({
    required MediaStreamTrack track,
    required RTCRtpMediaType kind,
    required RTCRtpTransceiverInit init,
  }) {
    if (initiator) {
      _addOfferTransceiver(track: track, kind: kind, init: init);
    } else {
      _addAnswerTransceiver(track: track, kind: kind, init: init);
    }
  }

  ///作为主叫，发起协商过程createOffer
  _negotiateOffer() async {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    if (status == PeerConnectionStatus.negotiating) {
      logger.e('PeerConnectionStatus already negotiating');
      return;
    }
    logger.w('Start negotiate');
    status == PeerConnectionStatus.negotiating;
    await _createOffer();
  }

  ///作为主叫，创建offer，设置到本地会话描述，并发送offer
  _createOffer() async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var localDescription = await peerConnection.getLocalDescription();
    if (localDescription != null) {
      logger.w('LocalDescription sdp offer is exist:${localDescription.type}');
    }
    RTCSessionDescription offer =
        await peerConnection.createOffer(sdpConstraints);
    await peerConnection.setLocalDescription(offer);
    logger.i('createOffer and setLocalDescription offer successfully');
    localSdp = offer;
    await _sendOffer(offer);
  }

  ///作为主叫，调用外部方法发送offer
  _sendOffer(RTCSessionDescription offer) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }

    var sdp = await peerConnection.getLocalDescription();
    sdp ??= offer;
    emit(WebrtcEventType.signal,
        WebrtcSignal(SignalType.sdp.name, sdp: sdp, extension: extension));
    logger.i('end sendOffer');
  }

  ///作为主叫，从信号服务器传回来远程的webrtcSignal信息，从signalAction回调
  _onOfferSignal(WebrtcSignal webrtcSignal) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    String signalType = webrtcSignal.signalType;
    //logger.i('onSignal signalType:$signalType');
    var candidates = webrtcSignal.candidates;
    var sdp = webrtcSignal.sdp;
    //被要求重新协商，则发起协商
    if (signalType == SignalType.renegotiate.name &&
        webrtcSignal.renegotiate != null) {
      logger.i('onSignal renegotiate');
      negotiate();
    }
    //被要求收发，则加收发器
    else if (webrtcSignal.transceiverRequest != null) {
      logger.i('onSignal transceiver');
      // addTransceiver(
      //     kind: data.transceiverRequest.kind,
      //     init: data.transceiverRequest.init);
    }
    //如果是候选信息
    else if (signalType == SignalType.candidate.name && candidates != null) {
      //logger.i('onSignal candidate:${candidate.candidate}');
      remoteCandidates.addAll(candidates);
      logger.i('remoteCandidates length:${remoteCandidates.length}');
      for (var candidate in candidates) {
        await addIceCandidate(candidate);
      }
    }
    //如果sdp信息，则设置远程描述
    //对主叫节点来说，sdp应该是answer
    else if (signalType == SignalType.sdp.name && sdp != null) {
      if (sdp.type != 'answer') {
        logger.e('onSignal sdp type is not answer:${sdp.type}');
      }
      RTCSessionDescription? remoteDescription =
          await peerConnection.getRemoteDescription();
      if (remoteDescription != null) {
        logger.w('remoteDescription is exist');
      }
      remoteSdp = sdp;
      await peerConnection.setRemoteDescription(sdp);
    }
    //如果什么都不是，报错
    else {
      logger.e('signal called with invalid signal type');
    }
  }

  /// 作为主叫，为连接加上收发器
  /// @param {String} kind
  /// @param {Object} init
  _addOfferTransceiver({
    required MediaStreamTrack track,
    required RTCRtpMediaType kind,
    required RTCRtpTransceiverInit init,
  }) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    logger.i('addTransceiver');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }

    //直接加上收发器，并开始协商
    try {
      await peerConnection.addTransceiver(track: track, kind: kind, init: init);
      //negotiate();
    } catch (err) {
      logger.e(err);
      close();
    }
  }

  ///作为被叫，协商时发送再协商信号给主叫，要求重新发起协商
  _negotiateAnswer() async {
    logger.i('Negotiation start, requesting negotiation from slave');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    if (status == PeerConnectionStatus.negotiating) {
      logger.e('already negotiating');
      return;
    }
    if (status != PeerConnectionStatus.connected) {
      logger.e('answer renegotiate only connected');
      return;
    }
    //被叫发送重新协商的请求
    logger.w('send signal renegotiate');
    emit(WebrtcEventType.signal,
        WebrtcSignal('renegotiate', renegotiate: true, extension: extension));
    status == PeerConnectionStatus.negotiating;
  }

  ///作为被叫，创建answer，发生在被叫方，将answer回到主叫方
  _createAnswer() async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }

    logger.i('start createAnswer');
    RTCSessionDescription? answer = await peerConnection.getLocalDescription();
    if (answer != null) {
      logger.e('getLocalDescription local sdp answer is exist:${answer.type}');
    }
    answer = await peerConnection.createAnswer(sdpConstraints);
    logger.i('create local sdp answer:${answer.type}, and setLocalDescription');
    localSdp = answer;
    await peerConnection.setLocalDescription(answer);
    logger
        .i('setLocalDescription local sdp answer:${answer.type} successfully');
    await _sendAnswer(answer);
  }

  //作为被叫，发送answer
  _sendAnswer(RTCSessionDescription answer) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    logger.i('send signal local sdp answer:${answer.type}');
    var sdp = await peerConnection.getLocalDescription();
    sdp ??= answer;
    emit(WebrtcEventType.signal,
        WebrtcSignal(SignalType.sdp.name, sdp: sdp, extension: extension));
    logger.i('sendAnswer:${answer.type} successfully');
  }

  ///作为被叫，从信号服务器传回来远程的webrtcSignal信息，从signalAction回调
  _onAnswerSignal(WebrtcSignal webrtcSignal) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    status == PeerConnectionStatus.negotiating;
    String signalType = webrtcSignal.signalType;
    var candidates = webrtcSignal.candidates;
    var sdp = webrtcSignal.sdp;
    //如果是候选信息
    if (signalType == SignalType.candidate.name && candidates != null) {
      remoteCandidates.addAll(candidates);
      logger.i('remoteCandidates length:${remoteCandidates.length}');
      for (var candidate in candidates) {
        await addIceCandidate(candidate);
      }
    }
    //如果sdp信息，则设置远程描述
    else if (signalType == SignalType.sdp.name && sdp != null) {
      if (sdp.type != 'offer') {
        logger.e('onSignal sdp is not offer:${sdp.type}');
      }
      remoteSdp = sdp;
      logger.i('start setRemoteDescription sdp offer:${sdp.type}');
      RTCSessionDescription? remoteDescription =
          await peerConnection.getRemoteDescription();
      if (remoteDescription != null) {
        logger.w(
            'RemoteDescription sdp offer is exist:${remoteDescription.type}');
      }
      await peerConnection.setRemoteDescription(sdp);
      logger.i('setRemoteDescription sdp offer:${sdp.type} successfully');
      //如果远程描述是offer请求，则创建answer
      remoteDescription = await peerConnection.getRemoteDescription();
      if (remoteDescription != null && remoteDescription.type == 'offer') {
        await _createAnswer();
      } else {
        logger
            .e('RemoteDescription sdp is not offer:${remoteDescription!.type}');
      }
    }
    //如果什么都不是，报错
    else {
      logger.e('signal called with invalid signal data');
    }
  }

  /// 作为被叫，为连接加上收发器
  /// @param {String} kind
  /// @param {Object} init
  _addAnswerTransceiver({
    required MediaStreamTrack track,
    required RTCRtpMediaType kind,
    required RTCRtpTransceiverInit init,
  }) async {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    logger.i('addTransceiver()');

    emit(
        WebrtcEventType.signal,
        WebrtcSignal(SignalType.transceiverRequest.name,
            transceiverRequest: {'kind': kind, 'init': init},
            extension: extension));
  }

  ///增加本地流到本地集合
  bool _addStream(MediaStream stream) {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return false;
    }
    var id = stream.id;
    if (streams.containsKey(id)) {
      return false;
    }
    streams[id] = stream;
    logger.i('BasePeerConnection _addStream:$id');
    var tracks = stream.getTracks();
    for (var track in tracks) {
      _addTrack(stream, track);
    }
    return true;
  }

  ///主动创建新的MediaStream，从连接中增加本地流，只能在init方法中调用
  Future<bool> addStream(MediaStream stream) async {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return false;
    }
    try {
      bool success = _addStream(stream);
      if (success) {
        RTCPeerConnection peerConnection = this.peerConnection!;
        await peerConnection.addStream(stream);
        logger.i('_addLocalStream ${stream.id}');
        return true;
      }
    } catch (e) {
      logger.e('peer connection addStream failure, $e');
    }

    ///以下是另一种做法
    // var tracks = stream.getTracks();
    // for (var track in tracks) {
    //   _addLocalTrack(stream, track);
    // }

    return false;
  }

  /// 把轨道加入到流中，其目的是为了把加入远程流的本地集合，连接没有操作
  /// @param {MediaStreamTrack} track
  /// @param {MediaStream} stream
  _addTrack(MediaStream stream, MediaStreamTrack track) {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    String streamId = stream.id;
    String? trackId = track.id;
    if (trackId == null) {
      logger.e('stream:$streamId, track:$trackId is null');
      return;
    }
    if (!streams.containsKey(streamId)) {
      streams[streamId] = stream;
    }
    var streamTracks = tracks[streamId];
    if (streamTracks == null) {
      streamTracks = {};
      tracks[streamId] = streamTracks;
    }
    streamTracks[trackId] = track;
    logger.i('_addTrack stream:${stream.id}, track:${track.id}');
  }

  /// 把轨道加入到流中，其目的是为了把本地流轨道加入本地集合，只能通过init方法调用_addStream方法，再调用本方法
  /// @param {MediaStreamTrack} track
  /// @param {MediaStream} stream
  addTrack(MediaStream stream, MediaStreamTrack track) async {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    logger.i('addTrack stream:${stream.id}, track:${track.id}');
    String streamId = stream.id;
    String? trackId = track.id;
    _addTrack(stream, track);

    RTCPeerConnection peerConnection = this.peerConnection!;
    var streamSenders = trackSenders[trackId!];
    if (streamSenders == null) {
      streamSenders = {};
      trackSenders[trackId] = streamSenders;
    }
    try {
      var streamSender = await peerConnection.addTrack(track, stream);
      streamSenders[streamId] = streamSender;
    } catch (e) {
      logger.e('peer connection addTrack failure, $e');
    }
  }

  /// 主动在连接中用一个轨道取代另一个轨道
  /// @param {MediaStreamTrack} oldTrack
  /// @param {MediaStreamTrack} newTrack
  /// @param {MediaStream} stream
  replaceTrack(MediaStream stream, MediaStreamTrack oldTrack,
      MediaStreamTrack newTrack) async {
    logger.i(
        'replaceTrack stream:${stream.id}, oldTrack:${oldTrack.id}, newTrack:${newTrack.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var streamId = stream.id;
    var oldTrackId = oldTrack.id;
    var newTrackId = newTrack.id;

    var streamTracks = tracks[streamId];
    if (streamTracks == null) {
      streamTracks = {};
      tracks[streamId] = streamTracks;
    }
    streamTracks.remove(oldTrackId);
    streamTracks[newTrackId!] = newTrack;

    var streamSenders = trackSenders[oldTrackId];
    if (streamSenders != null) {
      RTCRtpSender? sender = streamSenders[streamId];
      if (sender == null) {
        logger.e('Cannot replace track that was never added.');
      } else {
        trackSenders[newTrackId!] = streamSenders;
        await sender.replaceTrack(newTrack);
      }
    }
  }

  _removeTrack(MediaStream stream, MediaStreamTrack track) async {
    logger.i('_removeTrack stream:${stream.id}, track:${track.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var streamId = stream.id;
    var trackId = track.id;

    var streamTracks = tracks[streamId];
    if (streamTracks == null) {
      streamTracks = {};
      tracks[streamId] = streamTracks;
    }
    streamTracks.remove(trackId);
    if (streamTracks.isEmpty) {
      tracks.remove(streamId);
    }
  }

  /// 主动从连接中移除一个轨道，然后会激活onRemoveTrack
  /// @param {MediaStreamTrack} track
  /// @param {MediaStream} stream
  removeTrack(MediaStream stream, MediaStreamTrack track) async {
    logger.i('removeTrack stream:${stream.id}, track:${track.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var streamId = stream.id;
    var trackId = track.id;

    var streamSenders = trackSenders[trackId];
    if (streamSenders != null) {
      RTCRtpSender? sender = streamSenders[streamId];
      if (sender == null) {
        logger.e('Cannot remove track that was never added.');
      } else {
        try {
          RTCPeerConnection? peerConnection = this.peerConnection;
          if (peerConnection != null) {
            await peerConnection.removeTrack(sender);
          }
          _removeTrack(stream, track);
        } catch (err) {
          logger.e('removeTrack err $err');
          close();
        }
      }
    }
  }

  /// 主动从连接中移除流，然后会激活onRemoveStream
  /// @param {MediaStream} stream
  _removeStream(MediaStream stream) async {
    logger.i('removeStream stream:${stream.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var id = stream.id;
    if (streams.containsKey(id)) {
      RTCPeerConnection? peerConnection = this.peerConnection;
      if (peerConnection != null) {
        await peerConnection.removeStream(stream);
      }
      var tracks = stream.getTracks();
      for (var track in tracks) {
        removeTrack(stream, track);
      }
    }
  }

  /// 主动从连接中移除流，然后会激活onRemoveStream
  /// @param {MediaStream} stream
  removeStream(MediaStream stream) async {
    logger.i('removeStream stream:${stream.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var id = stream.id;
    if (streams.containsKey(id)) {
      RTCPeerConnection? peerConnection = this.peerConnection;
      if (peerConnection != null) {
        await peerConnection.removeStream(stream);
      }
      _removeStream(stream);
    }
  }

  ///对远端的连接来说，当有stream或者track到来时触发
  ///什么都不做，由onAddTrack事件处理
  onAddStream(MediaStream stream) {
    logger.i('onAddStream stream:${stream.id}');
    _addStream(stream);
    emit(WebrtcEventType.stream, stream);
  }

  onRemoveStream(MediaStream stream) {
    logger.i('onRemoveStream stream:${stream.id}');
    _removeStream(stream);
    emit(WebrtcEventType.removeStream, stream);
  }

  ///对远端的连接来说，当有stream或者track到来时触发
  onAddTrack(MediaStream stream, MediaStreamTrack track) {
    logger.i('onAddTrack stream:${stream.id}, track:${track.id}');
    _addTrack(stream, track);
    emit(WebrtcEventType.addTrack, {'stream': stream, 'track': track});
  }

  onRemoveTrack(MediaStream stream, MediaStreamTrack track) {
    logger.i('onRemoveTrack stream:${stream.id}, track:${track.id}');
    _removeTrack(stream, track);
    emit(WebrtcEventType.removeTrack, {'stream': stream, 'track': track});
  }

  ///连接的监听轨道到来的监听器，当远方由轨道来的时候执行
  onTrack(RTCTrackEvent event) {
    logger.i('onTrack event');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }

    for (var eventStream in event.streams) {
      logger.i('onTrack event stream:${eventStream.id}');
      onAddStream(eventStream);
      emit(WebrtcEventType.stream, eventStream);
    }
    emit(WebrtcEventType.track, event);
  }

  /// 注册一组回调函数，内部可以调用外部注册事件的方法
  /// name包括'signal','stream','track'
  /// 内部通过调用emit方法调用外部注册的方法
  /// 所有basePeerConnection的事件都缺省转发到peerConnectionPool相同的处理
  /// 所以调用此方法会覆盖peerConnectionPool的处理
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
    var map = iceCandidate.toMap();
    var jsonStr = JsonUtil.toJsonString(map);
    logger.i('addIceCandidate: $jsonStr');
  }

  /// 发送二进制消息 text/binary data to the remote peer.
  Future<void> send(List<int> message) async {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed, cannot send');
      return;
    }
    final dataChannel = this.dataChannel;
    if (dataChannel != null) {
      var dataChannelMessage =
          RTCDataChannelMessage.fromBinary(Uint8List.fromList(message));
      return await dataChannel.send(dataChannelMessage);
    }
  }

  ///关闭连接
  close() async {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    streams = {};
    //trackSenders = {};
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
        await peerConnection.close();
        this.peerConnection = null;
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
    status = PeerConnectionStatus.closed;
    logger.i('PeerConnectionStatus closed');

    // if (reconnectTimes > 0) {
    //   reconnect();
    // }
    emit(WebrtcEventType.closed, '');
  }
}
