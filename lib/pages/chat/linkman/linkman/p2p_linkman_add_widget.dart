import 'dart:async';

import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/p2p/chain/action/findclient.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/validator_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///p2p网络节点搜索增加
class P2pLinkmanAddWidget extends StatelessWidget with DataTileMixin {
  P2pLinkmanAddWidget({super.key}) {
    _init();
  }

  @override
  IconData get iconData => Icons.add_link;

  @override
  String get routeName => 'p2p_linkman_add';

  @override
  String get title => 'P2p add linkman';

  @override
  bool get withLeading => true;

  TextEditingController controller = TextEditingController();
  final DataListController<DataTile> tileDataController =
      DataListController<DataTile>();
  late final Widget dataListView;
  StreamSubscription<ChainMessage>? chainMessageListen;

  void _init() {
    dataListView = Obx(() {
      return DataListView(
        itemCount: tileDataController.length,
        itemBuilder: (BuildContext context, int index) {
          return tileDataController.data[index];
        },
      );
    });
    chainMessageListen = findClientAction.responseStreamController.stream
        .listen((ChainMessage chainMessage) {
      _responsePeerClients(chainMessage);
    });
  }

  Padding _buildSearchTextField(BuildContext context) {
    var searchTextField = TextFormField(
        controller: controller,
        keyboardType: TextInputType.text,
        validator: (value) {
          return ValidatorUtil.emptyValidator(value);
        },
        decoration: buildInputDecoration(
            labelText: AppLocalizations.t('PeerId/Mobile/Email/Name'),
            suffixIcon: IconButton(
              onPressed: () {
                _search(controller.text);
              },
              icon: Icon(
                Icons.search,
                color: myself.primary,
              ),
            )));

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: searchTextField);
  }

  Future<void> _responsePeerClients(ChainMessage chainMessage) async {
    if (chainMessage.payloadType == PayloadType.peerClients.name) {
      List<PeerClient> peerClients = chainMessage.payload;
      if (peerClients.isNotEmpty) {
        for (var peerClient in peerClients) {
          var peerId = peerClient.peerId;
          var clientId = peerClient.clientId;
          if (peerId == myself.peerId && clientId == myself.clientId) {
            continue;
          }
        }
        await _buildTiles(peerClients);
        linkmanChatSummaryController.refresh();
      }
    }
  }

  Future<void> _buildTiles(List<PeerClient> peerClients) async {
    List<DataTile> tiles = [];
    if (peerClients.isNotEmpty) {
      for (var peerClient in peerClients) {
        var title = peerClient.name;
        var peerId = peerClient.peerId;
        Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
        Widget suffix;
        if (linkman == null) {
          suffix = IconButton(
            iconSize: 24.0,
            icon: Icon(Icons.person_add, color: myself.primary),
            onPressed: () async {
              await peerClientService.store(peerClient,
                  mobile: false, email: false);
              _buildTiles(peerClients);
              DialogUtil.info(
                  content:
                      '${AppLocalizations.t('Add peerClient as linkman')}:$peerId');
            },
            tooltip: AppLocalizations.t('Add peerClient as linkman'),
          );
        } else {
          //加好友
          if (linkman.linkmanStatus != LinkmanStatus.F.name) {
            suffix = IconButton(
              iconSize: 24.0,
              icon: Icon(Icons.person_add_outlined, color: myself.primary),
              onPressed: () async {
                await linkmanService.update(
                    {'linkmanStatus': LinkmanStatus.F.name},
                    where: 'peerId=?',
                    whereArgs: [peerClient.peerId]);
                linkman.linkmanStatus = LinkmanStatus.F.name;
                _buildTiles(peerClients);
                DialogUtil.info(
                    content:
                        '${AppLocalizations.t('Add peerClient as friend')}:$peerId');
              },
              tooltip: AppLocalizations.t('Add peerClient as friend'),
            );
          } else {
            suffix = const SizedBox(
              height: 0,
            );
          }
        }
        DataTile tile = DataTile(
            title: title, subtitle: peerId, suffix: suffix, selected: false);
        tiles.add(tile);
      }
    }
    tileDataController.replaceAll(tiles);
  }

  Future<void> _search(String key) async {
    String? error = ValidatorUtil.emptyValidator(key);
    if (error != null) {
      DialogUtil.error(content: error);
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
    tileDataController.replaceAll([]);
    await findClientAction.findClient(key, mobile, email, key);
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: title,
        helpPath: routeName,
        child: Column(children: [
          const SizedBox(
            height: 15,
          ),
          _buildSearchTextField(context),
          dataListView
        ]));
  }
}
