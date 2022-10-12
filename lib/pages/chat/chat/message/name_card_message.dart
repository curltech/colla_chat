import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/image_widget.dart';
import 'package:flutter/material.dart';

///消息体：名片消息，content是json字符串
class NameCardMessage extends StatelessWidget {
  final String content;
  final bool isMyself;

  const NameCardMessage({
    Key? key,
    required this.content,
    required this.isMyself,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> map = JsonUtil.toJson(content);
    PeerClient peerClient = PeerClient.fromJson(map);
    var peerId = peerClient.peerId;
    var name = peerClient.name;
    var avatar = peerClient.avatar;
    var tile = InkWell(
      onTap: () {},
      child: ListTile(
        leading: ImageWidget(image: avatar),
        title: Text(name),
        subtitle: Text(peerId),
      ),
    );
    return SizedBox(height: 100, child: Card(elevation: 0, child: tile));
  }
}
