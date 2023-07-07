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
import 'package:colla_chat/tool/clipboard_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/validator_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:flutter/material.dart';

///粘贴linkman的json字符串增加
class JsonLinkmanAddWidget extends StatefulWidget with TileDataMixin {
  JsonLinkmanAddWidget({Key? key}) : super(key: key);

  @override
  IconData get iconData => Icons.add_link;

  @override
  String get routeName => 'json_linkman_add';

  @override
  String get title => 'Json add linkman';

  @override
  bool get withLeading => true;

  @override
  State<StatefulWidget> createState() => _JsonLinkmanAddWidgetState();
}

class _JsonLinkmanAddWidgetState extends State<JsonLinkmanAddWidget> {
  TextEditingController jsonController = TextEditingController();

  @override
  initState() {
    super.initState();
  }

  _update() {
    setState(() {});
  }

  _buildJsonTextField(BuildContext context) {
    var jsonTextField = CommonAutoSizeTextFormField(
      controller: jsonController,
      keyboardType: TextInputType.text,
      autofocus: true,
      minLines: 100,
      labelText: AppLocalizations.t('Please paste linkman json here'),
      //hintText: AppLocalizations.t('Please paste linkman json here'),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
      child: Column(children: [
        Expanded(child: jsonTextField),
        const SizedBox(
          height: 15.0,
        ),
        ButtonBar(children: [
          TextButton.icon(
            style: StyleUtil.buildButtonStyle(elevation: 10.0),
            onPressed: () async {
              jsonController.text = '';
            },
            icon: const Icon(
              Icons.clear,
            ),
            label: CommonAutoSizeText(AppLocalizations.t('Reset')),
          ),
          TextButton.icon(
            style: StyleUtil.buildButtonStyle(
                backgroundColor: myself.primary, elevation: 10.0),
            onPressed: () async {
              String content = await ClipboardUtil.paste();
              jsonController.text = content;
            },
            icon: const Icon(
              Icons.paste,
            ),
            label: CommonAutoSizeText(AppLocalizations.t('Paste')),
          ),
          TextButton.icon(
            style: StyleUtil.buildButtonStyle(
                backgroundColor: myself.primary, elevation: 10.0),
            onPressed: () async {
              PeerClient peerClient = await _addLinkman();
              if (mounted) {
                DialogUtil.info(context,
                    content:
                        '${AppLocalizations.t('Add linkman ')}:${peerClient.peerId}');
              }
            },
            icon: const Icon(
              Icons.heart_broken,
            ),
            label: CommonAutoSizeText(AppLocalizations.t('Add linkman')),
          ),
          TextButton.icon(
            style: StyleUtil.buildButtonStyle(
                backgroundColor: myself.primary, elevation: 10.0),
            onPressed: () async {
              PeerClient peerClient = await _addLinkman();
              await linkmanService.update(
                  {'linkmanStatus': LinkmanStatus.friend.name},
                  where: 'peerId=?',
                  whereArgs: [peerClient.peerId]);
              if (mounted) {
                DialogUtil.info(context,
                    content:
                        '${AppLocalizations.t('Add linkman as friend')}:${peerClient.peerId}');
              }
            },
            icon: const Icon(
              Icons.person_add,
            ),
            label: CommonAutoSizeText(AppLocalizations.t('Add friend')),
          ),
        ])
      ]),
    );
  }

  Future<PeerClient> _addLinkman() async {
    Map<String, dynamic> json = JsonUtil.toJson(jsonController.text);
    PeerClient peerClient = PeerClient.fromJson(json);
    await peerClientService.store(peerClient, mobile: false, email: false);

    return peerClient;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        withLeading: true,
        title: widget.title,
        child: _buildJsonTextField(context));
  }

  @override
  void dispose() {
    jsonController.dispose();
    super.dispose();
  }
}
