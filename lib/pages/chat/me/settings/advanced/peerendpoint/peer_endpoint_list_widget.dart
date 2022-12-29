import 'package:colla_chat/constant/address.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_show_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/dht/peerendpoint.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';


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
          var peerEndpoint = PeerEndpoint('', '');
          peerEndpoint.peerId = nodeAddressOption.connectPeerId!;
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
    indexWidgetProvider.define(peerEndpointShowWidget);
    indexWidgetProvider.define(peerEndpointEditWidget);
    rightWidgets = [
      IconButton(
          onPressed: () {
            var current = PeerEndpoint('', '');
            current.state = EntityState.insert;
            controller.add(current);
          },
          icon: const Icon(Icons.add),
          tooltip: AppLocalizations.t('Add')),
      IconButton(
          onPressed: () {
            var current = controller.current;
            if (current != null) {
              current.state = EntityState.delete;
              peerEndpointService.delete(entity: current);
              controller.delete();
            }
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

  _onTap(int index, String title, {String? subtitle,TileData? group}) {
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
      title: Text(AppLocalizations.t(widget.title)),
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
