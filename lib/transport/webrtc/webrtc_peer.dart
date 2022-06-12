import 'dart:typed_data';

import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/transport/webrtc/webrtc_core_peer.dart';
import 'package:colla_chat/transport/webrtc/webrtcpeerpool.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../provider/app_data.dart';

class SignalExtension {
  String? peerId;
  String? clientId;
  Router? router;
  List<Map<String, String>>? iceServers;

  SignalExtension(this.peerId, this.clientId, {this.router, this.iceServers});

  SignalExtension.fromJson(Map json) {
    peerId = json['peerId'];
    clientId = json['clientId'];
    Map<String, dynamic> router = json['router'];
    this.router = Router(router['roomId'],
        id: router['id'],
        type: router['type'],
        action: router['action'],
        identity: router['identity']);
    iceServers = json['iceServers'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'peerId': peerId,
      'clientId': clientId,
      'iceServers': iceServers,
    });
    var router = this.router;
    if (router != null) {
      json['router'] = router.toJson();
    }
    return json;
  }
}

///核心的Peer之上加入了业务的编号，peerId和clientId
class WebrtcPeer {
  late WebrtcCorePeer webrtcCorePeer;
  String? targetPeerId;
  String? clientId;
  String? peerId;
  String? connectPeerId;
  String? connectSessionId;
  List<Map<String, String>>? iceServers = [];
  List<MediaStream> localStreams = [];
  List<MediaStream> remoteStreams = [];
  Router? router;
  int? start;
  int? end;

//    初始化一个WebrtcCorePeer的配置参数
//     {
//		initiator: false,//是否是发起节点
//		channelConfig: {},
//		channelName: '<random string>',
//		config: { iceServers: [{ urls: 'stun:stun.l.google.com:19302' }, { urls: 'stun:global.stun.twilio.com:3478?transport=udp' }] },
//		offerOptions: {},
//		answerOptions: {},
//		sdpTransform: function (sdp) { return sdp },
//		stream: false,
//		streams: [],
//		trickle: true,
//		allowHalfTrickle: false,
//		wrtc: {}, // RTCPeerConnection/RTCSessionDescription/RTCIceCandidate
//		objectMode: false
//	}

  WebrtcPeer(String targetPeerId, String clientId, bool initiator,
      {List<MediaStream> streams = const [],
      List<Map<String, String>>? iceServers,
      Router? router}) {
    init(targetPeerId, clientId, initiator,
        iceServers: iceServers, router: router);
  }

  init(String targetPeerId, String clientId, bool initiator,
      {List<MediaStream> streams = const [],
      List<Map<String, String>>? iceServers,
      Router? router}) async {
    this.targetPeerId = targetPeerId;
    this.clientId = clientId;
    this.router = router;
    var appDataProvider = AppDataProvider.instance;
    if (iceServers == null) {
      this.iceServers = appDataProvider.defaultNodeAddress.iceServers;
    } else {
      this.iceServers = iceServers;
    }
    if (streams != null) {
      localStreams.addAll(streams);
    }
    // 自定义属性，表示本节点createOffer时加入的sfu的编号，作为出版者还是订阅者，还是都是
    this.router = router;
    start = DateTime.now().millisecondsSinceEpoch;
    SignalExtension extension = SignalExtension(myself.peerId, myself.clientId,
        router: router, iceServers: iceServers);
    if (initiator) {
      webrtcCorePeer = MasterWebrtcCorePeer();
      final webrtcPeer = this.webrtcCorePeer;
      if (webrtcPeer != null) {
        await webrtcPeer.init(streams: streams, extension: extension);
      }
    } else {
      this.webrtcCorePeer = FollowWebrtcCorePeer();
      final webrtcPeer = this.webrtcCorePeer;
      if (webrtcPeer != null) {
        await webrtcPeer.init(streams: streams, extension: extension);
      }
    }
    //下面的三个事件对于发起方和被发起方是一样的
    //可以发起信号
    final webrtcPeer = this.webrtcCorePeer;
    webrtcPeer.on(WebrtcEvent.signal, (WebrtcSignal signal) async {
      await webrtcPeerPool
          .emit(WebrtcEvent.signal.name, {'data': signal, 'source': this});
    });

    //连接建立/
    webrtcPeer.on(WebrtcEvent.connect, (data) async {
      end = DateTime.now().millisecondsSinceEpoch;
      if (end != null && start != null) {
        var interval = end! - start!;
        logger.i('connect time:$interval');
      }
      await webrtcPeerPool.emit(WebrtcEvent.connect.name, {'source': this});
    });

    webrtcPeer.on(WebrtcEvent.close, (data) async {
      if (this.targetPeerId != null) {
        await webrtcPeerPool.remove(this.targetPeerId!);
      }
    });

    //收到数据
    webrtcPeer.on(WebrtcEvent.data, (data) async {
      logger.i('${DateTime.now().toUtc()}:got a message from peer: $data');
      await webrtcPeerPool
          .emit(WebrtcEvent.data.name, {'data': data, 'source': this});
    });

    webrtcPeer.on(WebrtcEvent.stream, (stream) async {
      remoteStreams.add(stream);
      if (stream != null) {
        stream.onremovetrack = (event) {
          logger.i('Video track: ${event.track.label} removed');
        };
      }
      await webrtcPeerPool
          .emit(WebrtcEvent.stream.name, {'stream': stream, 'source': this});
    });

    webrtcPeer.on(WebrtcEvent.track, (track, stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:track');
      await webrtcPeerPool.emit(WebrtcEvent.track.name,
          {'track': track, 'stream': stream, 'source': this});
    });

    webrtcPeer.on(
        WebrtcEvent.error, (err) => {logger.e('webrtcPeerError:$err')});
  }

  on(WebrtcEvent name, Function(dynamic)? fn) {
    webrtcCorePeer.on(name, fn);
  }

  RTCVideoView attachStream(MediaStream stream) {
    var renderer = RTCVideoRenderer();
    renderer.initialize();
    renderer.srcObject = stream;
    return RTCVideoView(renderer);
  }

  addStream(MediaStream stream) {
    logger.i('add stream to webrtc');
    webrtcCorePeer.addStream(stream);
    localStreams.add(stream);
  }

  ///
  removeStream(MediaStream stream) {
    removeLocalStream(stream);
    removeRemoteStream(stream);
  }

  ///
  removeLocalStream(MediaStream stream) {
    int i = 0;
    for (var _stream in localStreams) {
      if (_stream == stream) {
        localStreams.remove(_stream);
        webrtcCorePeer.removeStream(_stream);
      }
    }
  }

  ///
  removeRemoteStream(MediaStream stream) {
    for (var _stream in localStreams) {
      if (_stream == stream) {
        remoteStreams.remove(_stream);
      }
    }
  }

  signal(WebrtcSignal signal) {
    webrtcCorePeer.signal(signal);
  }

  bool get connected {
    return webrtcCorePeer.connected;
  }

  send(Uint8List data) {
    if (webrtcCorePeer.connected) {
      webrtcCorePeer.send(data);
    } else {
      logger.e(
          'send failed , peerId:$targetPeerId;connectPeer:$connectPeerId session:$connectSessionId webrtc connection state is not connected');
    }
  }

  destroy(String err) async {
    await webrtcCorePeer.destroy(err);
  }
}
