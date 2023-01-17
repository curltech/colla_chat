import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/base.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_edit_widget.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerclient/peer_client_show_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

class PeerClientDataPageController extends DataPageController<PeerClient> {
  PeerClientDataPageController() : super();

  Future<Pagination<PeerClient>> _findPage(int offset, int limit) async {
    Pagination<PeerClient> page =
        await peerClientService.findPage(limit: limit, offset: offset);
    pagination = page;
    if (page.data.isNotEmpty) {
      currentIndex = 0;
    }
    notifyListeners();
    return page;
  }

  @override
  Future<bool> first() async {
    if (pagination.rowsNumber != -1 && pagination.offset == 0) {
      return false;
    }
    var offset = 0;
    var limit = pagination.rowsPerPage;
    await _findPage(offset, limit);

    return true;
  }

  @override
  Future<bool> last() async {
    var limit = this.limit;
    var offset = pagination.rowsNumber - limit;
    if (offset < 0) {
      offset = 0;
    }
    if (offset > pagination.rowsNumber) {
      return false;
    }
    await _findPage(offset, limit);
    return true;
  }

  @override
  Future<bool> move(int index) async {
    if (index >= pagination.rowsNumber) {
      return false;
    }
    var limit = this.limit;
    var offset = index ~/ limit * limit;
    await _findPage(offset, limit);
    return true;
  }

  @override
  Future<bool> next() async {
    var limit = this.limit;
    var offset = pagination.offset + limit;
    if (offset > pagination.rowsNumber) {
      return false;
    }
    await _findPage(offset, limit);
    return true;
  }

  @override
  Future<bool> previous() async {
    var limit = this.limit;
    var offset = pagination.offset - limit;
    if (offset < 0) {
      return false;
    }
    await _findPage(offset, limit);
    return true;
  }
}

final DataPageController<PeerClient> peerClientDataPageController =
    PeerClientDataPageController();

//设置页面，带有回退回调函数
class PeerClientListWidget extends StatefulWidget with TileDataMixin {
  late final List<Widget> rightWidgets;
  late final PeerClientShowWidget peerClientShowWidget;
  late final PeerClientEditWidget peerClientEditWidget;

  PeerClientListWidget({Key? key}) : super(key: key) {
    peerClientShowWidget =
        PeerClientShowWidget(controller: peerClientDataPageController);
    peerClientEditWidget =
        PeerClientEditWidget(controller: peerClientDataPageController);
    indexWidgetProvider.define(peerClientShowWidget);
    indexWidgetProvider.define(peerClientEditWidget);

    rightWidgets = [
      IconButton(
          onPressed: () {
            peerClientDataPageController.first();
          },
          icon: const Icon(Icons.refresh),
          tooltip: AppLocalizations.t('Refresh')),
      IconButton(
          onPressed: () {
            var current = PeerClient('', '', '');
            current.state = EntityState.insert;
            peerClientDataPageController.add(current);
          },
          icon: const Icon(Icons.add),
          tooltip: AppLocalizations.t('Add')),
      IconButton(
          onPressed: () {
            var current = peerClientDataPageController.current;
            if (current != null) {
              current.state = EntityState.delete;
              peerClientService.delete(entity: current);
              peerClientDataPageController.delete();
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
    peerClientDataPageController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  List<TileData> _convertTileData() {
    List<PeerClient> peerClients = peerClientDataPageController.pagination.data;
    List<TileData> tiles = [];
    if (peerClients.isNotEmpty) {
      for (var peerClient in peerClients) {
        var title = peerClient.name ?? '';
        var subtitle = peerClient.peerId ?? '';
        TileData tile = TileData(
            prefix: peerClient.avatarImage,
            title: title,
            subtitle: subtitle,
            routeName: 'peer_client_edit');
        List<TileData> slideActions = [];
        TileData deleteSlideAction = TileData(
            title: 'Delete',
            prefix: Icons.delete,
            onTap: (int index, String label, {String? subtitle}) async {
              peerClientDataPageController.currentIndex = index;
              await peerClientService.delete(entity: peerClient);
              peerClientDataPageController.delete();
            });
        slideActions.add(deleteSlideAction);
        // TileData editSlideAction = TileData(
        //     title: 'Edit',
        //     prefix: Icons.edit,
        //     onTap: (int index, String label, {String? subtitle}) async {
        //       peerClientDataPageController.currentIndex = index;
        //       indexWidgetProvider.push('peer_client_edit');
        //     });
        // slideActions.add(editSlideAction);
        tile.slideActions = slideActions;
        tiles.add(tile);
      }
    }

    return tiles;
  }

  _onTap(int index, String title, {String? subtitle, TileData? group}) {
    peerClientDataPageController.currentIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    var tiles = _convertTileData();
    var currentIndex = peerClientDataPageController.currentIndex;
    var dataListView = KeepAliveWrapper(
        child: DataListView(
            onTap: _onTap, tileData: tiles, currentIndex: currentIndex));

    var peerClientWidget = AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        withLeading: widget.withLeading,
        rightWidgets: widget.rightWidgets,
        child: dataListView);

    return peerClientWidget;
  }

  @override
  void dispose() {
    peerClientDataPageController.removeListener(_update);
    super.dispose();
  }
}
