import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/p2p/chain/action/findclient.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

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
    findClientAction.registerResponser(_responsePeerClients);
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

  Future<void> _responsePeerClients(ChainMessage chainMessage) async {
    if (chainMessage.payloadType == PayloadType.peerClients.name) {
      List<PeerClient> peerClients = chainMessage.payload;
      if (peerClients.isNotEmpty) {
        for (var peerClient in peerClients) {
          peerClientService.store(peerClient);
        }
      }

      List<TileData> tiles = [];
      if (peerClients.isNotEmpty) {
        for (var peerClient in peerClients) {
          var title = peerClient.name ?? '';
          var subtitle = peerClient.peerId ?? '';
          TileData tile = TileData(
              title: title,
              subtitle: subtitle,
              suffix: IconButton(
                iconSize: 24.0,
                icon: const Icon(Icons.add),
                onPressed: () {
                  logger.i('add peerClient:$subtitle as linkman');
                  linkmanService.addLinkman(peerClient);
                },
              ));
          tiles.add(tile);
        }
      }
      widget.controller.replaceAll(tiles);
    }
  }

  Future<void> _search(String key) async {
    String email = '';
    if (key.contains('@')) {
      email = key;
    }
    String mobile = '';
    bool isPhoneNumber = StringUtil.isNumeric(key);
    if (isPhoneNumber) {
      mobile = key;
    }
    findClientAction.findClient(key, mobile, email, key);
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: Text(AppLocalizations.t(widget.title)),
        child: Column(
            children: [_buildSearchTextField(context), widget.dataListView]));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    controller.dispose();
    super.dispose();
  }
}
