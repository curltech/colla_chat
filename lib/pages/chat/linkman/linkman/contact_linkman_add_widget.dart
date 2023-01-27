import 'package:colla_chat/crypto/cryptography.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/entity/p2p/chain_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/p2p/chain/action/findclient.dart';
import 'package:colla_chat/p2p/chain/baseaction.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///Contact增加联系人
class ContactLinkmanAddWidget extends StatefulWidget with TileDataMixin {
  final DataListController<TileData> controller =
      DataListController<TileData>();
  late final DataListView dataListView;

  ContactLinkmanAddWidget({Key? key}) : super(key: key) {
    dataListView = DataListView(
      controller: controller,
    );
  }

  @override
  IconData get iconData => Icons.contact_phone;

  @override
  String get routeName => 'contact_linkman_add';

  @override
  String get title => 'Contact add linkman';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _ContactLinkmanAddWidgetState();
}

class _ContactLinkmanAddWidgetState extends State<ContactLinkmanAddWidget> {
  var controller = TextEditingController();
  var contactMap = {};

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

  Future<void> _search(String key) async {
    List<Contact> contacts;
    if (StringUtil.isEmpty(key)) {
      contacts = await contactService.syncContact();
    } else {
      contacts = await contactService.search(key);
    }
    await _transfer(contacts);
  }

  Future<void> _transfer(List<Contact> contacts) async {
    List<TileData> tiles = [];
    contactMap = {};
    if (contacts.isNotEmpty) {
      for (var contact in contacts) {
        var title = contact.name;
        var mobile = contact.mobile;
        bool isFriend = false;
        var peerId = contact.peerId;
        var subtitle = mobile;
        if (StringUtil.isNotEmpty(peerId)) {
          subtitle = peerId;
          Linkman? linkman = await linkmanService.findCachedOneByPeerId(peerId);
          if (linkman != null && linkman.status == LinkmanStatus.friend.name) {
            isFriend = true;
          }
        }
        Widget suffix = Text(AppLocalizations.t('friend'));
        if (!isFriend) {
          suffix = IconButton(
            iconSize: 24.0,
            icon: const Icon(Icons.add),
            onPressed: () async {
              if (mobile != null) {
                await findClientAction.findClient('', mobile, '', '');
                var hash = CryptoUtil.encodeBase64(
                    await cryptoGraphy.hash(mobile.codeUnits));
                contactMap[hash] = contact;
              }
            },
          );
        }
        TileData tile =
            TileData(title: title, subtitle: subtitle, suffix: suffix);
        tiles.add(tile);
      }
    }
    widget.controller.replaceAll(tiles);
  }

  Future<void> _responsePeerClients(ChainMessage chainMessage) async {
    if (chainMessage.payloadType == PayloadType.peerClients.name) {
      List<PeerClient> peerClients = chainMessage.payload;
      if (peerClients.isNotEmpty) {
        for (var peerClient in peerClients) {
          var peerId = peerClient.peerId;
          var hash = peerClient.mobile;
          Contact? contact = contactMap[hash];
          if (contact != null) {
            contact.peerId = peerId;
            contactMap.remove(hash);
            peerClient.mobile = contact.mobile;
            Linkman linkman =
                await linkmanService.storeByPeerClient(peerClient);
            await linkmanService.update({
              'id': linkman.id,
              'status': LinkmanStatus.friend.name
            }).then((value) {
              contact.status = LinkmanStatus.friend.name;
              peerClient.status = LinkmanStatus.friend.name;
              contactService.update(contact);
              peerClientService.store(peerClient, mobile: true, email: false);
              DialogUtil.info(context,
                  content:
                      AppLocalizations.t('Add contact as linkman:') + peerId);
            });
          }
        }
      }
    }
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
    controller.dispose();
    findClientAction.unregisterResponsor(_responsePeerClients);
    super.dispose();
  }
}
