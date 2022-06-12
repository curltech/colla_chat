import 'dart:typed_data';

import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/transport/webrtc/webrtc_core_peer.dart';
import 'package:colla_chat/transport/webrtc/webrtcpeerpool.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../provider/app_data.dart';

class WebrtcPeer {
  late WebrtcCorePeer webrtcPeer;
  String? targetPeerId;
  String? clientId;
  String? peerId;
  String? connectPeerId;
  String? connectSessionId;
  List<Map<String, String>>? iceServers = [];
  List<MediaStream> localStreams = [];
  List<MediaStream> remoteStreams = [];
  Map<String, dynamic> options = {};
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
      Map<String, dynamic> options = const {},
      Router? router}) {
    init(targetPeerId, clientId, initiator,
        iceServers: iceServers, options: options, router: router);
  }

  init(String targetPeerId, String clientId, bool initiator,
      {List<MediaStream> streams = const [],
      List<Map<String, String>>? iceServers,
      Map<String, dynamic> options = const {},
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
    if (options != null) {
      this.options = options;
    }
    if (streams != null) {
      localStreams.addAll(streams);
    }
    // 自定义属性，表示本节点createOffer时加入的sfu的编号，作为出版者还是订阅者，还是都是
    this.router = router;
    start = DateTime.now().millisecondsSinceEpoch;
    Map<String, dynamic> extension = {
      'clientId': myself.clientId,
      'peerId': myself.peerId,
      'router': router?.toJson()
    };
    if (initiator) {
      this.webrtcPeer = MasterWebrtcCorePeer();
      final webrtcPeer = this.webrtcPeer;
      if (webrtcPeer != null) {
        await webrtcPeer.init(streams: streams, extension: extension);
      }
    } else {
      this.webrtcPeer = FollowWebrtcCorePeer();
      final webrtcPeer = this.webrtcPeer;
      if (webrtcPeer != null) {
        await webrtcPeer.init(streams: streams, extension: extension);
      }
    }
    //下面的三个事件对于发起方和被发起方是一样的
    //可以发起信号
    final webrtcPeer = this.webrtcPeer;
    webrtcPeer.on(WebrtcEvent.signal, (WebrtcSignal signal) async {
      bool? force = extension['force'];
      if (force != null && force) {
        extension.remove('force');
      }
      await webrtcPeerPool.emit(WebrtcEvent.signal.name, {'data': signal, 'source': this});
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
      await webrtcPeerPool.emit(WebrtcEvent.data.name, {'data': data, 'source': this});
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
      await webrtcPeerPool.emit(
          WebrtcEvent.track.name, {'track': track, 'stream': stream, 'source': this});
    });

    webrtcPeer.on(
        WebrtcEvent.error, (err) => {logger.e('webrtcPeerError:$err')});
  }

  on(WebrtcEvent name, Function(dynamic)? fn) {
    webrtcPeer.on(name, fn);
  }

  RTCVideoView attachStream(MediaStream stream) {
    var renderer = RTCVideoRenderer();
    renderer.initialize();
    renderer.srcObject = stream;
    return RTCVideoView(renderer);
  }

  addStream(MediaStream stream) {
    logger.i('add stream to webrtc');
    webrtcPeer.addStream(stream);
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
        webrtcPeer.removeStream(_stream);
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
    webrtcPeer.signal(signal);
  }

  bool get connected {
    return webrtcPeer.connected;
  }

  send(Uint8List data) {
    if (webrtcPeer.connected) {
      webrtcPeer.send(data);
    } else {
      logger.e(
          'send failed , peerId:$targetPeerId;connectPeer:$connectPeerId session:$connectSessionId webrtc connection state is not connected');
    }
  }

  destroy(String err) async {
    await webrtcPeer.destroy(err);
  }
}
