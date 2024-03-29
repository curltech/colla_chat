import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
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
      title: CommonAutoSizeText(name),
      subtitle: CommonAutoSizeText(peerId),
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
