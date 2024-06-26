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

///面对面建群
class FaceGroupAddWidget extends StatefulWidget with TileDataMixin {
  final DataListController<TileData> controller =
      DataListController<TileData>();
  late final DataListView dataListView;

  FaceGroupAddWidget({super.key}) {
    dataListView = DataListView(
      controller: controller,
    );
  }

  @override
  IconData get iconData => Icons.face;

  @override
  String get routeName => 'face_group_add';

  @override
  String get title => 'Face add group';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _FaceGroupAddWidgetState();
}

class _FaceGroupAddWidgetState extends State<FaceGroupAddWidget> {
  TextEditingController controller = TextEditingController();
  StreamSubscription<ChainMessage>? chainMessageListen;

  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
    chainMessageListen = findClientAction.responseStreamController.stream
        .listen((ChainMessage chainMessage) {
      _responsePeerClients(chainMessage);
    });
  }

  _update() {
    setState(() {});
  }

  _buildSearchTextField(BuildContext context) {
    var searchTextField = CommonTextFormField(
        controller: controller,
        keyboardType: TextInputType.text,
        labelText: AppLocalizations.t('PeerId/Mobile/Email/Name'),
        suffixIcon: IconButton(
          onPressed: () {
            _search(controller.text);
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
        title: widget.title,
        child: Column(
            children: [_buildSearchTextField(context), widget.dataListView]));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    chainMessageListen?.cancel();
    chainMessageListen = null;
    controller.dispose();
    super.dispose();
  }
}
