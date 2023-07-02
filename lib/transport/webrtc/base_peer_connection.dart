import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/entity/chat/conference.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/message_slice.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalExtension {
  late String peerId;
  late String clientId;
  late String name;
  Conference? conference;
  List<Map<String, String>>? iceServers;

  SignalExtension(this.peerId, this.clientId,
      {required this.name, this.conference, this.iceServers});

  SignalExtension.fromJson(Map json) {
    peerId = json['peerId'];
    clientId = json['clientId'];
    name = json['name'];
    Map<String, dynamic>? conference = json['conference'];
    if (conference != null) {
      this.conference = Conference(
        conference['conferenceId'],
        name: conference['name'],
        conferenceOwnerPeerId: conference['conferenceOwnerPeerId'],
      );
    }
    var iceServers = json['iceServers'];
    if (iceServers != null) {
      if (iceServers is List && iceServers.isNotEmpty) {
        this.iceServers = convertIceServers(iceServers);
      }
    }
  }

  static List<Map<String, String>> convertIceServers(List<dynamic> iceServers) {
    List<Map<String, String>> iss = [];
    if (iceServers.isNotEmpty) {
      for (var iceServer in iceServers) {
        for (var entry in (iceServer as Map).entries) {
          iss.add({entry.key: entry.value});
        }
      }
    }
    return iss;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'peerId': peerId,
      'clientId': clientId,
      'name': name,
      'iceServers': iceServers,
    });
    var conference = this.conference;
    if (conference != null) {
      json['conference'] = conference.toJson();
    }
    return json;
  }
}

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

class WebrtcEvent {
  String peerId;
  String clientId;
  String name;
  WebrtcEventType eventType;
  dynamic data;

  WebrtcEvent(this.peerId,
      {required this.clientId,
      required this.name,
      required this.eventType,
      this.data});
}

const String unknownClientId = 'unknownClientId';
const String unknownName = 'unknownName';

enum SignalType {
  renegotiate,
  transceiverRequest,
  candidate,
  sdp,
  offer,
  answer,
  error,
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
  String? error;

  WebrtcSignal(this.signalType,
      {this.renegotiate,
      this.transceiverRequest,
      this.candidates,
      this.sdp,
      this.extension,
      this.error});

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
    error = json['error'];
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
    var error = this.error;
    if (error != null) {
      json['error'] = error;
    }

    return json;
  }
}

//sdp约束
final Map<String, dynamic> sdpConstraints = {
  "mandatory": {
    //接收语音数据
    "OfferToReceiveAudio": true,
    //接收视频数据
    "OfferToReceiveVideo": true,
  },
  "optional": [],
};

enum NegotiateStatus {
  none,
  negotiating, //协商过程中
  negotiated,
}

enum PeerConnectionStatus {
  none,
  created,
  init,
  reconnecting,
  failed,
  connected, //连接是否完全建立，即协商过程结束
  closed, //是否关闭连接完成
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
  NegotiateStatus _negotiateStatus = NegotiateStatus.none;
  bool renegotiate = false;

  //数据通道的状态是否打开
  bool dataChannelOpen = false;

  //主动发送数据的通道
  RTCDataChannel? dataChannel;

  //是否需要主动建立数据通道
  bool needDataChannel = true;

  //媒体流的轨道，流和发送者之间的关系
  //Map<String, Map<String, MediaStreamTrack>> tracks = {};
  Map<String, Map<String, RTCRtpSender>> trackSenders = {};

  //外部使用时注册的回调方法，也就是注册事件
  //WebrtcEvent定义了事件的名称
  Map<WebrtcEventType, Function> events = {};

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

  int delayTimes = 20;
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
    try {
      if (extension.iceServers == null) {
        if (peerEndpointController.defaultPeerEndpoint != null) {
          var iceServers = JsonUtil.toJson(
              peerEndpointController.defaultPeerEndpoint!.iceServers);
          if (iceServers != null &&
              iceServers is List &&
              iceServers.isNotEmpty) {
            extension.iceServers =
                SignalExtension.convertIceServers(iceServers);
          }
        }
      }
      this.extension = extension;
      var configuration = {
        ///plan-b格式是老的格式，将会淘汰
        "sdpSemantics": "plan-b",
        //"sdpSemantics": "unified-plan",
        'iceServers': extension.iceServers
      };
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
        await addLocalStream(localStream);
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
      //建立数据通道的监听器
      if (initiator) {
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

        dataChannel!.onDataChannelState =
            (RTCDataChannelState state) => {onDataChannelState(state)};
        dataChannel!.onMessage =
            (RTCDataChannelMessage message) => {onMessage(message)};
        logger.i('peerConnection createDataChannel end');
      } else {
        peerConnection.onDataChannel = (RTCDataChannel dataChannel) {
          this.dataChannel = dataChannel;
          dataChannel.onDataChannelState =
              (RTCDataChannelState state) => {onDataChannelState(state)};
          dataChannel.onMessage =
              (RTCDataChannelMessage message) => {onMessage(message)};
        };
        logger.i('peerConnection set onDataChannel end');
      }
    }

