import 'package:colla_chat/entity/dht/myself.dart';
import 'package:flutter/material.dart';

import '../../../widgets/common/image_widget.dart';
import '../index/index_widget_controller.dart';

class MeHeadWidget extends StatelessWidget {
  const MeHeadWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String name;
    var peerId = myself.peerId;
    if (peerId == null) {
      peerId = '未登录';
      name = '未登录';
    } else {
      name = myself.myselfPeer!.name;
    }
    var listTile = ListTile(
      leading: const ImageWidget(
        width: 32.0,
        height: 32.0,
      ),
      title: Text(name),
      subtitle: Text(peerId),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        var indexWidgetController = IndexWidgetController.instance;
        indexWidgetController.push('personal_info');
      },
    );
    return InkWell(
      child: listTile,
    );
  }
}
