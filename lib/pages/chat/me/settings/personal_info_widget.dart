import 'package:colla_chat/entity/dht/myself.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/data_listview.dart';
import '../../../../widgets/common/image_widget.dart';

class PersonalInfoWidget extends StatelessWidget {
  final bool withBack;

  const PersonalInfoWidget({Key? key, this.withBack = true}) : super(key: key);

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
    final Map<String, List<TileData>> personalInfoTileData = {
      'Setting': [
        TileData(
          title: 'Avatar',
          suffix: const ImageWidget(
            width: 32.0,
            height: 32.0,
          ),
          routeName: 'avatar',
        ),
        TileData(
          title: 'Name',
          suffix: name,
          routeName: 'name',
        ),
        TileData(
          title: 'PeerId',
          suffix: peerId,
          routeName: 'peerId',
        ),
        TileData(
          title: 'Qrcode',
          routeName: 'qrcode',
        ),
      ]
    };
    var personalInfo = AppBarView(
        title: 'Personal Information',
        withBack: withBack,
        child: DataListView(tileData: personalInfoTileData));
    return personalInfo;
  }
}
