import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:cryptography/cryptography.dart';

import '../entity/chat/chat.dart';
import '../entity/chat/contact.dart';
import '../entity/dht/peerclient.dart';
import '../service/chat/chat.dart';
import '../service/chat/contact.dart';
import '../service/dht/peerclient.dart';

class DataBuilder {
  static build(int count) async {
    PeerClient peerClient = PeerClient();

    ///peerId对应的密钥对
    SimpleKeyPair peerPrivateKey = await cryptoGraphy.generateKeyPair();
    peerClient.peerPublicKey =
        await cryptoGraphy.exportPublicKey(peerPrivateKey);
    peerClient.peerId = peerClient.peerPublicKey;

    ///加密对应的密钥对x25519
    SimpleKeyPair keyPair =
        await cryptoGraphy.generateKeyPair(keyPairType: 'x25519');
    peerClient.publicKey = await cryptoGraphy.exportPublicKey(keyPair);
    peerClient.name = await cryptoGraphy.getRandomAsciiString();
    PeerClientService.instance.insert(peerClient);

    /// 1/3
    Linkman linkman =
        Linkman(myself.peerId!, peerClient.peerId!, peerClient.name);
    await LinkmanService.instance.insert(linkman);

    /// 3个群
    Group group = Group(myself.peerId!, peerClient.peerId!, peerClient.name);
    await GroupService.instance.insert(group);

    ///每个群分别有3，4，5个成员
    GroupMember groupMember = GroupMember();
    await GroupMemberService.instance.insert(groupMember);

    /// 100条消息
    ChatMessage chatMessage = ChatMessage();
    await ChatMessageService.instance.insert(chatMessage);

    /// 好友和群相加的数量
    ChatSummary chatSummary = ChatSummary();
    await ChatSummaryService.instance.insert(chatSummary);
  }
}
