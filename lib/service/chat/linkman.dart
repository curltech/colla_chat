import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/chat/peer_party.dart';
import 'package:colla_chat/entity/dht/base.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/peer_party.dart';
import 'package:colla_chat/service/dht/myselfpeer.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';

class LinkmanService extends PeerPartyService<Linkman> {
  Map<String, Linkman> linkmen = {};
  var publicKeys = <String, SimplePublicKey>{};

  LinkmanService(
      {required super.tableName,
      required super.fields,
      super.uniqueFields = const [
        'peerId',
      ],
      super.indexFields = const [
        'givenName',
        'name',
        'ownerPeerId',
        'mobile',
      ],
      super.encryptFields}) {
    post = (Map map) {
      return Linkman.fromJson(map);
    };
  }

  Future<List<Linkman>> search(String key,
      {LinkmanStatus? linkmanStatus}) async {
    var keyword = '%$key%';
    var where = '1=1';
    List<Object> whereArgs = [];
    if (StringUtil.isNotEmpty(key)) {
      where =
          '$where and (peerId=? or mobile like ? or name like ? or pyName like ? or email like ?)';
      whereArgs.addAll([key, keyword, keyword, keyword, keyword]);
    }
    if (linkmanStatus != null) {
      where = '$where and linkmanStatus=?';
      whereArgs.add(linkmanStatus.name);
    }
    var linkmen = await find(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'linkmanStatus,pyName,name',
    );
    if (linkmen.isNotEmpty) {
      for (var linkman in linkmen) {
        await setAvatar(linkman);
      }
    }
    return linkmen;
  }

  Future<void> setAvatar(Linkman linkman) async {
    var peerId = linkman.peerId;
    String? avatar = linkman.avatar;
    if (avatar != null) {
      var avatarImage = ImageUtil.buildImageWidget(
          imageContent: avatar,
          height: AppImageSize.mdSize,
          width: AppImageSize.mdSize,
          fit: BoxFit.contain);
      linkman.avatarImage = avatarImage;
    } else {
      PeerClient? peerClient =
          await peerClientService.findCachedOneByPeerId(peerId);
      if (peerClient != null) {
        linkman.avatarImage = peerClient.avatarImage;
      }
    }
    if (linkman.avatarImage == null &&
        linkman.linkmanStatus == LinkmanStatus.G.name) {
      linkman.avatarImage = ImageUtil.buildImageWidget(
          imageContent: 'assets/image/ollama.png',
          width: AppIconSize.lgSize,
          height: AppIconSize.lgSize);
    }
    linkmen[peerId] = linkman;
  }

  Future<Linkman?> findCachedOneByPeerId(String peerId) async {
    if (linkmen.containsKey(peerId)) {
      return linkmen[peerId];
    }
    Linkman? linkman = await findOneByPeerId(peerId);
    if (linkman != null) {
      setAvatar(linkman);
    }
    return linkman;
  }

  Future<SimplePublicKey?> getCachedPublicKey(String peerId) async {
    SimplePublicKey? simplePublicKey;
    String? publicKey;
    var linkman = await findCachedOneByPeerId(peerId);
    if (linkman != null) {
      simplePublicKey = publicKeys[peerId];
      publicKey = linkman.publicKey;
    }
    if (simplePublicKey == null) {
      if (StringUtil.isNotEmpty(publicKey)) {
        simplePublicKey = await cryptoGraphy.importPublicKey(publicKey!,
            type: KeyPairType.x25519);
        if (simplePublicKey != null) {
          publicKeys[peerId] = simplePublicKey;
        }
      } else {
        logger.e('linkman $peerId has no publicKey');
        return null;
      }
    }
    if (simplePublicKey == null) {
      simplePublicKey = await peerClientService.getCachedPublicKey(peerId);
      if (simplePublicKey != null) {
        publicKeys[peerId] = simplePublicKey;
      }
    }

    return simplePublicKey;
  }

  Future<Widget> findAvatarImageWidget(String peerId) async {
    Widget image = AppImage.mdAppImage;
    var linkman = await findCachedOneByPeerId(peerId);
    if (linkman != null && linkman.avatarImage != null) {
      image = linkman.avatarImage!;
    }
    return image;
  }

