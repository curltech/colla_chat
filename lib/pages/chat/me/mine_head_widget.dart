import 'package:colla_chat/entity/dht/myself.dart';
import 'package:flutter/material.dart';

import '../../../widgets/common/image_widget.dart';

class MineHeadWidget extends StatelessWidget {
  const MineHeadWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var listTile = ListTile(
      leading: const ImageWidget(
        width: 32.0,
        height: 32.0,
      ),
      title: Text(myself.myselfPeer!.name!),
      subtitle: Text(myself.peerId!),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        //routePush(PersonalInfoPage());
      },
    );
    return InkWell(
      child: listTile,
    );
  }
}
