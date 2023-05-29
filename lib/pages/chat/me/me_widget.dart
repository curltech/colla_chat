import 'package:colla_chat/pages/chat/me/collection/collection_list_view.dart';
import 'package:colla_chat/pages/chat/me/contact_widget.dart';
import 'package:colla_chat/pages/chat/me/logger_console_view.dart';
import 'package:colla_chat/pages/chat/me/mail/mail_widget.dart';
import 'package:colla_chat/pages/chat/me/me_head_widget.dart';
import 'package:colla_chat/pages/chat/me/media/media_widget.dart';
import 'package:colla_chat/pages/chat/me/openvpn_widget.dart';
import 'package:colla_chat/pages/chat/me/personal_info_widget.dart';
import 'package:colla_chat/pages/chat/me/platform_webview_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/setting_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/webrtc_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//我的页面，带有路由回调函数
class MeWidget extends StatelessWidget with TileDataMixin {
  final PersonalInfoWidget personalInfoWidget = const PersonalInfoWidget();
  final CollectionListView collectionListView = CollectionListView();
  final SettingWidget settingWidget = SettingWidget();
  final MailWidget mailWidget = MailWidget();
  final WebrtcWidget webrtcWidget = WebrtcWidget();
  final MediaWidget mediaWidget = MediaWidget();
  final PlatformWebViewWidget webViewWidget = PlatformWebViewWidget();
  final OpenVpnWidget openVpnWidget = const OpenVpnWidget();
  final LoggerConsoleView loggerConsoleView = const LoggerConsoleView();
  final ContactWidget contactWidget = const ContactWidget();

  late final List<TileData> meTileData;

  MeWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(collectionListView);
    indexWidgetProvider.define(settingWidget);
    indexWidgetProvider.define(personalInfoWidget);
    indexWidgetProvider.define(contactWidget);
    indexWidgetProvider.define(mailWidget);
    indexWidgetProvider.define(webrtcWidget);
    indexWidgetProvider.define(webViewWidget);
    indexWidgetProvider.define(mediaWidget);
    indexWidgetProvider.define(openVpnWidget);
    indexWidgetProvider.define(loggerConsoleView);
    List<TileDataMixin> mixins = [
      settingWidget,
      collectionListView,
      mailWidget,
      contactWidget,
      webrtcWidget,
      webViewWidget,
      mediaWidget,
      openVpnWidget,
      loggerConsoleView,
    ];
    meTileData = TileData.from(mixins);
    for (var tile in meTileData) {
      tile.dense = true;
      tile.selected = false;
    }
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'me';

  @override
  IconData get iconData => Icons.person;

  @override
  String get title => 'Me';

  @override
  Widget build(BuildContext context) {
    Widget child = DataListView(tileData: meTileData);
    var me = AppBarView(
        title: title,
        child: Column(
            children: <Widget>[const MeHeadWidget(), Expanded(child: child)]));
    return me;
  }
}