  Future<List<Linkman>> findSubscript(LinkmanStatus linkmanStatus) async {
    var where = 'subscriptStatus=?';
    List<Object> whereArgs = [linkmanStatus.name];
    var linkmen = await find(
      where: where,
      whereArgs: whereArgs,
    );
    return linkmen;
  }

  ///保存新的联系人信息，同时修改自己，peerClient和chatSummary的信息
  Future<void> store(Linkman linkman) async {
    Linkman? old = await findCachedOneByPeerId(linkman.peerId);
    if (old == null) {
      linkman.id = null;
      await insert(linkman);
    } else {
      old.email = linkman.email;
      old.mobile = linkman.mobile;
      old.name = linkman.name;
      old.clientId = linkman.clientId;
      old.avatar = linkman.avatar;
      old.status = linkman.status;
      old.address = linkman.address;
      old.startDate = linkman.startDate;
      old.endDate = linkman.endDate;
      if (linkman.peerPublicKey != null &&
          linkman.peerPublicKey != old.peerPublicKey) {
        old.peerPublicKey = linkman.peerPublicKey;
      }
      if (linkman.publicKey != null && linkman.publicKey != old.publicKey) {
        old.publicKey = linkman.publicKey;
      }
      await update(old);
    }
    linkmen[linkman.peerId] = linkman;
    await peerClientService.storeByPeerEntity(linkman);
    await myselfPeerService.storeByPeerEntity(linkman);
    await chatSummaryService.upsertByLinkman(linkman);
    linkmen.remove(linkman.peerId);
  }

  ///只保存新Linkman信息
  Future<Linkman> storeByPeerEntity(PeerEntity peerEntity,
      {LinkmanStatus? linkmanStatus}) async {
    String peerId = peerEntity.peerId;
    Linkman? linkman = await findCachedOneByPeerId(peerId);
    if (linkman == null) {
      Map<String, dynamic> map = peerEntity.toJson();
      linkman = Linkman.fromJson(map);
      if (linkmanStatus != null) {
        linkman.linkmanStatus = linkmanStatus.name;
      }
      linkman.id = null;
      await insert(linkman);
    } else {
      if (linkmanStatus != null) {
        linkman.linkmanStatus = linkmanStatus.name;
      }
      linkman.email = peerEntity.email;
      linkman.mobile = peerEntity.mobile;
      linkman.name = peerEntity.name;
      linkman.clientId = peerEntity.clientId;
      linkman.avatar = peerEntity.avatar;
      linkman.status = peerEntity.status;
      linkman.address = peerEntity.address;
      linkman.startDate = peerEntity.startDate;
      linkman.endDate = peerEntity.endDate;
      linkman.peerPublicKey = peerEntity.peerPublicKey;
      linkman.publicKey = peerEntity.publicKey;
      await update(linkman);
    }
    linkmen.remove(linkman.peerId);

    return linkman;
  }

  ///发出加好友的请求
  Future<ChatMessage> addFriend(String peerId, String? title,
      {TransportType transportType = TransportType.webrtc,
      CryptoOption cryptoOption = CryptoOption.linkman}) async {
    // 加好友会发送自己的信息，回执将收到对方的信息
    Map<String, dynamic> map = JsonUtil.toJson(myself.myselfPeer);
    PeerClient peerClient = PeerClient.fromJson(map);
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
        receiverPeerId: peerId,
        content: peerClient,
        subMessageType: ChatMessageSubType.addFriend,
        transportType: transportType,
        title: title);
    List<ChatMessage> chatMessages = await chatMessageService
        .sendAndStore(chatMessage, cryptoOption: cryptoOption);

