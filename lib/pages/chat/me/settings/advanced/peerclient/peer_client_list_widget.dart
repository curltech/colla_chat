import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_controller.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_view_widget.dart';

import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//设置页面，带有回退回调函数
class PeerClientListWidget extends StatefulWidget with TileDataMixin {
  late final List<Widget> rightWidgets;
  late final PeerClientViewWidget peerClientViewWidget;
  late final PeerClientEditWidget peerClientEditWidget;

  PeerClientListWidget({Key? key}) : super(key: key) {
    peerClientViewWidget =
        PeerClientViewWidget(controller: peerClientDataPageController);
    peerClientEditWidget =
        PeerClientEditWidget(controller: peerClientDataPageController);
    indexWidgetProvider.define(peerClientViewWidget);
    indexWidgetProvider.define(peerClientEditWidget);

    rightWidgets = [
      IconButton(
          onPressed: () {
            peerClientDataPageController.first();
          },
          icon: const Icon(Icons.first_page),
          tooltip: AppLocalizations.t('First')),
      IconButton(
          onPressed: () {
            peerClientDataPageController.previous();
          },
          icon: const Icon(Icons.navigate_before),
          tooltip: AppLocalizations.t('Previous')),
      IconButton(
          onPressed: () {
            peerClientDataPageController.next();
          },
          icon: const Icon(Icons.navigate_next),
          tooltip: AppLocalizations.t('Next')),
      IconButton(
          onPressed: () {
            peerClientDataPageController.last();
          },
          icon: const Icon(Icons.last_page),
          tooltip: AppLocalizations.t('Last')),
      IconButton(
          onPressed: () {
            var current = PeerClient('', '', '');
            current.state = EntityState.insert;
            peerClientDataPageController.add(current);
          },
          icon: const Icon(Icons.add),
          tooltip: AppLocalizations.t('Add')),
      IconButton(
          onPressed: () {
            var current = peerClientDataPageController.current;
            if (current != null) {
              current.state = EntityState.delete;
              peerClientService.delete(entity: current);
              peerClientDataPageController.delete();
            }
          },
          icon: const Icon(Icons.remove),
          tooltip: AppLocalizations.t('Delete')),
    ];
  }

  @override
  State<StatefulWidget> createState() => _PeerClientListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'peer_client';

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'PeerClient';
}

class _PeerClientListWidgetState extends State<PeerClientListWidget> {
  @override
  initState() {
    super.initState();
    peerClientDataPageController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  List<TileData> _buildTileData() {
    List<PeerClient> peerClients = peerClientDataPageController.pagination.data;
    List<TileData> tiles = [];
    if (peerClients.isNotEmpty) {
      for (var peerClient in peerClients) {
        var title = peerClient.name ?? '';
        var subtitle = peerClient.peerId ?? '';
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
              peerClientDataPageController.currentIndex = index;
              await peerClientService.delete(entity: peerClient);
              peerClientDataPageController.delete();
            });
        slideActions.add(deleteSlideAction);
        TileData editSlideAction = TileData(
            title: 'Edit',
            prefix: Icons.edit,
            onTap: (int index, String label, {String? subtitle}) async {
              peerClientDataPageController.currentIndex = index;
              indexWidgetProvider.push('peer_client_edit');
            });
        slideActions.add(editSlideAction);
        tile.slideActions = slideActions;
        tiles.add(tile);
      }
    }

    return tiles;
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    peerClientDataPageController.currentIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    var tiles = _buildTileData();
    var currentIndex = peerClientDataPageController.currentIndex;
    var dataListView = KeepAliveWrapper(
        child: DataListView(
            onTap: _onTap, tileData: tiles, currentIndex: currentIndex));

    var peerClientWidget = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        rightWidgets: widget.rightWidgets,
        child: dataListView);

    return peerClientWidget;
  }

  @override
  void dispose() {
    peerClientDataPageController.removeListener(_update);
    super.dispose();
  }
}
