import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_controller.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_view_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

//设置页面，带有回退回调函数
class PeerClientListWidget extends StatelessWidget with TileDataMixin {
  final PeerClientViewWidget peerClientViewWidget = PeerClientViewWidget();
  final PeerClientEditWidget peerClientEditWidget = PeerClientEditWidget();

  PeerClientListWidget({super.key}) {
    indexWidgetProvider.define(peerClientViewWidget);
    indexWidgetProvider.define(peerClientEditWidget);
    peerClientController.clear(notify: false);
    peerClientController.more();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'peer_client';

  @override
  IconData get iconData => Icons.desktop_windows;

  @override
  String get title => 'PeerClient';

  List<TileData> _buildPeerClientTileData() {
    List<PeerClient> peerClients = peerClientController.data.value;
    List<TileData> tiles = [];
    if (peerClients.isNotEmpty) {
      int i = 0;
      for (var peerClient in peerClients) {
        var title = peerClient.name;
        var subtitle = peerClient.peerId;
        TileData tile = TileData(
            selected: peerClientController.currentIndex.value == i,
            prefix: peerClient.avatarImage,
            title: title,
            subtitle: subtitle,
            routeName: 'peer_client_edit');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.remove,
            onTap: (int index, String label, {String? subtitle}) async {
              peerClientController.setCurrentIndex = index;
              peerClientService.delete(entity: peerClient);
              peerClientController.delete();
            });
        slideActions.add(deleteSlideAction);
        TileData editSlideAction = TileData(
            title: 'Edit',
            prefix: Icons.edit,
            onTap: (int index, String label, {String? subtitle}) async {
              peerClientController.setCurrentIndex = index;
              indexWidgetProvider.push('peer_client_edit');
            });
        slideActions.add(editSlideAction);
        tile.slideActions = slideActions;
        tiles.add(tile);
        i++;
      }
    }
    return tiles;
  }

  Future<void> _onRefresh() async {
    await peerClientController.more();
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    peerClientController.setCurrentIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    var peerClientView = RefreshIndicator(
        onRefresh: _onRefresh,
        //notificationPredicate: _notificationPredicate,
        child: Obx(() {
          var tiles = _buildPeerClientTileData();
          return DataListView(
            onTap: _onTap,
            itemCount: tiles.length,
            itemBuilder: (BuildContext context, int index) {
              return tiles[index];
            },
          );
        }));

    var peerClientWidget = AppBarView(
        title: title, withLeading: withLeading, child: peerClientView);

    return peerClientWidget;
  }
}
