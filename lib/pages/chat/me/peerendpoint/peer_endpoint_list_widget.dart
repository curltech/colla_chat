import 'package:colla_chat/pages/chat/me/peerendpoint/peer_endpoint_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/peerendpoint/peer_endpoint_show_widget.dart';
import 'package:colla_chat/tool/util.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:flutter/material.dart';

import '../../../../constant/address.dart';
import '../../../../entity/dht/peerendpoint.dart';
import '../../../../provider/data_list_controller.dart';
import '../../../../provider/index_widget_provider.dart';
import '../../../../service/dht/peerendpoint.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/data_listview.dart';
import '../../../../widgets/common/widget_mixin.dart';

class PeerEndpointController extends DataListController<PeerEndpoint> {
  PeerEndpointController() {
    init();
  }

  init() {
    PeerEndpointService.instance
        .findAllPeerEndpoint()
        .then((List<PeerEndpoint> peerEndpoints) {
      if (peerEndpoints.isNotEmpty) {
        add(peerEndpoints);
      } else {
        for (var entry in nodeAddressOptions.entries) {
          var nodeAddressOption = entry.value;
          var peerEndpoint = PeerEndpoint();
          peerEndpoint.peerId = nodeAddressOption.connectPeerId;
          peerEndpoint.name = entry.key;
          peerEndpoint.wsConnectAddress = nodeAddressOption.wsConnectAddress;
          peerEndpoint.httpConnectAddress =
              nodeAddressOption.httpConnectAddress;
          peerEndpoint.libp2pConnectAddress =
              nodeAddressOption.libp2pConnectAddress;
          peerEndpoint.iceServers =
              JsonUtil.toJsonString(nodeAddressOption.iceServers);
          PeerEndpointService.instance.insert(peerEndpoint);
          data.add(peerEndpoint);
        }
        notifyListeners();
      }
    });
  }
}

//设置页面，带有回退回调函数
class PeerEndpointListWidget extends StatefulWidget with TileDataMixin {
  final PeerEndpointController controller = PeerEndpointController();
  late final PeerEndpointShowWidget peerEndpointShowWidget;
  late final PeerEndpointEditWidget peerEndpointEditWidget;

  PeerEndpointListWidget({Key? key}) : super(key: key) {
    peerEndpointShowWidget = PeerEndpointShowWidget(controller: controller);
    peerEndpointEditWidget = PeerEndpointEditWidget(controller: controller);
    var indexWidgetProvider = IndexWidgetProvider.instance;
    indexWidgetProvider.define(peerEndpointShowWidget);
    indexWidgetProvider.define(peerEndpointEditWidget);
  }

  @override
  State<StatefulWidget> createState() => _PeerEndpointListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'peerendpoint';

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'PeerEndpoint';
}

class _PeerEndpointListWidgetState extends State<PeerEndpointListWidget> {
  late KeepAliveWrapper dataListView;

  @override
  initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
    var peerEndpoints = widget.controller.data;
    var tiles = _convert(peerEndpoints);
    dataListView =
        KeepAliveWrapper(child: DataListView(onTap: _onTap, tileData: tiles));
  }

  List<TileData> _convert(List<PeerEndpoint> peerEndpoints) {
    List<TileData> tiles = [];
    if (peerEndpoints.isNotEmpty) {
      for (var peerEndpoint in peerEndpoints) {
        var title = peerEndpoint.name ?? '';
        var subtitle = peerEndpoint.peerId ?? '';
        TileData tile = TileData(
            title: title, subtitle: subtitle, routeName: 'peer_endpoint_edit');
        tiles.add(tile);
      }
    }

    return tiles;
  }

  _onTap(int index, String title, {TileData? group}) {
    widget.controller.currentIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    var peerendpointWidget = KeepAliveWrapper(
        child: AppBarView(
            title: widget.title,
            withLeading: widget.withLeading,
            child: dataListView));
    return peerendpointWidget;
  }
}
