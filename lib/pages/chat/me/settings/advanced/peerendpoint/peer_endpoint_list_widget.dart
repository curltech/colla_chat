import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_show_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_transport_widget.dart';

import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/dht/peerendpoint.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

//定位器列表
class PeerEndpointListWidget extends StatefulWidget with TileDataMixin {
  late final List<Widget> rightWidgets;
  late final PeerEndpointShowWidget peerEndpointShowWidget;
  late final PeerEndpointEditWidget peerEndpointEditWidget;
  late final PeerEndpointTransportWidget peerEndpointTransportWidget;

  PeerEndpointListWidget({Key? key}) : super(key: key) {
    peerEndpointShowWidget =
        PeerEndpointShowWidget(controller: peerEndpointController);
    peerEndpointEditWidget =
        PeerEndpointEditWidget(controller: peerEndpointController);
    peerEndpointTransportWidget = PeerEndpointTransportWidget();
    indexWidgetProvider.define(peerEndpointShowWidget);
    indexWidgetProvider.define(peerEndpointEditWidget);
    indexWidgetProvider.define(peerEndpointTransportWidget);
    rightWidgets = [
      IconButton(
          onPressed: () {
            peerEndpointController.init();
          },
          icon: const Icon(Icons.refresh),
          tooltip: AppLocalizations.t('Refresh')),
      IconButton(
          onPressed: () {
            var current = PeerEndpoint(name: '', peerId: '');
            current.state = EntityState.insert;
            peerEndpointController.add(current);
          },
          icon: const Icon(Icons.add),
          tooltip: AppLocalizations.t('Add')),
      IconButton(
          onPressed: () {
            var current = peerEndpointController.current;
            if (current != null) {
              current.state = EntityState.delete;
              peerEndpointService.delete(entity: current);
              peerEndpointController.delete();
            }
          },
          icon: const Icon(Icons.remove),
          tooltip: AppLocalizations.t('Delete')),
      IconButton(
          onPressed: () {
            var current = peerEndpointController.current;
            if (current != null) {
              indexWidgetProvider.push('peer_endpoint_transport');
            }
          },
          icon: const Icon(Icons.light_mode),
          tooltip: AppLocalizations.t('Status')),
    ];
  }

  @override
  State<StatefulWidget> createState() => _PeerEndpointListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'peer_endpoint';

  @override
  Icon get icon => const Icon(Icons.device_hub);

  @override
  String get title => 'PeerEndpoint';
}

class _PeerEndpointListWidgetState extends State<PeerEndpointListWidget> {
  @override
  initState() {
    super.initState();
    peerEndpointController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  List<TileData> _buildTileData() {
    var peerEndpoints = peerEndpointController.data;
    List<TileData> tiles = [];
    if (peerEndpoints.isNotEmpty) {
      for (var peerEndpoint in peerEndpoints) {
        var title = peerEndpoint.name ?? '';
        var subtitle = peerEndpoint.peerId ?? '';
        TileData tile = TileData(
            title: title, subtitle: subtitle, routeName: 'peer_endpoint_edit');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.remove,
            onTap: (int index, String label, {String? subtitle}) async {
              peerEndpointController.currentIndex = index;
              await peerEndpointService.delete(entity: peerEndpoint);
              peerEndpointController.delete();
            });
        slideActions.add(deleteSlideAction);
        TileData editSlideAction = TileData(
            title: 'Edit',
            prefix: Icons.edit,
            onTap: (int index, String label, {String? subtitle}) async {
              peerEndpointController.currentIndex = index;
              indexWidgetProvider.push('peer_endpoint_edit');
            });
        slideActions.add(editSlideAction);
        tile.slideActions = slideActions;
        tiles.add(tile);
      }
    }

    return tiles;
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    peerEndpointController.currentIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    var tiles = _buildTileData();
    var currentIndex = peerEndpointController.currentIndex;
    var dataListView = KeepAliveWrapper(
        child: DataListView(
            onTap: _onTap, tileData: tiles, currentIndex: currentIndex));
    var peerEndpointWidget = AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      rightWidgets: widget.rightWidgets,
      child: dataListView,
    );

    return peerEndpointWidget;
  }

  @override
  void dispose() {
    peerEndpointController.removeListener(_update);
    super.dispose();
  }
}
