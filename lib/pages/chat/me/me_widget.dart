import 'package:colla_chat/pages/chat/me/settings/personal_info_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/setting_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/common/app_bar_view.dart';
import '../../../widgets/common/data_group_listview.dart';
import '../../../widgets/common/data_listtile.dart';
import '../../../widgets/common/widget_mixin.dart';
import 'collection/collection_widget.dart';
import 'mail/address/address_add.dart';
import 'mail/mail_address_widget.dart';
import 'mail/mail_content_widget.dart';
import 'mail/mail_list_widget.dart';
import 'me_head_widget.dart';

//我的页面，带有路由回调函数
class MeWidget extends StatefulWidget with TileDataMixin {
  MeWidget({Key? key}) : super(key: key);

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'me';

  @override
  State<StatefulWidget> createState() {
    return _MeWidgetState();
  }

  @override
  Icon get icon => const Icon(Icons.person);

  @override
  String get title => 'Me';
}

class _MeWidgetState extends State<MeWidget> {
  CollectionWidget collectionWidget = CollectionWidget();
  SettingWidget settingWidget = const SettingWidget();
  PersonalInfoWidget personalInfoWidget = const PersonalInfoWidget();
  AddressAddWidget addressAddWidget = const AddressAddWidget();

  // MailView mailView = MailView();
  MailAddressWidget mailAddressWidget = const MailAddressWidget();
  MailListWidget mailListWidget = const MailListWidget();
  MailContentWidget mailContentWidget = const MailContentWidget();

  @override
  initState() {
    super.initState();
    var indexWidgetProvider =
        Provider.of<IndexWidgetProvider>(context, listen: false);

    //indexWidgetProvider.define(collectionWidget);
    indexWidgetProvider.define(settingWidget);
    indexWidgetProvider.define(personalInfoWidget);
    indexWidgetProvider.define(addressAddWidget);

    // indexWidgetProvider.define(mailView);
    indexWidgetProvider.define(mailAddressWidget);
    indexWidgetProvider.define(mailListWidget);
    indexWidgetProvider.define(mailContentWidget);
  }

  @override
  Widget build(BuildContext context) {
    List<TileDataMixin> mixins = [
      collectionWidget,
      addressAddWidget,
      mailAddressWidget,
      settingWidget
    ];
    final Map<TileData, List<TileData>> meTileData = {
      TileData(title: widget.title): TileData.from(mixins),
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
