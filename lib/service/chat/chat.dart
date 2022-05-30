import '../../datastore/datastore.dart';
import '../../entity/chat/chat.dart';
import '../../entity/dht/myself.dart';
import '../../entity/p2p/security_context.dart';
import '../base.dart';
import '../p2p/security_context.dart';

class ChatMessageService extends BaseService {
  static final ChatMessageService _instance = ChatMessageService();
  static bool initStatus = false;

  static ChatMessageService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<ChatMessageService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }

  Future<List<ChatMessage>> load(String where,
      {List<Object>? whereArgs,
      String? orderBy,
      int? offset,
      int? limit}) async {
    List<Map> data = await find(where,
        whereArgs: whereArgs, orderBy: orderBy, offset: offset, limit: limit);
    List<ChatMessage> chatMessages = [];
    for (var d in data) {
      var chatMessage = ChatMessage.fromJson(d);
      SecurityContext securityContext = SecurityContext();
      securityContext.needCompress = chatMessage.needCompress;
      securityContext.needEncrypt = chatMessage.needEncrypt;
      securityContext.payloadKey = chatMessage.payloadKey;
      var content = chatMessage.content;
      var thumbnail = chatMessage.thumbnail;
      if (content != null) {
        content =
            await SecurityContextService.decrypt(content, securityContext);
        chatMessage.content = content;
      }
      if (thumbnail != null) {
        thumbnail =
            await SecurityContextService.decrypt(thumbnail, securityContext);
        chatMessage.thumbnail = thumbnail;
      }
      chatMessages.add(chatMessage);
    }
    return chatMessages;
  }

  /// 批量保存聊天消息
  store(List<ChatMessage> chatMessages, dynamic parent) async {
    if (chatMessages.isEmpty) {
      return;
    }
    var peerProfile = myself.peerProfile;
    if (peerProfile != null && peerProfile.localDataCryptoSwitch) {
      SecurityContext securityContext = SecurityContext();
      securityContext.needCompress = true;
      securityContext.needEncrypt = true;
      for (var chatMessage in chatMessages) {
        var state = chatMessage.state;
        if (EntityState.Deleted.name == state) {
          continue;
        }
        securityContext.payloadKey = chatMessage.payloadKey;
        var content = chatMessage.content;
        if (content != null) {
          var result =
              await SecurityContextService.encrypt(content, securityContext);
          chatMessage.payloadKey = result.payloadKey;
          chatMessage.needCompress = result.needCompress;
          chatMessage.content = result.transportPayload;
          chatMessage.payloadHash = result.payloadHash;
        }
        var thumbnail = chatMessage.thumbnail;
        if (thumbnail != null) {
          var result =
              await SecurityContextService.encrypt(thumbnail, securityContext);
          chatMessage.thumbnail = result.transportPayload;
        }
      }
    }
    await save(chatMessages, [], parent);
  }
}

class MergeMessageService extends BaseService {
  static final MergeMessageService _instance = MergeMessageService();
  static bool initStatus = false;

  static MergeMessageService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<MergeMessageService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }
}

class ChatAttachService extends BaseService {
  static final ChatAttachService _instance = ChatAttachService();
  static bool initStatus = false;

  static ChatAttachService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<ChatAttachService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }

  store(dynamic entity) async {
    List<ChatAttach> attaches = entity.attaches;
    var peerProfile = myself.peerProfile;
    if (peerProfile != null && peerProfile.localDataCryptoSwitch) {
      SecurityContext securityContext = SecurityContext();
      securityContext.needCompress = true;
      securityContext.needEncrypt = true;
      for (var attach in attaches) {
        if (EntityState.Deleted.name == entity.state) {
          attach.state = EntityState.Deleted.name;
          continue;
        }
        var content = attach.content;
        if (content != null) {
          var result =
              await SecurityContextService.encrypt(content, securityContext);
          attach.payloadKey = result.payloadKey;
          attach.needCompress = result.needCompress;
          attach.needCompress = result.needEncrypt;
          attach.content = result.transportPayload;
          attach.payloadHash = result.payloadHash;
        }
      }
      await save(attaches, [], entity.attachs);
    } else {
      await save(attaches, [], entity.attachs);
    }
  }

  load(String attachBlockId, int? offset) async {
    var where = 'attachBlockId=? and ownerPeerId=?';
    var peerId = myself.peerId;
    if (peerId == null) {
      return;
    }
    List<Object> whereArgs = [attachBlockId, peerId];
    List<ChatAttach> attaches = [];
    var data = await find(where, whereArgs: whereArgs);
    SecurityContext securityContext = SecurityContext();
    securityContext.needCompress = true;
    securityContext.needEncrypt = true;
    for (var d in data) {
      var chatAttach = ChatAttach.fromJson(d);
      var payloadKey = chatAttach.payloadKey;
      if (payloadKey != null) {
        securityContext.payloadKey = payloadKey;
        var content = chatAttach.content;
        if (content != null) {
          content =
              await SecurityContextService.decrypt(content, securityContext);
          //d.content = StringUtil.decodeURI(payload)
          chatAttach.content = content;
        }
      }
      attaches.add(chatAttach);
    }
    return attaches;
  }
}

class ReceiveService extends BaseService {
  static final ReceiveService _instance = ReceiveService();
  static bool initStatus = false;

  static ReceiveService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<ReceiveService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }
}

class ChatService extends BaseService {
  static final ChatService _instance = ChatService();
  static bool initStatus = false;

  static ChatService get instance {
    if (!initStatus) {
      throw 'please init!';
    }
    return _instance;
  }

  static Future<ChatService> init(
      {required String tableName,
      required List<String> fields,
      List<String>? indexFields}) async {
    if (!initStatus) {
      await BaseService.init(_instance,
          tableName: tableName, fields: fields, indexFields: indexFields);
      initStatus = true;
    }
    return _instance;
  }
}

class ChatBlockService {}

var chatBlockService = ChatBlockService();
