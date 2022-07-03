import 'package:colla_chat/pages/chat/me/peerclient/peer_client_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/peerclient/peer_client_show_widget.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:flutter/material.dart';

import '../../../../entity/dht/peerclient.dart';
import '../../../../provider/data_list_controller.dart';
import '../../../../provider/index_widget_provider.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/data_listview.dart';
import '../../../../widgets/common/widget_mixin.dart';

//设置页面，带有回退回调函数
class PeerClientListWidget extends StatefulWidget with TileDataMixin {
  final DataListController<PeerClient> controller =
      DataListController<PeerClient>();
  late final PeerClientShowWidget peerClientShowWidget;
  late final PeerClientEditWidget peerClientEditWidget;

  PeerClientListWidget({Key? key}) : super(key: key) {
    peerClientShowWidget = PeerClientShowWidget(controller: controller);
    peerClientEditWidget = PeerClientEditWidget(controller: controller);
    var indexWidgetProvider = IndexWidgetProvider.instance;
    indexWidgetProvider.define(peerClientShowWidget);
    indexWidgetProvider.define(peerClientEditWidget);
  }

  @override
  State<StatefulWidget> createState() => _PeerClientListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'peerclient';

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'PeerClient';
}

class _PeerClientListWidgetState extends State<PeerClientListWidget> {
  late KeepAliveWrapper<DataListView> dataListView;

  @override
  initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
    var peerClients = widget.controller.data;
    var tiles = _convert(peerClients);
    dataListView =
        KeepAliveWrapper(child: DataListView(onTap: _onTap, tileData: tiles));
  }

  List<TileData> _convert(List<PeerClient> peerClients) {
    List<TileData> tiles = [];
    if (peerClients.isNotEmpty) {
      for (var peerClient in peerClients) {
        var title = peerClient.name ?? '';
        var subtitle = peerClient.peerId ?? '';
        TileData tile = TileData(
            title: title, subtitle: subtitle, routeName: 'peer_client_edit');
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
    var peerclientWidget = KeepAliveWrapper(
        child: AppBarView(
            title: widget.title,
            withLeading: widget.withLeading,
            child: dataListView));
    return peerclientWidget;
  }
}
