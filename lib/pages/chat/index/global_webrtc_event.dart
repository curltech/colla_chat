import 'dart:async';

import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/transport/webrtc/base_peer_connection.dart';
import 'package:synchronized/synchronized.dart';

class AllowedResult {
  bool allowed;
  DateTime timestamp;

  AllowedResult(this.allowed, this.timestamp);
}

///跟踪影响全局的webrtc事件到来，对不同类型的事件进行分派
class GlobalWebrtcEvent {
  Future<bool?> Function(WebrtcEvent webrtcEvent)? onWebrtcSignal;
  Map<String, AllowedResult> results = {};

  StreamController<WebrtcEvent> webrtcEventStreamController =
      StreamController<WebrtcEvent>.broadcast();
  StreamController<WebrtcEvent> errorWebrtcEventStreamController =
      StreamController<WebrtcEvent>.broadcast();

  Lock lock = Lock();

  GlobalWebrtcEvent();

  /// 跟踪影响全局的webrtc协商信号事件到来，对不同类型的事件进行分派
  /// 目前用于处理对方的webrtc呼叫是否被允许
  Future<bool> receiveWebrtcSignal(WebrtcEvent webrtcEvent) async {
    bool allowed;
    String peerId = webrtcEvent.peerId;
    String name = webrtcEvent.name;
    String clientId = webrtcEvent.clientId;

    Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
    if (linkman != null) {
      ///呼叫者本地存在
      if (linkman.linkmanStatus == LinkmanStatus.friend.name) {
        ///如果是好友，则直接接受
        return true;
      } else if (linkman.linkmanStatus == LinkmanStatus.blacklist.name) {
        ///如果是黑名单，则直接拒绝
        return false;
      }
    } else {
      // Linkman linkman = Linkman(peerId, name);
      // linkman.clientId = clientId;
      // linkman.peerPublicKey = peerId;
      // linkmanService.store(linkman);
    }

    ///linkman不存在，或者既不是好友也不是黑名单，由外部接口判断
    allowed = await lock.synchronized(() async {
      ///如果保存的判断结果是24小时之内
      if (results.containsKey(peerId)) {
        bool a = results[peerId]!.allowed;
        DateTime t = results[peerId]!.timestamp;
        t = t.add(const Duration(hours: 24));
        DateTime c = DateTime.now();
        if (t.isAfter(c)) {
          return a;
        }
      }

      ///否则重新判断
      if (onWebrtcSignal != null) {
        bool? a = await onWebrtcSignal!(webrtcEvent);
        a ??= true;
        results[peerId] = AllowedResult(a, DateTime.now());

        return a;
      }
      return true;
    });

    return allowed;
  }
}

final GlobalWebrtcEvent globalWebrtcEvent = GlobalWebrtcEvent();
