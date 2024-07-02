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

//设置页面，带有回退回调函数
class PeerClientListWidget extends StatefulWidget with TileDataMixin {
  final PeerClientViewWidget peerClientViewWidget =
      const PeerClientViewWidget();
  final PeerClientEditWidget peerClientEditWidget =
      const PeerClientEditWidget();

  PeerClientListWidget({super.key}) {
    indexWidgetProvider.define(peerClientViewWidget);
    indexWidgetProvider.define(peerClientEditWidget);
  }

  @override
  State<StatefulWidget> createState() => _PeerClientListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'peer_client';

  @override
  IconData get iconData => Icons.desktop_windows;

  @override
  String get title => 'PeerClient';
}

class _PeerClientListWidgetState extends State<PeerClientListWidget> {
  final ValueNotifier<List<TileData>> tiles = ValueNotifier<List<TileData>>([]);

  @override
  initState() {
    super.initState();
    peerClientController.clear(notify: false);
    _more();
  }

  _more() async {
    await peerClientController.more();
    _buildPeerClientTileData();
  }

  void _buildPeerClientTileData() {
    List<PeerClient> peerClients = peerClientController.data;
    List<TileData> tiles = [];
    if (peerClients.isNotEmpty) {
      for (var peerClient in peerClients) {
        var title = peerClient.name;
        var subtitle = peerClient.peerId;
        TileData tile = TileData(
            prefix: peerClient.avatarImage,
            title: title,
            subtitle: subtitle,
            routeName: 'peer_client_edit');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.remove,
            onTap: (int index, String label, {String? subtitle}) async {
              peerClientController.currentIndex = index;
              peerClientService.delete(entity: peerClient);
              peerClientController.delete();
            });
        slideActions.add(deleteSlideAction);
        TileData editSlideAction = TileData(
            title: 'Edit',
            prefix: Icons.edit,
            onTap: (int index, String label, {String? subtitle}) async {
              peerClientController.currentIndex = index;
              indexWidgetProvider.push('peer_client_edit');
            });
        slideActions.add(editSlideAction);
        tile.slideActions = slideActions;
        tiles.add(tile);
      }
    }
    this.tiles.value = tiles;
  }

  Future<void> _onRefresh() async {
    await _more();
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    peerClientController.currentIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    var currentIndex = peerClientController.currentIndex;
    var peerClientView = RefreshIndicator(
        onRefresh: _onRefresh,
        //notificationPredicate: _notificationPredicate,
        child: ValueListenableBuilder(
            valueListenable: tiles,
            builder:
                (BuildContext context, List<TileData> tiles, Widget? child) {
              return DataListView(
                  onTap: _onTap,
                  itemCount: tiles.length,
                  itemBuilder: (BuildContext context, int index) {
                    return tiles[index];
                  },
                  currentIndex: currentIndex);
            }));

    var peerClientWidget = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: peerClientView);

    return peerClientWidget;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