    /// 4.建立连接的监听轨道到来的监听器，当远方由轨道来的时候执行
    peerConnection.onAddStream = (MediaStream stream) {
      onAddRemoteStream(stream);
    };
    peerConnection.onRemoveStream = (MediaStream stream) {
      onRemoveRemoteStream(stream);
    };
    peerConnection.onAddTrack = (MediaStream stream, MediaStreamTrack track) {
      onAddRemoteTrack(stream, track);
    };
    peerConnection.onRemoveTrack =
        (MediaStream stream, MediaStreamTrack track) {
      onRemoveRemoteTrack(stream, track);
    };
    peerConnection.onTrack = (RTCTrackEvent event) {
      onRemoteTrack(event);
    };
    status = PeerConnectionStatus.init;

    return true;
  }

  PeerConnectionStatus get status {
    return _status;
  }

  set status(PeerConnectionStatus status) {
    if (_status != status) {
      _status = status;
      emit(WebrtcEventType.status, status);
    }
  }

  NegotiateStatus get negotiateStatus {
    return _negotiateStatus;
  }

  set negotiateStatus(NegotiateStatus negotiateStatus) {
    logger.i(
        'negotiateStatus from oldStatus: $_negotiateStatus, newStatus: $negotiateStatus');
    _negotiateStatus = negotiateStatus;
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
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    emit(WebrtcEventType.iceGatheringState, state);
  }

  /// signal状态事件
  onSignalingState(RTCSignalingState state) {
    RTCPeerConnection peerConnection = this.peerConnection!;
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    if (state == RTCSignalingState.RTCSignalingStateStable) {
      negotiateStatus = NegotiateStatus.negotiated;
      if (renegotiate) {
        renegotiate = false;
        negotiate();
      }
    }
    emit(WebrtcEventType.signalingState, state);
  }

  ///onIceCandidate事件表示本地candidate准备好，可以发送IceCandidate到远端
  onIceCandidate(RTCIceCandidate candidate) {
    ///如果注册了iceCandidate事件，则直接执行事件
    var handler = events[WebrtcEventType.iceCandidate];
    if (handler != null) {
      handler(candidate);
      return;
    }

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
    logger.w('onRenegotiationNeeded event');
    negotiate();
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

  ///被叫不能在第一次的时候主动发起协议过程，主叫或者被叫不在第一次的时候可以发起协商过程
  negotiate() async {
    if (initiator) {
      await _negotiateOffer();
    } else {
      await _negotiateAnswer();
    }

    //延时关闭
    Future.delayed(Duration(seconds: delayTimes)).then((value) {
      if (status != PeerConnectionStatus.connected) {
        logger.w('delayed $delayTimes second cannot connected, will be closed');
        close();
        if (reconnectTimes > 0) {
          reconnectTimes--;
          negotiate();
        }
      }
    });
  }

  ///作为主叫，发起协商过程createOffer
  _negotiateOffer() async {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    if (negotiateStatus == NegotiateStatus.negotiating) {
      logger.e('PeerConnectionStatus already negotiating');
      renegotiate = true;
      return;
    }
    logger.w('Start negotiate');
    negotiateStatus = NegotiateStatus.negotiating;
    await _createOffer();
  }

  ///作为主叫，创建offer，设置到本地会话描述，并发送offer
  _createOffer() async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    RTCSessionDescription? localDescription;
    try {
      localDescription = await peerConnection.getLocalDescription();
    } catch (e) {
      logger.e('peerConnection getLocalDescription failure:$e');
    }
    if (localDescription != null) {
      logger.w('LocalDescription sdp offer is exist:${localDescription.type}');
    }
    try {
      RTCSessionDescription offer =
          await peerConnection.createOffer(sdpConstraints);
      await peerConnection.setLocalDescription(offer);
      logger.i('createOffer and setLocalDescription offer successfully');
      await _sendOffer(offer);
    } catch (e) {
      logger.e('createOffer,setLocalDescription and sendOffer failure:$e');
    }
  }

  ///作为主叫，调用外部方法发送offer
  _sendOffer(RTCSessionDescription offer) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }

    RTCSessionDescription? sdp;
    try {
      sdp = await peerConnection.getLocalDescription();
    } catch (e) {
      logger.e('peerConnection getLocalDescription failure:$e');
    }
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
      await negotiate();
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
      RTCSessionDescription? remoteDescription;
      try {
        remoteDescription = await peerConnection.getRemoteDescription();
      } catch (e) {
        logger.e('peerConnection getRemoteDescription failure:$e');
      }
      if (remoteDescription != null) {
        logger.w('remoteDescription is exist');
      }
      try {
        await peerConnection.setRemoteDescription(sdp);
      } catch (e) {
        logger.e('setRemoteDescription failure:$e');
      }
    } else if (signalType == SignalType.error.name) {
      logger.e('received error signal:${webrtcSignal.error}');
    }
    //如果什么都不是，报错
    else {
      logger.e('signal called with invalid signal type');
    }
  }

  ///作为被叫，协商时发送再协商信号给主叫，要求重新发起协商
  _negotiateAnswer() async {
    logger.i('Negotiation start, requesting negotiation from slave');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    if (negotiateStatus == NegotiateStatus.negotiating) {
      logger.e('already negotiating');
      renegotiate = true;
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
    negotiateStatus = NegotiateStatus.negotiating;
  }

  ///作为被叫，创建answer，发生在被叫方，将answer回到主叫方
  _createAnswer() async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }

    logger.i('start createAnswer');
    RTCSessionDescription? answer;
    try {
      answer = await peerConnection.getLocalDescription();
    } catch (e) {
      logger.e('peerConnection getLocalDescription failure:$e');
    }
    if (answer != null) {
      logger.w('getLocalDescription local sdp answer is exist:${answer.type}');
    }
    try {
      answer = await peerConnection.createAnswer(sdpConstraints);
    } catch (e) {
      logger.e('peerConnection createAnswer: $e');
      answer = null;
    }
    if (answer != null) {
      logger
          .i('create local sdp answer:${answer.type}, and setLocalDescription');
      try {
        await peerConnection.setLocalDescription(answer);
        logger.i(
            'setLocalDescription local sdp answer:${answer.type} successfully');
      } catch (e) {
        logger.e('createAnswer failure:$e');
      }
      await _sendAnswer(answer);
    }
  }

  //作为被叫，发送answer
  _sendAnswer(RTCSessionDescription answer) async {
    RTCPeerConnection peerConnection = this.peerConnection!;
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    logger.i('send signal local sdp answer:${answer.type}');
    RTCSessionDescription? sdp;
    try {
      sdp = await peerConnection.getLocalDescription();
    } catch (e) {
      logger.e('peerConnection getLocalDescription failure:$e');
    }
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
    negotiateStatus = NegotiateStatus.negotiating;
    String signalType = webrtcSignal.signalType;
    var candidates = webrtcSignal.candidates;
    var sdp = webrtcSignal.sdp;
    //如果是候选信息
    if (signalType == SignalType.candidate.name && candidates != null) {
      for (var candidate in candidates) {
        await addIceCandidate(candidate);
      }
    }
    //如果sdp信息，则设置远程描述
    else if (signalType == SignalType.sdp.name && sdp != null) {
      if (sdp.type != 'offer') {
        logger.e('onSignal sdp is not offer:${sdp.type}');
      }
      logger.i('start setRemoteDescription sdp offer:${sdp.type}');
      RTCSessionDescription? remoteDescription;
      try {
        remoteDescription = await peerConnection.getRemoteDescription();
      } catch (e) {
        logger.e('peerConnection getRemoteDescription failure:$e');
      }
      if (remoteDescription != null) {
        logger.w(
            'RemoteDescription sdp offer is exist:${remoteDescription.type}');
      }
      try {
        await peerConnection.setRemoteDescription(sdp);
      } catch (e) {
        logger.e('peerConnection setRemoteDescription failure:$e');
      }
      logger.i('setRemoteDescription sdp offer:${sdp.type} successfully');
      try {
        //如果远程描述是offer请求，则创建answer
        remoteDescription = await peerConnection.getRemoteDescription();
      } catch (e) {
        logger.e('peerConnection getRemoteDescription failure:$e');
        remoteDescription = null;
      }
      if (remoteDescription != null && remoteDescription.type == 'offer') {
        await _createAnswer();
      } else {
        logger
            .e('RemoteDescription sdp is not offer:${remoteDescription!.type}');
      }
    } else if (signalType == SignalType.error.name) {
      logger.e('received error signal:${webrtcSignal.error}');
    }
    //如果什么都不是，报错
    else {
      logger.e('signal called with invalid signal data');
    }
  }

  ///外部在收到信号的时候调用
  onSignal(WebrtcSignal webrtcSignal) async {
    if (initiator) {
      await _onOfferSignal(webrtcSignal);
    } else {
      await _onAnswerSignal(webrtcSignal);
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

  ///增加本地流到到连接中
  Future<bool> addLocalStream(MediaStream stream) async {
    logger.i('addLocalStream ${stream.id} ${stream.ownerTag}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return false;
    }
    // try {
    //   RTCPeerConnection peerConnection = this.peerConnection!;
    //   await peerConnection.addStream(stream);
    //   return true;
    // } catch (e) {
    //   logger.e('peer connection addLocalStream failure, $e');
    // }

    ///以下是推荐的做法
    var tracks = stream.getTracks();
    for (var track in tracks) {
      addLocalTrack(stream, track);
    }

    return false;
  }

  /// 把本地流轨道加入到连接中
  addLocalTrack(MediaStream stream, MediaStreamTrack track) async {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    logger.i(
        'addLocalTrack stream:${stream.id} ${stream.ownerTag}, track:${track.id}');
    String streamId = stream.id;
    String? trackId = track.id;

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

  ///判断本地流是否存在
  bool existLocal(MediaStream stream) {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return false;
    }
    RTCPeerConnection? peerConnection = this.peerConnection;
    if (peerConnection == null) {
      logger.e('PeerConnection is not exist');
      return false;
    }
    try {
      List<MediaStream?> streams = peerConnection.getLocalStreams();
      if (streams.isNotEmpty) {
        for (var s in streams) {
          if (s != null && s.id == stream.id) {
            logger.i('stream ${stream.id} is local');
            return true;
          }
        }
      }
    } catch (e) {
      logger.e('peer connection getLocalStreams failure, $e');
    }
    return false;
  }

  ///判断远程流是否存在
  bool existRemote(MediaStream stream) {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return false;
    }
    RTCPeerConnection? peerConnection = this.peerConnection;
    if (peerConnection == null) {
      logger.e('PeerConnection is not exist');
      return false;
    }
    try {
      List<MediaStream?> streams = peerConnection.getRemoteStreams();
      if (streams.isNotEmpty) {
        for (var s in streams) {
          if (s != null && s.id == stream.id) {
            logger.i('stream ${stream.id} is remote');
            return true;
          }
        }
      }
    } catch (e) {
      logger.e('peer connection getRemoteStreams failure, $e');
    }
    return false;
  }

  /// 主动从连接中移除流，然后会激活onRemoveStream
  removeStream(MediaStream stream) async {
    logger.i('removeStream stream:${stream.id} ${stream.ownerTag}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    RTCPeerConnection? peerConnection = this.peerConnection;
    if (peerConnection != null) {
      existLocal(stream);
      // try {
      //   await peerConnection.removeStream(stream);
      // } catch (e) {
      //   logger.e('peer connection removeStream failure, $e');
      // }

      var tracks = stream.getTracks();
      for (var track in tracks) {
        removeTrack(stream, track);
      }
    }
  }

  /// 主动从连接中移除一个轨道，然后会激活onRemoveTrack
  removeTrack(MediaStream stream, MediaStreamTrack track) async {
    logger.i(
        'removeTrack stream:${stream.id} ${stream.ownerTag}, track:${track.id}');
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
        } catch (err) {
          logger.e('removeTrack err $err');
          close();
        }
      }
    }
  }

  ///克隆远程流，可用于转发
  Future<MediaStream?> cloneStream(MediaStream stream) async {
    logger.i('removeStream stream:${stream.id} ${stream.ownerTag}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return null;
    }
    RTCPeerConnection? peerConnection = this.peerConnection;
    if (peerConnection != null) {
      try {
        existRemote(stream);
        try {
          List<MediaStream?> streams = peerConnection.getRemoteStreams();
          if (streams.isNotEmpty) {
            for (var s in streams) {
              if (s != null && s.id == stream.id) {
                MediaStream cloneStream = await s.clone();
                return cloneStream;
              }
            }
          }
        } catch (e) {
          logger.e('peer connection getRemoteStreams failure, $e');
        }
      } catch (e) {
        logger.e('peer connection stream clone failure, $e');
      }
    }
    return null;
  }

  /// 主动在连接中用一个轨道取代另一个轨道
  replaceTrack(MediaStream stream, MediaStreamTrack oldTrack,
      MediaStreamTrack newTrack) async {
    logger.i(
        'replaceTrack stream:${stream.id} ${stream.ownerTag}, oldTrack:${oldTrack.id}, newTrack:${newTrack.id}');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }
    var streamId = stream.id;
    var oldTrackId = oldTrack.id;
    var newTrackId = newTrack.id;

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

  ///对远端的连接来说，当有stream或者track到来时触发
  ///什么都不做，由onAddTrack事件处理
  onAddRemoteStream(MediaStream stream) {
    logger.i('onAddRemoteStream stream:${stream.id} ${stream.ownerTag}');
    emit(WebrtcEventType.stream, stream);
  }

  onRemoveRemoteStream(MediaStream stream) {
    logger.i('onRemoveRemoteStream stream:${stream.id} ${stream.ownerTag}');
    emit(WebrtcEventType.removeStream, stream);
  }

  ///对远端的连接来说，当有stream或者track到来时触发
  onAddRemoteTrack(MediaStream stream, MediaStreamTrack track) {
    logger.i(
        'onAddRemoteTrack stream:${stream.id} ${stream.ownerTag}, track:${track.id}');
    emit(WebrtcEventType.addTrack, {'stream': stream, 'track': track});
  }

  onRemoveRemoteTrack(MediaStream stream, MediaStreamTrack track) {
    logger.i(
        'onRemoveRemoteTrack stream:${stream.id} ${stream.ownerTag}, track:${track.id}');
    emit(WebrtcEventType.removeTrack, {'stream': stream, 'track': track});
  }

  ///连接的监听轨道到来的监听器，当远方由轨道来的时候执行
  onRemoteTrack(RTCTrackEvent event) {
    logger.i('onRemoteTrack event');
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed');
      return;
    }

    for (var eventStream in event.streams) {
      logger.i('onRemoteTrack event stream:${eventStream.id}');
      onAddRemoteStream(eventStream);
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
      events[name] = fn;
    } else {
      events.remove(name);
    }
  }

  /// 调用外部事件注册方法
  emit(WebrtcEventType name, dynamic webrtcEvent) {
    var event = events[name];
    if (event != null) {
      event(webrtcEvent);
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

  ///消息分片处理器
  MessageSlice messageSlice = MessageSlice();

  /// 发送二进制消息 text/binary data to the remote peer.
  Future<bool> send(List<int> message) async {
    Map<int, List<int>> slices = messageSlice.slice(message);
    bool success = false;
    for (var slice in slices.values) {
      success = await _send(slice);
      if (!success) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _send(List<int> message) async {
    if (status == PeerConnectionStatus.closed) {
      logger.e('PeerConnectionStatus closed, cannot send');
      return false;
    }
    logger.i('webrtc send message length: ${message.length}');
    final dataChannel = this.dataChannel;
    if (dataChannel != null) {
      var dataChannelMessage =
          RTCDataChannelMessage.fromBinary(Uint8List.fromList(message));
      await dataChannel.send(dataChannelMessage);
      return true;
    }
    return false;
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
      List<int>? slices = messageSlice.merge(data);

      if (slices != null) {
        logger.i('webrtc binary onMessage length: ${slices.length}');
        emit(WebrtcEventType.message, slices);
      }
    } else {
      var data = message.text.codeUnits;
      List<int>? slices = messageSlice.merge(data);

      if (slices != null) {
        logger.i('webrtc text onMessage length: ${slices.length}');
        emit(WebrtcEventType.message, slices);
      }
    }
  }

  ///关闭连接
  close() async {
    if (status == PeerConnectionStatus.closed) {
      logger.w('PeerConnectionStatus closed');
      return;
    }
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
    negotiateStatus = NegotiateStatus.none;
    logger.i('PeerConnectionStatus closed');

    // if (reconnectTimes > 0) {
    //   reconnect();
    // }
    emit(WebrtcEventType.closed, this);
  }
}
