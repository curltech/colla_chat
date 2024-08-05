import 'dart:async';

import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/p2p/chain/action/findclient.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_text_form_field.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///附近的人建群
class NearbyGroupAddWidget extends StatelessWidget with TileDataMixin {
  final DataListController<TileData> controller =
      DataListController<TileData>();
  late final Widget dataListView;

  NearbyGroupAddWidget({super.key}) {
    dataListView = Obx(() {
      return DataListView(
        itemCount: controller.length,
        itemBuilder: (BuildContext context, int index) {
          return controller.data[index];
        },
      );
    });

    chainMessageListen = findClientAction.responseStreamController.stream
        .listen((ChainMessage chainMessage) {
      _responsePeerClients(chainMessage);
    });
  }

  @override
  IconData get iconData => Icons.near_me;

  @override
  String get routeName => 'nearby_group_add';

  @override
  String get title => 'Nearby add group';

  @override
  bool get withLeading => true;

  TextEditingController textEditingController = TextEditingController();
  StreamSubscription<ChainMessage>? chainMessageListen;

  _buildSearchTextField(BuildContext context) {
    var searchTextField = CommonTextFormField(
        controller: textEditingController,
        keyboardType: TextInputType.text,
        labelText: AppLocalizations.t('PeerId/Mobile/Email/Name'),
        suffixIcon: IconButton(
          onPressed: () {
            _search(textEditingController.text);
          },
          icon: const Icon(Icons.search),
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
                onPressed: () async {
                  logger.i('add peerClient:$subtitle as linkman');
                  Linkman linkman =
                      await linkmanService.storeByPeerEntity(peerClient);
                  await linkmanService.update(
                      {'id': linkman.id, 'status': LinkmanStatus.F.name});
                },
              ));
          tiles.add(tile);
        }
      }
      controller.replaceAll(tiles);
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
        title: title,
        child:
            Column(children: [_buildSearchTextField(context), dataListView]));
  }
}
