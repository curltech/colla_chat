import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/p2p/chain/action/ping.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';

import 'package:colla_chat/transport/httpclient.dart';
import 'package:colla_chat/transport/websocket.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

//定位器连接性测试
class PeerEndpointTransportWidget extends StatefulWidget with TileDataMixin {
  PeerEndpointTransportWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PeerEndpointTransportWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'peer_endpoint_transport';

  @override
  Icon get icon => const Icon(Icons.private_connectivity);

  @override
  String get title => 'PeerEndpointTransport';
}

class _PeerEndpointTransportWidgetState
    extends State<PeerEndpointTransportWidget> {
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
  late PeerEndpoint peerEndpoint;

  @override
  initState() {
    super.initState();
    peerEndpoint = peerEndpointController.current!;
  }

  Future<Icon> _httpLight() async {
    Icon httpLight = grey;
    if (peerEndpoint.httpConnectAddress != null) {
      DioHttpClient? dioHttpClient =
          HttpClientPool.instance.get(peerEndpoint.httpConnectAddress!);
      if (dioHttpClient == null) {
        httpLight = grey;
      } else {
        try {
          Response<dynamic> response = await dioHttpClient.get('\\');
          if (response.statusCode != 200) {
            httpLight = green;
          } else {
            httpLight = red;
          }
        } catch (e) {
          return httpLight;
        }
      }
    }
    return httpLight;
  }

  Future<Icon> _wsLight() async {
    Icon wsLight;
    if (peerEndpoint.wsConnectAddress == null) {
      wsLight = grey;
    } else {
      Websocket? websocket =
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
    Icon libp2pLight;
    if (peerEndpoint.libp2pConnectAddress == null) {
      libp2pLight = grey;
    } else {
      var response = await pingAction.ping('hello', peerEndpoint.peerId);
      if (response == null) {
        libp2pLight = red;
      } else {
        libp2pLight = green;
      }
    }
    return libp2pLight;
  }

  _update() {
    setState(() {});
  }

  Future<List<TileData>> _buildTileData() async {
    List<TileData> tiles = [];
    // TileData tile = TileData(
    //     prefix: await _httpLight(),
    //     title: peerEndpoint.httpConnectAddress ?? '');
    // tiles.add(tile);
    TileData tile = TileData(
        prefix: await _wsLight(), title: peerEndpoint.wsConnectAddress ?? '');
    tiles.add(tile);
    // tile = TileData(
    //     prefix: await _libp2pLight(),
    //     title: peerEndpoint.libp2pConnectAddress ?? '');
    // tiles.add(tile);

    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    var dataListView = FutureBuilder(
        future: _buildTileData(),
        builder:
            (BuildContext context, AsyncSnapshot<List<TileData>> snapshot) {
          if (snapshot.hasData) {
            var tiles = snapshot.data;
            if (tiles != null) {
              return DataListView(tileData: tiles);
            }
          }
          return Container();
        });
    var peerEndpointWidget = AppBarView(
      title: Text(AppLocalizations.t(widget.title)),
      withLeading: widget.withLeading,
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
