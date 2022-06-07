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
  String? roomId;
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
      String? roomId}) {
    init(targetPeerId, clientId, initiator,
        iceServers: iceServers, options: options, roomId: roomId);
  }

  init(String targetPeerId, String clientId, bool initiator,
      {List<MediaStream> streams = const [],
      List<Map<String, String>>? iceServers,
      Map<String, dynamic> options = const {},
      String? roomId}) async {
    this.targetPeerId = targetPeerId;
    this.clientId = clientId;
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
    this.roomId = roomId;
    start = DateTime.now().millisecondsSinceEpoch;
    Map<String, dynamic> extension = {
      'clientId': myself.clientId,
      'peerId': myself.peerId
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
    webrtcPeer.on('signal', (data) async {
      if (this.roomId != null) {
        data.router = this.roomId;
      }
      bool? force = extension['force'];
      if (force != null && force) {
        extension.remove('force');
      }
      await webrtcPeerPool.emitEvent('signal', {'data': data, 'source': this});
    });

    //连接建立/
    webrtcPeer.on('connect', (data) async {
      end = DateTime.now().millisecondsSinceEpoch;
      if (end != null && start != null) {
        var interval = end! - start!;
        logger.i('connect time:$interval');
      }
      await webrtcPeerPool.emitEvent('connect', {'source': this});
    });

    webrtcPeer.on('close', (data) async {
      if (this.targetPeerId != null) {
        await webrtcPeerPool.remove(this.targetPeerId!);
      }
    });

    //收到数据
    webrtcPeer.on('data', (data) async {
      logger.i('${DateTime.now().toUtc()}:got a message from peer: $data');
      await webrtcPeerPool.emitEvent('data', {'data': data, 'source': this});
    });

    webrtcPeer.on('stream', (stream) async {
      remoteStreams.add(stream);
      if (stream != null) {
        stream.onremovetrack = (event) {
          logger.i('Video track: ${event.track.label} removed');
        };
      }
      await webrtcPeerPool
          .emitEvent('stream', {'stream': stream, 'source': this});
    });

    webrtcPeer.on('track', (track, stream) async {
      logger.i('${DateTime.now().toUtc().toIso8601String()}:track');
      await webrtcPeerPool.emitEvent(
          'track', {'track': track, 'stream': stream, 'source': this});
    });

    webrtcPeer.on('error', (err) => {logger.e('webrtcPeerError:$err')});
  }

  on(String name, Function(dynamic)? fn) {
    webrtcPeer.on(name, fn);
  }

  attachStream(MediaStream stream) {
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

  /// 空参数全部删除
  removeStream(MediaStream stream) {
    this.removeLocalStream(stream);
    this.removeRemoteStream(stream);
  }

  /// 空参数全部删除
  removeLocalStream(MediaStream stream) {
    int i = 0;
    for (var i = localStreams.length - 1; i >= 0; i--) {
      var _stream = localStreams[i];
      if (stream == null || _stream == stream) {
        localStreams.remove(_stream);
        webrtcPeer.removeStream(_stream);
      }
    }
  }

  /// 空参数全部删除
  removeRemoteStream(MediaStream stream) {
    for (var i = remoteStreams.length - 1; i >= 0; i--) {
      var _stream = remoteStreams[i];
      if (stream == null || _stream == stream) {
        remoteStreams.remove(_stream);
      }
    }
  }

  signal(dynamic data) {
    webrtcPeer.signal(data);
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
