import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/p2p/chain/action/findclient.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/tool/validator_util.dart';
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
  Icon get icon => const Icon(Icons.add_link);

  @override
  String get routeName => 'p2p_linkman_add';

  @override
  String get title => 'P2p add linkman';

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
    findClientAction.registerResponsor(_responsePeerClients);
  }

  _update() {
    setState(() {});
  }

  _buildSearchTextField(BuildContext context) {
    var searchTextField = TextFormField(
        controller: controller,
        keyboardType: TextInputType.text,
        validator: (value) {
          return ValidatorUtil.emptyValidator(value);
        },
        decoration: InputDecoration(
          labelText: AppLocalizations.t('PeerId/Mobile/Email/Name'),
          suffixIcon: IconButton(
            onPressed: () {
              _search(controller.text);
            },
            icon: const Icon(Icons.search),
          ),
        ));

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: searchTextField);
  }

  Future<void> _responsePeerClients(ChainMessage chainMessage) async {
    if (chainMessage.payloadType == PayloadType.peerClients.name) {
      List<PeerClient> peerClients = chainMessage.payload;
      if (peerClients.isNotEmpty) {
        for (var peerClient in peerClients) {
          await peerClientService.store(peerClient,
              mobile: false, email: false);
        }
      }

      List<TileData> tiles = [];
      if (peerClients.isNotEmpty) {
        for (var peerClient in peerClients) {
          var title = peerClient.name;
          var peerId = peerClient.peerId;
          Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
          bool isStranger = false;
          if (linkman != null &&
              linkman.status == LinkmanStatus.stranger.name) {
            isStranger = true;
          }
          Widget suffix = Text(AppLocalizations.t(linkman!.status!));
          if (isStranger) {
            suffix = IconButton(
              iconSize: 24.0,
              icon: const Icon(Icons.person_add),
              onPressed: () async {
                Linkman linkman =
                    await linkmanService.storeByPeerClient(peerClient);
                await linkmanService.update({
                  'id': linkman.id,
                  'status': LinkmanStatus.friend.name
                }).then((value) {
                  DialogUtil.info(context,
                      content:
                          AppLocalizations.t('Add peerClient as linkman:') +
                              peerId);
                });
              },
            );
          }
          TileData tile =
              TileData(title: title, subtitle: peerId, suffix: suffix);
          tiles.add(tile);
        }
      }
      widget.controller.replaceAll(tiles);
    }
  }

  Future<void> _search(String key) async {
    String? error = ValidatorUtil.emptyValidator(key);
    if (error != null) {
      DialogUtil.error(context, content: error);
      return;
    }
    String email = '';
    error = ValidatorUtil.emailValidator(key);
    if (error == null) {
      email = key;
    }
    String mobile = '';
    error = ValidatorUtil.mobileValidator(key);
    if (error == null) {
      mobile = key;
    }
    await findClientAction.findClient(key, mobile, email, key);
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
    findClientAction.unregisterResponsor(_responsePeerClients);
    super.dispose();
  }
}
