import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/p2p/chain/action/ping.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_view_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/dht/peerendpoint.dart';
import 'package:colla_chat/transport/httpclient.dart';
import 'package:colla_chat/transport/websocket/common_websocket.dart';
import 'package:colla_chat/transport/websocket/universal_websocket.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

//定位器列表
class PeerEndpointListWidget extends StatelessWidget with TileDataMixin {
  late final List<Widget> rightWidgets;
  late final PeerEndpointViewWidget peerEndpointViewWidget;
  late final PeerEndpointEditWidget peerEndpointEditWidget;

  PeerEndpointListWidget({super.key}) {
    peerEndpointViewWidget =
        PeerEndpointViewWidget(peerEndpointController: peerEndpointController);
    peerEndpointEditWidget =
        PeerEndpointEditWidget(peerEndpointController: peerEndpointController);
    indexWidgetProvider.define(peerEndpointViewWidget);
    indexWidgetProvider.define(peerEndpointEditWidget);
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
    ];
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'peer_endpoint';

  @override
  IconData get iconData => Icons.device_hub;

  @override
  String get title => 'PeerEndpoint';

  

  var red = const Icon(
    Icons.light_mode,
    color: Colors.red,
  );
  var green = const Icon(
    Icons.light_mode,
    color: Colors.green,
  );
  var grey = const Icon(
    Icons.light_mode,
    color: Colors.grey,
  );

  Future<Icon> _httpLight() async {
    PeerEndpoint? peerEndpoint = peerEndpointController.current;
    if (peerEndpoint == null) {
      return grey;
    }
    Icon httpLight = grey;
    if (peerEndpoint.httpConnectAddress != null) {
      DioHttpClient? dioHttpClient =
          httpClientPool.get(peerEndpoint.httpConnectAddress!);
      try {
        dio.Response<dynamic> response = await dioHttpClient.get('\\');
        if (response.statusCode != 200) {
          httpLight = green;
        } else {
          httpLight = red;
        }
      } catch (e) {
        return httpLight;
      }
    }
    return httpLight;
  }

  Future<Icon> _wsLight() async {
    PeerEndpoint? peerEndpoint = peerEndpointController.current;
    if (peerEndpoint == null) {
      return grey;
    }
    Icon wsLight;
    if (peerEndpoint.wsConnectAddress == null) {
      wsLight = grey;
    } else {
      UniversalWebsocket? websocket =
          await websocketPool.get(peerEndpoint.wsConnectAddress!);
      if (websocket == null) {
        wsLight = grey;
      } else {
        if (websocket.status == SocketStatus.connected) {
          wsLight = green;
        } else {
          wsLight = red;
        }
      }
    }
    return wsLight;
  }

  Future<Icon> _libp2pLight() async {
    PeerEndpoint? peerEndpoint = peerEndpointController.current;
    if (peerEndpoint == null) {
      return grey;
    }
    Icon libp2pLight;
    if (peerEndpoint.libp2pConnectAddress == null) {
      libp2pLight = grey;
    } else {
      var response =
          await pingAction.ping('hello', targetPeerId: peerEndpoint.peerId);
      if (response) {
        libp2pLight = red;
      } else {
        libp2pLight = green;
      }
    }
    return libp2pLight;
  }

  List<TileData> _buildTileData() {
    var peerEndpoints = peerEndpointController.data;
    List<TileData> tiles = [];
    if (peerEndpoints.isNotEmpty) {
      int i = 0;
      for (var peerEndpoint in peerEndpoints) {
        var title = peerEndpoint.name;
        var subtitle = peerEndpoint.peerId;
        TileData tile = TileData(
            selected: peerEndpointController.currentIndex.value == i,
            title: title,
            subtitle: subtitle,
            routeName: 'peer_endpoint_edit');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.remove,
            onTap: (int index, String label, {String? subtitle}) async {
              peerEndpointController.setCurrentIndex = index;
              peerEndpointService.delete(entity: peerEndpoint);
              peerEndpointController.delete();
            });
        slideActions.add(deleteSlideAction);
        TileData editSlideAction = TileData(
            title: 'Edit',
            prefix: Icons.edit,
            onTap: (int index, String label, {String? subtitle}) async {
              peerEndpointController.setCurrentIndex = index;
              indexWidgetProvider.push('peer_endpoint_edit');
            });
        slideActions.add(editSlideAction);
        TileData statusSlideAction = TileData(
            title: 'Status',
            prefix: Icons.light_mode,
            onTap: (int index, String label, {String? subtitle}) async {
              var current = peerEndpointController.current;
              if (current != null) {
                indexWidgetProvider.push('peer_endpoint_transport');
              }
            });
        slideActions.add(statusSlideAction);
        tile.slideActions = slideActions;

        List<TileData> endSlideActions = [];
        TileData wsConnectSlideAction = TileData(
            title: 'WsConnect',
            prefix: Icons.private_connectivity_outlined,
            onTap: (int index, String label, {String? subtitle}) async {
              _wsLight();
            });
        endSlideActions.add(wsConnectSlideAction);
        tile.endSlideActions = endSlideActions;

        tiles.add(tile);
        i++;
      }
    }

    return tiles;
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    peerEndpointController.setCurrentIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    Widget dataListView = Obx(() {
      var tiles = _buildTileData();
      var dataListView = DataListView(
        onTap: _onTap,
        itemCount: tiles.length,
        itemBuilder: (BuildContext context, int index) {
          return tiles[index];
        },
      );
      return dataListView;
    });
    Widget peerEndpointWidget = AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: withLeading,
      rightWidgets: rightWidgets,
      child: dataListView,
    );

    return peerEndpointWidget;
  }
}