    return chatMessages.first;
  }

  ///接收到加好友的请求，发送回执
  Future<ChatMessage> receiveAddFriend(
      ChatMessage chatMessage, MessageReceiptType receiptType) async {
    Map<String, dynamic> map = JsonUtil.toJson(myself.myselfPeer);
    PeerClient peerClient = PeerClient.fromJson(map);
    ChatMessage? chatReceipt = await chatMessageService.buildLinkmanChatReceipt(
        chatMessage, receiptType);
    //改变发送消息的状态为接收
    await chatMessageService.updateReceiptType(chatMessage, receiptType);
    if (receiptType == MessageReceiptType.accepted) {
      chatReceipt.content = JsonUtil.toJsonString(peerClient);
    }
    List<ChatMessage> chatMessages =
        await chatMessageService.sendAndStore(chatMessage);

    return chatMessages.first;
  }

  ///接收到加好友的回执
  Future<Linkman?> receiveAddFriendReceipt(ChatMessage chatReceipt) async {
    var receiptType = chatReceipt.receiptType;
    if (receiptType == MessageReceiptType.accepted.name) {
      Uint8List data = CryptoUtil.decodeBase64(chatReceipt.content!);
      String json = CryptoUtil.utf8ToString(data);
      Map<String, dynamic> map = JsonUtil.toJson(json);
      PeerClient peerClient = PeerClient.fromJson(map);
      return await linkmanService.storeByPeerEntity(peerClient);
    } else {
      var messageId = chatReceipt.messageId!;
      ChatMessage? chatMessage =
          await chatMessageService.findOriginByMessageId(messageId);
      if (chatMessage != null) {
        await chatMessageService.update(
            {'receiptType': MessageReceiptType.rejected.name},
            where: 'id=?',
            whereArgs: [chatMessage.id!]);
      }
    }
    return null;
  }

  ///发出更新联系人信息的请求
  Future<ChatMessage> findLinkman(String peerId, List<String> peerIds,
      {String? clientId}) async {
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
      receiverPeerId: peerId,
      clientId: clientId,
      content: peerIds,
      messageType: ChatMessageType.system,
      subMessageType: ChatMessageSubType.findLinkman,
    );
    List<ChatMessage> chatMessages =
        await chatMessageService.sendAndStore(chatMessage);

    return chatMessages.first;
  }

  ///接收更新联系人信息的请求
  receiveFindLinkman(ChatMessage chatMessage) async {
    String json = chatMessageService.recoverContent(chatMessage.content!);
    List<String> peerIds = [];
    List<dynamic> list = JsonUtil.toJson(json);
    for (String peerId in list) {
      peerIds.add(peerId);
    }
    await modifyLinkman(chatMessage.senderPeerId!,
        clientId: chatMessage.senderClientId, peerIds: peerIds);
  }

  ///发出联系人信息
  Future<ChatMessage> modifyLinkman(String peerId,
      {String? clientId, List<String>? peerIds}) async {
    peerIds ??= [myself.peerId!];
    List<PeerParty> peers = [];
    for (String peerId in peerIds) {
      Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
      if (linkman != null) {
        peers.add(linkman);
      }
    }
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
      receiverPeerId: peerId,
      clientId: clientId,
      content: peers,
      messageType: ChatMessageType.system,
      subMessageType: ChatMessageSubType.modifyLinkman,
    );
    List<ChatMessage> chatMessages =
        await chatMessageService.sendAndStore(chatMessage);

    return chatMessages.first;
  }

  ///接收到联系人信息，会同时修改消息和联系人
  receiveModifyLinkman(ChatMessage chatMessage) async {
    String json = chatMessageService.recoverContent(chatMessage.content!);
    List<dynamic> list = JsonUtil.toJson(json);
    for (dynamic map in list) {
      Linkman linkman = Linkman.fromJson(map);
      linkman.linkmanStatus = null;
      await store(linkman);
    }
  }

  removeByPeerId(String peerId) {
    delete(where: 'peerId=?', whereArgs: [peerId]);
    linkmen.remove(peerId);
  }

  ///更新头像
  @override
  Future<String?> updateAvatar(String peerId, List<int>? avatar) async {
    String? data = await super.updateAvatar(peerId, avatar);
    linkmen.remove(peerId);

    return data;
  }
}

final linkmanService = LinkmanService(
    tableName: 'chat_linkman',
    fields: ServiceLocator.buildFields(Linkman('', ''), []));
