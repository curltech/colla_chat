import 'package:colla_chat/p2p/chain/action/findclient.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';

import '../../../entity/dht/peerclient.dart';
import '../../../l10n/localization.dart';
import '../../../provider/data_list_controller.dart';
import '../../../tool/util.dart';
import '../../../widgets/common/app_bar_view.dart';
import '../../../widgets/common/widget_mixin.dart';
import '../../../widgets/data_bind/data_listview.dart';

///p2p网络节点搜索增加
class P2pLinkmanAddWidget extends StatefulWidget with TileDataMixin {
  final DataListController<TileData> controller =
      DataListController<TileData>();
  late final DataListView dataListView;

  P2pLinkmanAddWidget({Key? key}) : super(key: key) {
    dataListView = DataListView(
      controller: controller,
    );
  }

  @override
  Icon get icon => const Icon(Icons.person_add);

  @override
  String get routeName => 'p2p_linkman_add';

  @override
  String get title => 'P2pLinmkmanAdd';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _P2pLinkmanAddWidgetState();
}

class _P2pLinkmanAddWidgetState extends State<P2pLinkmanAddWidget> {
  var controller = TextEditingController();

  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
    findClientAction.registerResponser('', _receivePeerClients);
  }

  _update() {
    setState(() {});
  }

  _buildSearchTextField(BuildContext context) {
    var searchTextField = TextFormField(
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: AppLocalizations.t('PeerId/Mobile/Email/Name'),
          suffixIcon: IconButton(
            onPressed: () {
              _search(controller.text);
            },
            icon: const Icon(Icons.search),
          ),
        ));

    return searchTextField;
  }

  _receivePeerClients(List<PeerClient>? peerClients) {
    List<TileData> tiles = [];
    if (peerClients != null && peerClients.isNotEmpty) {
      for (var peerClient in peerClients) {
        var title = peerClient.name ?? '';
        var subtitle = peerClient.peerId ?? '';
        TileData tile = TileData(
          title: title,
          subtitle: subtitle,
        );
        tiles.add(tile);
      }
    }
    widget.controller.addAll(tiles);
  }

  Future<void> _search(String key) async {
    String email = '';
    if (key.contains('@')) {
      email = key;
    }
    String mobile = '';
    bool isPhoneNumber = await PhoneNumberUtil.validate(key, '');
    if (isPhoneNumber) {
      mobile = key;
    }
    findClientAction.findClient(key, mobile, email, key);
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: AppLocalizations.instance.text(widget.title),
        child: Column(
            children: [_buildSearchTextField(context), widget.dataListView]));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
