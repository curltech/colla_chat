import 'dart:typed_data';

import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/clipboard_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

final ValueNotifier<Linkman?> linkmanNotifier = ValueNotifier<Linkman?>(null);

//联系人信息页面
class LinkmanEditWidget extends StatefulWidget with TileDataMixin {
  LinkmanEditWidget({super.key});

  @override
  State<StatefulWidget> createState() => _LinkmanEditWidgetState();

  @override
  String get routeName => 'linkman_edit';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.person_add;

  @override
  String get title => 'Linkman edit';
}

class _LinkmanEditWidgetState extends State<LinkmanEditWidget> {
  final List<PlatformDataField> linkmanDataField = [
    PlatformDataField(
        name: 'id',
        label: 'Id',
        inputType: InputType.label,
        readOnly: true,
        prefixIcon: Icon(
          Icons.numbers_outlined,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'peerId',
        label: 'PeerId',
        inputType: InputType.label,
        readOnly: true,
        prefixIcon: Icon(
          Icons.perm_identity,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'name',
        label: 'Name',
        prefixIcon: Icon(
          Icons.person,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'alias',
        label: 'Alias',
        prefixIcon: Icon(
          Icons.person_pin,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'email',
        label: 'Email',
        prefixIcon: Icon(
          Icons.email,
          color: myself.primary,
        ),
        textInputType: TextInputType.emailAddress),
    PlatformDataField(
        name: 'mobile',
        label: 'Mobile',
        prefixIcon: Icon(
          Icons.mobile_friendly,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'linkmanStatus',
        label: 'LinkmanStatus',
        prefixIcon: Icon(
          Icons.child_friendly_outlined,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'subscriptStatus',
        label: 'SubscriptStatus',
        prefixIcon: Icon(
          Icons.subscript_outlined,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'publicKey',
        label: 'PublicKey',
        readOnly: true,
        prefixIcon: Icon(
          Icons.vpn_key,
          color: myself.primary,
        )),
  ];
  late final FormInputController controller =
      FormInputController(linkmanDataField);

  @override
  initState() {
    super.initState();
    linkmanNotifier.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildFormInputWidget(BuildContext context) {
    Linkman? linkman = linkmanNotifier.value;
    if (linkman != null) {
      controller.setValues(JsonUtil.toJson(linkman));
    }
    List<FormButton> formButtons = [
      FormButton(
          label: 'Ok',
          onTap: (Map<String, dynamic> values) {
            _onOk(values);
          }),
      FormButton(
          label: 'Share',
          onTap: (Map<String, dynamic> values) {
            _onShare(values);
          }),
      FormButton(
          label: 'Copy',
          onTap: (Map<String, dynamic> values) {
            _onCopy(values);
          }),
    ];
    List<Widget> heads = [];
    if (linkman != null) {
      heads.add(ListTile(
          title: Text(AppLocalizations.t('Avatar')),
          trailing: linkman.avatarImage,
          onTap: () async {
            await _pickAvatar(
              context,
              linkman.peerId,
            );
            linkmanNotifier.value =
                await linkmanService.findCachedOneByPeerId(linkman.peerId);
            linkmanController.current = linkmanNotifier.value;
          }));
    }
    var formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: FormInputWidget(
          height: appDataProvider.portraitSize.height * 0.7,
          spacing: 5.0,
          formButtons: formButtons,
          controller: controller,
          heads: heads,
        ));

    return formInputWidget;
  }

  Future<void> _pickAvatar(
    BuildContext context,
    String peerId,
  ) async {
    Uint8List? avatar = await ImageUtil.pickAvatar(context);
    if (avatar == null) {
      bool? confirm = await DialogUtil.confirm(context,
          content: 'Do you want delete avatar?');
      if (confirm == null || !confirm) {
        return;
      }
    }
    await linkmanService.updateAvatar(peerId, avatar);
    await peerClientService.updateAvatar(peerId, avatar);
  }

  _onOk(Map<String, dynamic> values) async {
    Linkman? linkman = linkmanNotifier.value;
    if (linkman == null) {
      linkman = Linkman('', '');
      linkmanNotifier.value = linkman;
    }
    Linkman currentLinkman = Linkman.fromJson(values);
    linkman.id = currentLinkman.id;
    linkman.name = currentLinkman.name;
    linkman.alias = currentLinkman.alias;
    linkman.mobile = currentLinkman.mobile;
    linkman.email = currentLinkman.email;
    linkman.linkmanStatus = currentLinkman.linkmanStatus;
    linkman.subscriptStatus = currentLinkman.subscriptStatus;
    await linkmanService.store(linkman);
    linkmanChatSummaryController.refresh();
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Linkman has stored completely'));
    }
  }

  _onShare(Map<String, dynamic> values) async {
    final box = context.findRenderObject() as RenderBox?;
    String peerId = values['peerId'];
    PeerClient? peerClient =
        await peerClientService.findCachedOneByPeerId(peerId);
    if (peerClient == null) {
      return;
    }
    Share.share(
      JsonUtil.toJsonString(peerClient),
      subject: peerClient.name,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  _onCopy(Map<String, dynamic> values) async {
    String peerId = values['peerId'];
    PeerClient? peerClient =
        await peerClientService.findCachedOneByPeerId(peerId);
    if (peerClient == null) {
      return;
    }
    await ClipboardUtil.copy(JsonUtil.toJsonString(peerClient));
  }

  @override
  Widget build(BuildContext context) {
    Linkman? linkman = linkmanNotifier.value;
    String title = 'Add linkman';
    int? id = linkman?.id;
    if (id != null) {
      title = 'Edit linkman';
    }
    var appBarView = AppBarView(
        title: title,
        withLeading: widget.withLeading,
        child: SingleChildScrollView(child: _buildFormInputWidget(context)));

    return appBarView;
  }

  @override
  void dispose() {
    linkmanNotifier.removeListener(_update);
    super.dispose();
  }
}
