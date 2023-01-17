import 'package:colla_chat/constant/address.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_show_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/dht/peerendpoint.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

// 定位器，初始化后按照优先级排序
class PeerEndpointController extends DataListController<PeerEndpoint> {
  int _defaultIndex = 0;

  PeerEndpointController() {
    init();
  }

  PeerEndpoint? get defaultPeerEndpoint {
    if (_defaultIndex > -1) {
      return data[_defaultIndex];
    }
    return null;
  }

  int? get defaultIndex {
    return _defaultIndex;
  }

  set defaultIndex(int? defaultIndex) {
    if (defaultIndex != null && defaultIndex > -1) {
      _defaultIndex = defaultIndex;
      notifyListeners();
    }
  }

  init() {
    peerEndpointService
        .findAllPeerEndpoint()
        .then((List<PeerEndpoint> peerEndpoints) {
      clear();
      if (peerEndpoints.isNotEmpty) {
        addAll(peerEndpoints);
      } else {
        for (var peerEndpoint in nodeAddressOptions.values) {
          peerEndpointService.insert(peerEndpoint);
          data.add(peerEndpoint);
        }
        notifyListeners();
      }
    });
  }
}

final PeerEndpointController peerEndpointController = PeerEndpointController();

//设置页面，带有回退回调函数
class PeerEndpointListWidget extends StatefulWidget with TileDataMixin {
  late final List<Widget> rightWidgets;
  late final PeerEndpointShowWidget peerEndpointShowWidget;
  late final PeerEndpointEditWidget peerEndpointEditWidget;

  PeerEndpointListWidget({Key? key}) : super(key: key) {
    peerEndpointShowWidget =
        PeerEndpointShowWidget(controller: peerEndpointController);
    peerEndpointEditWidget =
        PeerEndpointEditWidget(controller: peerEndpointController);
    indexWidgetProvider.define(peerEndpointShowWidget);
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
            var current = PeerEndpoint('', peerId: '');
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

  List<TileData> _convertTileData() {
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
    var tiles = _convertTileData();
    var currentIndex = peerEndpointController.currentIndex;
    var dataListView = KeepAliveWrapper(
        child: DataListView(
            onTap: _onTap, tileData: tiles, currentIndex: currentIndex));
    var peerEndpointWidget = AppBarView(
      title: Text(AppLocalizations.t(widget.title)),
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
