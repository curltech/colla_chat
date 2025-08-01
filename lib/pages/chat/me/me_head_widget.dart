import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MeHeadWidget extends StatelessWidget {
  const MeHeadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    String peerId;
    String name;
    var myselfPeer = myself.myselfPeer;

    peerId = myselfPeer.peerId;
    name = myselfPeer.name;
    var listTile = ListTile(
      leading: myself.avatarImage,
      title: AutoSizeText(name),
      subtitle: AutoSizeText(peerId),
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
