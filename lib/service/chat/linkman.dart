import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/security_context.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/chat_summary.dart';
import 'package:colla_chat/service/chat/peer_party.dart';
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
      required super.indexFields}) {
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
          image: avatar,
          height: AppImageSize.mdSize,
          width: AppImageSize.mdSize,
          fit: BoxFit.contain);
      linkman.avatarImage = avatarImage;
    } else {
      PeerClient? peerClient = await peerClientService.findOneByPeerId(peerId);
      if (peerClient != null) {
        linkman.avatarImage = peerClient.avatarImage;
      }
    }
    if (linkman.avatarImage == null &&
        linkman.linkmanStatus == LinkmanStatus.chatGPT.name) {
      linkman.avatarImage = ImageUtil.buildImageWidget(
          image: 'assets/images/openai.png',
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
      simplePublicKey = await peerClientService.getCachedPublicKey(peerId);
      if (simplePublicKey == null) {
        if (publicKey == null) {
          logger.e('linkman $peerId has no publicKey');
          return null;
        }
        simplePublicKey = await cryptoGraphy.importPublicKey(publicKey,
            type: KeyPairType.x25519);
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

  ///发出linkman邀请，把自己的详细的信息发出，当邀请被同意后，就会收到对方详细的信息
  ///一般来说，采用websocket发送信息，是chainmessage，其中的payload是chatmessage
  ///而采用webrtc时，直接是chatmessage，content里面是实际的信息
  Future<void> requestLinkman(Linkman linkman) async {}

  Future<void> store(Linkman linkman) async {
    Linkman? old = await findCachedOneByPeerId(linkman.peerId);
    if (old == null) {
      linkman.id = null;
      await insert(linkman);
      linkmen[linkman.peerId] = linkman;
      await chatSummaryService.upsertByLinkman(linkman);
    } else {
      linkman.id = old.id;
      await update(linkman);
      linkmen[linkman.peerId] = linkman;
      await chatSummaryService.upsertByLinkman(linkman);
    }
    linkmen.remove(linkman.peerId);
  }

  ///通过peerclient增加或者修改
  Future<Linkman> storeByPeerClient(PeerClient peerClient,
      {LinkmanStatus? linkmanStatus}) async {
    String peerId = peerClient.peerId;
    Linkman? linkman = await findCachedOneByPeerId(peerId);
    if (linkman == null) {
      Map<String, dynamic> map = peerClient.toJson();
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
      linkman.email = peerClient.email;
      linkman.mobile = peerClient.mobile;
      linkman.name = peerClient.name;
      linkman.clientId = peerClient.clientId;
      linkman.avatar = peerClient.avatar;
      linkman.status = peerClient.status;
      linkman.address = peerClient.address;
      linkman.startDate = peerClient.startDate;
      linkman.endDate = peerClient.endDate;
      linkman.activeStatus = peerClient.activeStatus;
      linkman.trustLevel = peerClient.trustLevel;
      linkman.publicKey = peerClient.publicKey;
      linkman.peerPublicKey = peerClient.peerPublicKey;
      await update(linkman);
    }
    await chatSummaryService.upsertByLinkman(linkman);
    linkmen.remove(linkman.peerId);

    return linkman;
  }

  ///发出加好友的请求
  Future<ChatMessage> addFriend(String peerId, String? title,
      {TransportType transportType = TransportType.webrtc,
      CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    // 加好友会发送自己的信息，回执将收到对方的信息
    Map<String, dynamic> map = JsonUtil.toJson(myself.myselfPeer);
    PeerClient peerClient = PeerClient.fromJson(map);
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
        receiverPeerId: peerId,
        content: peerClient,
        subMessageType: ChatMessageSubType.addFriend,
        transportType: transportType,
        title: title);
    return await chatMessageService.sendAndStore(chatMessage,
        cryptoOption: cryptoOption);
  }

  ///接收到加好友的请求，发送回执
  Future<ChatMessage> receiveAddFriend(
      ChatMessage chatMessage, MessageReceiptType receiptType) async {
    Map<String, dynamic> map = JsonUtil.toJson(myself.myselfPeer);
    PeerClient peerClient = PeerClient.fromJson(map);
    ChatMessage? chatReceipt =
        await chatMessageService.buildChatReceipt(chatMessage, receiptType);
    //改变发送消息的状态为接收
    await chatMessageService.updateReceiptType(chatMessage, receiptType);
    if (receiptType == MessageReceiptType.accepted) {
      chatReceipt.content = JsonUtil.toJsonString(peerClient);
    }
    return await chatMessageService.sendAndStore(chatReceipt);
  }

  ///接收到加好友的回执
  Future<Linkman?> receiveAddFriendReceipt(ChatMessage chatReceipt) async {
    var receiptType = chatReceipt.receiptType;
    if (receiptType == MessageReceiptType.accepted.name) {
      Uint8List data = CryptoUtil.decodeBase64(chatReceipt.content!);
      String json = CryptoUtil.utf8ToString(data);
      Map<String, dynamic> map = JsonUtil.toJson(json);
      PeerClient peerClient = PeerClient.fromJson(map);
      return await linkmanService.storeByPeerClient(peerClient);
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
  Future<ChatMessage> modifyLinkman(String peerId,
      {String? clientId,
      CryptoOption cryptoOption = CryptoOption.cryptography}) async {
    // 加好友会发送自己的信息，回执将收到对方的信息
    Map<String, dynamic> map = JsonUtil.toJson(myself.myselfPeer);
    PeerClient peerClient = PeerClient.fromJson(map);
    ChatMessage chatMessage = await chatMessageService.buildChatMessage(
      receiverPeerId: peerId,
      clientId: clientId,
      content: peerClient,
      messageType: ChatMessageType.system,
      subMessageType: ChatMessageSubType.modifyLinkman,
    );
    return await chatMessageService.sendAndStore(chatMessage,
        cryptoOption: cryptoOption);
  }

  ///接收到更新联系人信息的请求
  receiveModifyLinkman(ChatMessage chatMessage) async {
    String json = chatMessageService.recoverContent(chatMessage.content!);
    Map<String, dynamic> map = JsonUtil.toJson(json);
    PeerClient peerClient = PeerClient.fromJson(map);
    return await linkmanService.storeByPeerClient(peerClient);
  }

  removeByPeerId(String peerId) {
    delete(where: 'peerId=?', whereArgs: [peerId]);
    linkmen.remove(peerId);
  }

  ///更新头像
  @override
  Future<String> updateAvatar(String peerId, List<int> avatar) async {
    String data = await super.updateAvatar(peerId, avatar);
    linkmen.remove(peerId);

    return data;
  }
}

final linkmanService = LinkmanService(
    tableName: 'chat_linkman',
    indexFields: [
      'givenName',
      'name',
      'ownerPeerId',
      'peerId',
      'mobile',
    ],
    fields: ServiceLocator.buildFields(Linkman('', ''), []));
