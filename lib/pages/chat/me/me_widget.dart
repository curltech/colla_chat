import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_list_widget.dart';

import 'package:colla_chat/pages/chat/me/mail/mail_widget.dart';
import 'package:colla_chat/pages/chat/me/me_head_widget.dart';
import 'package:colla_chat/pages/chat/me/media/media_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_list_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_list_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/personal_info_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/setting_widget.dart';
import 'package:colla_chat/pages/chat/me/webrtc/webrtc_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/pages/chat/me/platform_webview_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//我的页面，带有路由回调函数
class MeWidget extends StatelessWidget with TileDataMixin {
  final PersonalInfoWidget personalInfoWidget = const PersonalInfoWidget();
  final CollectionListWidget collectionListWidget = CollectionListWidget();
  final SettingWidget settingWidget = SettingWidget();
  final MailWidget mailWidget = MailWidget();

  final PeerEndpointListWidget peerEndpointListWidget =
      PeerEndpointListWidget();
  final PeerClientListWidget peerClientListWidget = PeerClientListWidget();
  final WebrtcWidget webrtcWidget = WebrtcWidget();
  final MediaWidget mediaWidget = MediaWidget();
  final PlatformWebViewWidget webViewWidget = PlatformWebViewWidget();

  late final Widget child;

  MeWidget({Key? key}) : super(key: key) {
    indexWidgetProvider.define(collectionListWidget);
    indexWidgetProvider.define(settingWidget);
    indexWidgetProvider.define(personalInfoWidget);
    indexWidgetProvider.define(mailWidget);
    indexWidgetProvider.define(peerEndpointListWidget);
    indexWidgetProvider.define(peerClientListWidget);
    indexWidgetProvider.define(webrtcWidget);
    indexWidgetProvider.define(webViewWidget);
    indexWidgetProvider.define(mediaWidget);
    List<TileDataMixin> mixins = [
      settingWidget,
      collectionListWidget,
      mailWidget,
      peerEndpointListWidget,
      peerClientListWidget,
      webrtcWidget,
      mediaWidget,
      webViewWidget
    ];
    final List<TileData> meTileData = TileData.from(mixins);
    for (var tile in meTileData) {
      tile.dense = true;
    }
    child = Expanded(child: DataListView(tileData: meTileData));
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
        title: Text(AppLocalizations.t(title)),
        child: Column(children: <Widget>[const MeHeadWidget(), child]));
    return me;
  }
}
