import 'package:colla_chat/pages/chat/me/peerclient/peer_client_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/peerclient/peer_client_show_widget.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/pluto_data_grid_widget.dart';
import 'package:flutter/material.dart';

import '../../../../datastore/datastore.dart';
import '../../../../entity/base.dart';
import '../../../../entity/dht/myself.dart';
import '../../../../entity/dht/peerclient.dart';
import '../../../../l10n/localization.dart';
import '../../../../provider/data_list_controller.dart';
import '../../../../provider/index_widget_provider.dart';
import '../../../../service/dht/peerclient.dart';
import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/data_listtile.dart';
import '../../../../widgets/common/widget_mixin.dart';

class PeerClientDataPageController extends DataPageController<PeerClient> {
  PeerClientDataPageController() : super();

  _findPage(int offset, int limit) {
    peerClientService
        .findPage(limit: limit, offset: offset)
        .then((Pagination<PeerClient> page) {
      pagination = page;
      if (page.data.isNotEmpty) {
        setCurrentIndex(0, listen: false);
      }
      notifyListeners();
    });
  }

  @override
  bool first() {
    if (pagination.rowsNumber != -1 && pagination.offset == 0) {
      return false;
    }
    var offset = 0;
    var limit = pagination.rowsPerPage;
    _findPage(offset, limit);

    return true;
  }

  @override
  bool last() {
    var limit = this.limit;
    var offset = pagination.rowsNumber - limit;
    if (offset < 0) {
      offset = 0;
    }
    if (offset > pagination.rowsNumber) {
      return false;
    }
    _findPage(offset, limit);
    return true;
  }

  @override
  bool move(int index) {
    if (index >= pagination.rowsNumber) {
      return false;
    }
    var limit = this.limit;
    var offset = index ~/ limit * limit;
    _findPage(offset, limit);
    return true;
  }

  @override
  bool next() {
    var limit = this.limit;
    var offset = pagination.offset + limit;
    if (offset > pagination.rowsNumber) {
      return false;
    }
    _findPage(offset, limit);
    return true;
  }

  @override
  bool previous() {
    var limit = this.limit;
    var offset = pagination.offset - limit;
    if (offset < 0) {
      return false;
    }
    _findPage(offset, limit);
    return true;
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
            var current = PeerClient(myself.peerId ?? '');
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
              peerClientService.delete(current);
              controller.delete();
            }
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
  String get routeName => 'peer_client';

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
    widget.controller.setCurrentIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    KeepAliveWrapper<PlutoDataGridWidget> dataTableView = KeepAliveWrapper(
        child: PlutoDataGridWidget<PeerClient>(
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
