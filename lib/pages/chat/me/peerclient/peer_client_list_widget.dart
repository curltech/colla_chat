import 'package:colla_chat/pages/chat/me/peerclient/peer_client_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/peerclient/peer_client_show_widget.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:flutter/material.dart';

import '../../../../entity/dht/myself.dart';
import '../../../../entity/dht/peerclient.dart';
import '../../../../l10n/localization.dart';
import '../../../../provider/data_list_controller.dart';
import '../../../../provider/index_widget_provider.dart';
import '../../../../service/dht/peerclient.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/data_table_view.dart';
import '../../../../widgets/common/widget_mixin.dart';

class PeerClientDataPageController extends DataPageController<PeerClient> {
  @override
  void first() {
    PeerClientService.instance.findPage();
  }

  @override
  void last() {
    // TODO: implement last
  }

  @override
  void move(int index) {
    // TODO: implement move
  }

  @override
  void next() {
    // TODO: implement next
  }

  @override
  void previous() {
    // TODO: implement previous
  }
}

//设置页面，带有回退回调函数
class PeerClientListWidget extends StatefulWidget with TileDataMixin {
  final DataPageController<PeerClient> controller =
      PeerClientDataPageController();
  late final List<Widget> rightWidgets;
  late final PeerClientShowWidget peerClientShowWidget;
  late final PeerClientEditWidget peerClientEditWidget;

  PeerClientListWidget({Key? key}) : super(key: key) {
    peerClientShowWidget = PeerClientShowWidget(controller: controller);
    peerClientEditWidget = PeerClientEditWidget(controller: controller);
    var indexWidgetProvider = IndexWidgetProvider.instance;
    indexWidgetProvider.define(peerClientShowWidget);
    indexWidgetProvider.define(peerClientEditWidget);

    rightWidgets = [
      IconButton(
          onPressed: () {
            controller.add(PeerClient(myself.peerId ?? ''));
          },
          icon: const Icon(Icons.add),
          tooltip: AppLocalizations.t('Add')),
      IconButton(
          onPressed: () {
            var current = controller.current;
            PeerClientService.instance.delete(current);
            controller.delete();
          },
          icon: const Icon(Icons.delete),
          tooltip: AppLocalizations.t('Delete')),
    ];
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
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
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
    KeepAliveWrapper<DataTableView> dataTableView = KeepAliveWrapper(
        child: DataTableView<PeerClient>(
      columnDefs: peerClientColumnFieldDefs,
      controller: widget.controller,
      routeName: 'peer_client_edit',
    ));

    var peerclientWidget = KeepAliveWrapper(
        child: AppBarView(
            title: widget.title,
            withLeading: widget.withLeading,
            rightWidgets: widget.rightWidgets,
            child: dataTableView));
    return peerclientWidget;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
