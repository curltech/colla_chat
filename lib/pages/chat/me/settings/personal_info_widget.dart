import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/pages/chat/me/settings/qrcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/index_widget_provider.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';
import '../../../../widgets/data_bind/data_group_listview.dart';
import '../../../../widgets/data_bind/data_listtile.dart';

class PersonalInfoWidget extends StatefulWidget with TileDataMixin {
  const PersonalInfoWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PersonalInfoWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'personal_info';

  @override
  Icon get icon => const Icon(Icons.personal_video);

  @override
  String get title => 'PersonalInfo';
}

class _PersonalInfoWidgetState extends State<PersonalInfoWidget>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    final QrcodeWidget qrcodeWidget = QrcodeWidget();
    indexWidgetProvider.define(qrcodeWidget);
  }

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
    final Map<TileData, List<TileData>> personalInfoTileData = {
      TileData(title: 'Setting'): [
        TileData(
          title: 'Avatar',
          suffix: myself.avatarImage,
          routeName: 'avatar',
        ),
        TileData(
          title: 'Name',
          suffix: name,
          routeName: 'name',
        ),
        TileData(
          title: 'PeerId',
          subtitle: peerId,
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
        withLeading: widget.withLeading,
        child: GroupDataListView(tileData: personalInfoTileData));
    return personalInfo;
  }
}
