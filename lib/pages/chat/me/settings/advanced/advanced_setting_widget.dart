import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/myselfpeer/myself_peer_list_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_list_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_list_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/ws_address_picker.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

/// 高级设置组件，包括定位器配置
class AdvancedSettingWidget extends StatelessWidget with TileDataMixin {
  final PeerEndpointListWidget peerEndpointListWidget =
      PeerEndpointListWidget();
  final PeerClientListWidget peerClientListWidget = PeerClientListWidget();
  final MyselfPeerListWidget myselfPeerListWidget =
      const MyselfPeerListWidget();
  late final List<TileData> advancedSettingTileData;

  AdvancedSettingWidget({super.key}) {
    indexWidgetProvider.define(peerEndpointListWidget);
    indexWidgetProvider.define(peerClientListWidget);
    indexWidgetProvider.define(myselfPeerListWidget);
    List<TileDataMixin> mixins = [
      peerEndpointListWidget,
      peerClientListWidget,
      myselfPeerListWidget,
    ];
    advancedSettingTileData = TileData.from(mixins);
    for (var tile in advancedSettingTileData) {
      tile.dense = true;
    }
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'advanced_setting';

  @override
  IconData get iconData => Icons.settings_suggest;

  @override
  String get title => 'Advanced Setting';

  

  Widget _buildSettingWidget(BuildContext context) {
    Widget child = DataListView(
      itemCount: advancedSettingTileData.length,
      itemBuilder: (BuildContext context, int index) {
        return advancedSettingTileData[index];
      },
    );
    var padding = const EdgeInsets.symmetric(horizontal: AppPadding.mdPadding);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: AppPadding.mdPadding),
        Padding(
          padding: padding,
          child: WsAddressPicker(),
        ),
        const SizedBox(height: AppPadding.mdPadding),
        child
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true, title: title,helpPath: routeName, child: _buildSettingWidget(context));
  }
}
