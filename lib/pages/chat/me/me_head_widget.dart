import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class MeHeadWidget extends StatelessWidget {
  const MeHeadWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String peerId;
    String name;
    var myselfPeer = myself.myselfPeer;
    if (myselfPeer == null) {
      peerId = '未登录';
      name = '未登录';
    } else {
      peerId = myselfPeer.peerId;
      name = myselfPeer.name;
    }
    var listTile = ListTile(
      leading: myself.avatarImage,
      title: Text(name),
      subtitle: Text(peerId),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        var indexWidgetProvider =
            Provider.of<IndexWidgetProvider>(context, listen: false);
        indexWidgetProvider.push('personal_info', context: context);
      },
    );
    return InkWell(
      child: listTile,
    );
  }
}
