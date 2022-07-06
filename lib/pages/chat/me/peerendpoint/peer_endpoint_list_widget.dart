import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/pages/chat/me/peerendpoint/peer_endpoint_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/peerendpoint/peer_endpoint_show_widget.dart';
import 'package:colla_chat/tool/util.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:flutter/material.dart';

import '../../../../constant/address.dart';
import '../../../../entity/dht/peerendpoint.dart';
import '../../../../l10n/localization.dart';
import '../../../../provider/app_data_provider.dart';
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
    peerEndpointService
        .findAllPeerEndpoint()
        .then((List<PeerEndpoint> peerEndpoints) {
      if (peerEndpoints.isNotEmpty) {
        addAll(peerEndpoints);
      } else {
        for (var entry in nodeAddressOptions.entries) {
          var nodeAddressOption = entry.value;
          var peerEndpoint = PeerEndpoint(myself.peerId ?? '');
          peerEndpoint.peerId = nodeAddressOption.connectPeerId;
          peerEndpoint.name = entry.key;
          peerEndpoint.wsConnectAddress = nodeAddressOption.wsConnectAddress;
          peerEndpoint.httpConnectAddress =
              nodeAddressOption.httpConnectAddress;
          peerEndpoint.libp2pConnectAddress =
              nodeAddressOption.libp2pConnectAddress;
          peerEndpoint.iceServers =
              JsonUtil.toJsonString(nodeAddressOption.iceServers);
          peerEndpointService.insert(peerEndpoint);
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
  late final List<Widget> rightWidgets;
  late final PeerEndpointShowWidget peerEndpointShowWidget;
  late final PeerEndpointEditWidget peerEndpointEditWidget;

  PeerEndpointListWidget({Key? key}) : super(key: key) {
    peerEndpointShowWidget = PeerEndpointShowWidget(controller: controller);
    peerEndpointEditWidget = PeerEndpointEditWidget(controller: controller);
    var indexWidgetProvider = IndexWidgetProvider.instance;
    indexWidgetProvider.define(peerEndpointShowWidget);
    indexWidgetProvider.define(peerEndpointEditWidget);
    rightWidgets = [
      IconButton(
          onPressed: () {
            controller.add(PeerEndpoint(myself.peerId ?? ''));
          },
          icon: const Icon(Icons.add),
          tooltip: AppLocalizations.t('Add')),
      IconButton(
          onPressed: () {
            var current = controller.current;
            peerEndpointService.delete(current);
            controller.delete();
          },
          icon: const Icon(Icons.delete),
          tooltip: AppLocalizations.t('Delete')),
    ];
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
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
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
    var peerEndpoints = widget.controller.data;
    var tiles = _convert(peerEndpoints);
    var currentIndex = widget.controller.currentIndex;
    var dataListView = KeepAliveWrapper(
        child: DataListView(
            onTap: _onTap, tileData: tiles, currentIndex: currentIndex));
    var peerendpointWidget = AppBarView(
      title: widget.title,
      withLeading: widget.withLeading,
      rightWidgets: widget.rightWidgets,
      child: dataListView,
    );
    return peerendpointWidget;
  }

  @override
  void dispose() {
    logger.w('PeerEndpointListWidget dispose');
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
