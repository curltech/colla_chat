import 'package:colla_chat/pages/chat/me/peerendpoint/peer_endpoint_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/peerendpoint/peer_endpoint_show_widget.dart';
import 'package:colla_chat/tool/util.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:flutter/material.dart';

import '../../../../constant/address.dart';
import '../../../../entity/dht/peerendpoint.dart';
import '../../../../provider/index_widget_provider.dart';
import '../../../../service/dht/peerendpoint.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/data_listview.dart';
import '../../../../widgets/common/widget_mixin.dart';

class PeerEndpointController with ChangeNotifier {
  final List<PeerEndpoint> _peerEndpoints = [];

  int _currentIndex = 0;

  PeerEndpointController() {
    init();
  }

  List<PeerEndpoint> get peerEndpoints {
    return _peerEndpoints;
  }

  init() {
    PeerEndpointService.instance.findAllPeerEndpoint().then((peerEndpoints) {
      if (peerEndpoints.isNotEmpty) {
        _peerEndpoints.addAll(peerEndpoints);
        notifyListeners();
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
          _peerEndpoints.add(peerEndpoint);
        }
        notifyListeners();
      }
    });
  }

  int get currentIndex {
    return _currentIndex;
  }

  PeerEndpoint? get currentPeerEndpoint {
    return _peerEndpoints[_currentIndex];
  }

  set currentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  add(List<PeerEndpoint> peerEndpoints) {
    _peerEndpoints.addAll(peerEndpoints);
    notifyListeners();
  }
}

class PeerEndpointTileDataConvertMixin with TileDataConvertMixin {
  List<PeerEndpoint> peerEndpoints;

  PeerEndpointTileDataConvertMixin({required this.peerEndpoints});

  @override
  TileData getTileData(int index) {
    PeerEndpoint peerEndpoint = peerEndpoints[index];
    var title = peerEndpoint.name ?? '';
    var subTitle = peerEndpoint.peerId ?? '';
    TileData tile = TileData(
        title: title, subtitle: subTitle, routeName: 'peer_endpoint_show');

    return tile;
  }

  @override
  bool add(List<TileData> tiles) {
    return false;
  }

  @override
  int get length => peerEndpoints.length;
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
  @override
  initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  _onTap(int index, String title, {TileData? group}) {
    widget.controller.currentIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    var peerEndpoints = widget.controller.peerEndpoints;
    var peerEndpointTileDataConvertMixin =
        PeerEndpointTileDataConvertMixin(peerEndpoints: peerEndpoints);
    var dataListView = KeepAliveWrapper(
        child: DataListView(
            onTap: _onTap, tileDataMix: peerEndpointTileDataConvertMixin));
    var peerendpointWidget = KeepAliveWrapper(
        child: AppBarView(
            title: widget.title,
            withLeading: widget.withLeading,
            child: dataListView));
    return peerendpointWidget;
  }
}
