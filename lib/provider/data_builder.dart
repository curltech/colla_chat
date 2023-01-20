import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:cryptography/cryptography.dart';

import '../crypto/util.dart';
import '../entity/chat/chat.dart';
import '../entity/chat/contact.dart';
import '../entity/dht/peerclient.dart';
import '../platform.dart';
import '../service/chat/chat.dart';
import '../service/chat/contact.dart';
import '../service/dht/peerclient.dart';

class DataBuilder {
  static build() async {
    List<Linkman> linkmen = [];
    var deviceData = platformParams.deviceData;
    var clientDevice = JsonUtil.toJsonString(deviceData);
    var hash = await cryptoGraphy.hash(clientDevice.codeUnits);
    var clientId = CryptoUtil.encodeBase58(hash);
    for (var i = 0; i < 20; ++i) {
      PeerClient peerClient = PeerClient('', clientId, '');

      ///peerId对应的密钥对
      SimpleKeyPair peerPrivateKey = await cryptoGraphy.generateKeyPair();
      peerClient.peerPublicKey =
          await cryptoGraphy.exportPublicKey(peerPrivateKey);
      peerClient.peerId = peerClient.peerPublicKey!;

      ///加密对应的密钥对x25519
      SimpleKeyPair keyPair =
          await cryptoGraphy.generateKeyPair(keyPairType: KeyPairType.x25519);
      peerClient.publicKey = await cryptoGraphy.exportPublicKey(keyPair);
      peerClient.name = 'PeerClient$i';
      peerClientService.insert(peerClient);

      if (i % 3 == 0) {
        Linkman linkman = Linkman(peerClient.peerId, peerClient.name);
        await linkmanService.insert(linkman);
        linkmen.add(linkman);

        ChatSummary chatSummary = ChatSummary();
        chatSummary.peerId = linkman.peerId;
        chatSummary.name = linkman.name;
        chatSummary.partyType = PartyType.linkman.name;
        await chatSummaryService.insert(chatSummary);
      }
    }

    /// 3个群
    List<Group> groups = [];
    for (var i = 0; i < 3; ++i) {
      ///peerId对应的密钥对
      SimpleKeyPair peerPrivateKey = await cryptoGraphy.generateKeyPair();
      var peerPublicKey = await cryptoGraphy.exportPublicKey(peerPrivateKey);
      var peerId = peerPublicKey;

      ///加密对应的密钥对x25519
      SimpleKeyPair keyPair =
          await cryptoGraphy.generateKeyPair(keyPairType: KeyPairType.x25519);
      var publicKey = await cryptoGraphy.exportPublicKey(keyPair);
      var name = 'Group$i';
      Group group = Group(peerId, name);
      group.publicKey = publicKey;
      group.peerPublicKey = peerPublicKey;
      await groupService.insert(group);
      groups.add(group);

      ChatSummary chatSummary = ChatSummary();
      chatSummary.peerId = group.peerId;
      chatSummary.name = group.name;
      chatSummary.partyType = PartyType.group.name;
      await chatSummaryService.insert(chatSummary);

      for (var j = 0; j < 3; ++j) {
        ///每个群分别有3，4，5个成员
        GroupMember groupMember = GroupMember();
        groupMember.groupId = group.peerId;
        groupMember.memberPeerId = linkmen[i + j].peerId;
        if (j == 0) {
          groupMember.memberType = MemberType.owner.name;
        } else {
          groupMember.memberType = MemberType.member.name;
        }
        await groupMemberService.insert(groupMember);
      }

      GroupMember groupMember = GroupMember();
      groupMember.groupId = group.peerId;
      groupMember.memberPeerId = myself.peerId;
      groupMember.memberType = MemberType.member.name;
      await groupMemberService.insert(groupMember);
    }

    /// 100条消息
    for (var i = 0; i < 100; ++i) {
      ChatMessage chatMessage = ChatMessage();
      chatMessage.title = 'title$i';
      chatMessage.content = 'message content$i';
      chatMessage.contentType = ContentType.text.name;
      chatMessage.messageId = await cryptoGraphy.getRandomAsciiString();
      chatMessage.messageType = ChatMessageType.chat.name;
      if (i % 2 == 0) {
        chatMessage.direct = ChatDirect.send.name;
        if (i % 3 == 0) {
          chatMessage.receiverPeerId = groups[i % 3].peerId;
          chatMessage.receiverName = groups[i % 3].name;
          chatMessage.receiverType = PartyType.group.name;
        } else {
          chatMessage.receiverPeerId = linkmen[i % 7].peerId;
          chatMessage.receiverName = linkmen[i % 7].name;
          chatMessage.receiverType = PartyType.linkman.name;
        }
        chatMessage.sendTime = DateUtil.currentDate();
        await chatMessageService.insert(chatMessage);
        ChatSummary? chatSummary =
            await chatSummaryService.findByPeerId(chatMessage.receiverPeerId!);
        if (chatSummary != null) {
          chatSummary.messageId = chatMessage.messageId;
          chatSummary.messageType = chatMessage.messageType;
          chatSummary.title = chatMessage.title;
          chatSummary.content = chatMessage.content;
          chatSummary.contentType = chatMessage.contentType;
          chatSummary.sendReceiveTime = chatMessage.sendTime;
          var unreadNumber = chatSummary.unreadNumber;
          chatSummary.unreadNumber = unreadNumber + 1;
          await chatSummaryService.update(chatSummary);
        }
      } else {
        chatMessage.direct = ChatDirect.receive.name;
        chatMessage.senderPeerId = linkmen[i % 7].peerId;
        if (i % 3 == 0) {
          chatMessage.receiverPeerId = groups[i % 3].peerId;
          chatMessage.receiverType = PartyType.group.name;
        } else {
          chatMessage.receiverType = PartyType.linkman.name;
        }
        chatMessage.receiveTime = DateUtil.currentDate();
        await chatMessageService.insert(chatMessage);

        ChatSummary? chatSummary =
            await chatSummaryService.findByPeerId(chatMessage.senderPeerId!);
        if (chatSummary != null) {
          chatSummary.messageId = chatMessage.messageId;
          chatSummary.messageType = chatMessage.messageType;
          chatSummary.title = chatMessage.title;
          chatSummary.content = chatMessage.content;
          chatSummary.contentType = chatMessage.contentType;
          chatSummary.sendReceiveTime = chatMessage.receiveTime;
          var unreadNumber = chatSummary.unreadNumber;
          chatSummary.unreadNumber = unreadNumber + 1;
          await chatSummaryService.update(chatSummary);
        }
      }
    }
  }
}
