import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/tool/json_util.dart';
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

    return InkWell(
      onTap: () {},
      child: Text(
        peerClient.name,
      ),
    );
  }
}
