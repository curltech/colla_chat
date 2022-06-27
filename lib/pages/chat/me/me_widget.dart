import 'package:colla_chat/pages/chat/me/settings/personal_info_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/setting_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:flutter/material.dart';

import '../../../provider/app_data_provider.dart';
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
class MeWidget extends StatelessWidget with TileDataMixin {
  final CollectionWidget collectionWidget = CollectionWidget();
  final SettingWidget settingWidget = SettingWidget();
  final PersonalInfoWidget personalInfoWidget = const PersonalInfoWidget();
  final AddressAddWidget addressAddWidget = const AddressAddWidget();

  // MailView mailView = MailView();
  final MailAddressWidget mailAddressWidget = MailAddressWidget();
  final MailListWidget mailListWidget = const MailListWidget();
  final MailContentWidget mailContentWidget = const MailContentWidget();

  late final Widget child;

  MeWidget({Key? key}) : super(key: key) {
    var indexWidgetProvider = IndexWidgetProvider.instance;
    logger.w('me init');
    //indexWidgetProvider.define(collectionWidget);
    indexWidgetProvider.define(settingWidget);
    indexWidgetProvider.define(personalInfoWidget);
    indexWidgetProvider.define(addressAddWidget);

    // indexWidgetProvider.define(mailView);
    indexWidgetProvider.define(mailAddressWidget);
    indexWidgetProvider.define(mailListWidget);
    indexWidgetProvider.define(mailContentWidget);

    List<TileDataMixin> mixins = [
      collectionWidget,
      addressAddWidget,
      mailAddressWidget,
      settingWidget
    ];
    final Map<TileData, List<TileData>> meTileData = {
      TileData(title: title): TileData.from(mixins),
    };
    child = GroupDataListView(tileData: meTileData);
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'me';

  @override
  Icon get icon => const Icon(Icons.person);

  @override
  String get title => 'Me';

  @override
  Widget build(BuildContext context) {
    var me = AppBarView(
        title: 'Me',
        child: Column(children: <Widget>[const MeHeadWidget(), child]));
    return me;
  }
}
