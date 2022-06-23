import 'package:colla_chat/pages/chat/me/mail/mail_view.dart';
import 'package:colla_chat/pages/chat/me/settings/personal_info_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/setting_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/app_data_provider.dart';
import '../../../widgets/common/app_bar_view.dart';
import '../../../widgets/common/data_group_listview.dart';
import '../../../widgets/common/data_listtile.dart';
import '../../../widgets/common/widget_mixin.dart';
import 'mail/address/address_add.dart';
import 'me_head_widget.dart';

//我的页面，带有路由回调函数
class MeWidget extends StatefulWidget with LeadingButtonMixin, RouteNameMixin {
  MeWidget({Key? key}) : super(key: key);

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'me';

  @override
  State<StatefulWidget> createState() {
    return _MeWidgetState();
  }
}

class _MeWidgetState extends State<MeWidget> {
  @override
  initState() {
    super.initState();
    //CollectionWidget collectionWidget = CollectionWidget();
    SettingWidget settingWidget = SettingWidget();
    PersonalInfoWidget personalInfoWidget = PersonalInfoWidget();
    MailView mailView = MailView();
    AddressAddWidget addressAddWidget = const AddressAddWidget();
    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);
    //indexWidgetProvider.define(collectionWidget);
    indexWidgetProvider.define(settingWidget);
    indexWidgetProvider.define(personalInfoWidget);
    indexWidgetProvider.define(mailView);
    indexWidgetProvider.define(addressAddWidget);
  }

  @override
  Widget build(BuildContext context) {
    final Map<TileData, List<TileData>> meTileData = {
      TileData(title: 'Me'): [
        TileData(
          icon: Icon(Icons.collections,
              color: appDataProvider.themeData?.colorScheme.primary),
          title: '收藏',
          routeName: 'collection',
        ),
        TileData(
          icon: Icon(Icons.contact_mail,
              color: appDataProvider.themeData?.colorScheme.primary),
          title: '邮件地址',
          routeName: 'mail_address_add',
        ),
        TileData(
          icon: Icon(Icons.email,
              color: appDataProvider.themeData?.colorScheme.primary),
          title: '邮件',
          routeName: 'mail',
        ),
        TileData(
          icon: Icon(Icons.settings,
              color: appDataProvider.themeData?.colorScheme.primary),
          title: '设置',
          routeName: 'setting',
        ),
      ]
    };
    var me = AppBarView(
        title: 'Me',
        child: Column(children: <Widget>[
          const MeHeadWidget(),
          GroupDataListView(tileData: meTileData)
        ]));
    return me;
  }
}
