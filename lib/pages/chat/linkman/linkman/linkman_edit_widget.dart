import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/service/dht/peerclient.dart';
import 'package:colla_chat/tool/clipboard_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

final List<ColumnFieldDef> linkmanColumnFieldDefs = [
  ColumnFieldDef(
      name: 'peerId',
      label: 'PeerId',
      inputType: InputType.label,
      prefixIcon: Icon(
        Icons.perm_identity,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'name',
      label: 'Name',
      prefixIcon: Icon(
        Icons.person,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'alias',
      label: 'Alias',
      prefixIcon: Icon(
        Icons.person_pin,
        color: myself.primary,
      )),
  ColumnFieldDef(
      name: 'email',
      label: 'Email',
      prefixIcon: Icon(
        Icons.email,
        color: myself.primary,
      ),
      textInputType: TextInputType.emailAddress),
  ColumnFieldDef(
      name: 'mobile',
      label: 'Mobile',
      prefixIcon: Icon(
        Icons.mobile_friendly,
        color: myself.primary,
      )),
];

//联系人信息页面
class LinkmanEditWidget extends StatefulWidget with TileDataMixin {
  LinkmanEditWidget({Key? key}) : super(key: key);

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
  Linkman? linkman;

  @override
  initState() {
    super.initState();
    linkmanController.addListener(_update);
    linkman ??= linkmanController.current;
  }

  _update() {
    setState(() {});
  }

  Widget _buildFormInputWidget(BuildContext context) {
    Map<String, dynamic>? initValues =
        linkmanController.getInitValue(linkmanColumnFieldDefs);
    List<FormButtonDef> formButtonDefs = [
      FormButtonDef(
          label: 'Ok',
          onTap: (Map<String, dynamic> values) {
            _onOk(values);
          }),
      FormButtonDef(
          label: 'Share',
          onTap: (Map<String, dynamic> values) {
            _onShare(values);
          }),
      FormButtonDef(
          label: 'Copy',
          onTap: (Map<String, dynamic> values) {
            _onCopy(values);
          }),
    ];

    var formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: FormInputWidget(
          height: 430,
          formButtonDefs: formButtonDefs,
          columnFieldDefs: linkmanColumnFieldDefs,
          initValues: initValues,
        ));

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) async {
    Linkman currentLinkman = Linkman.fromJson(values);
    linkman!.name = currentLinkman.name;
    linkman!.alias = currentLinkman.alias;
    linkman!.mobile = currentLinkman.mobile;
    linkman!.email = currentLinkman.email;
    await linkmanService.store(linkman!);
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

  _changeLinkmanStatus(LinkmanStatus status) async {
    int id = linkman!.id!;
    await linkmanService.update({'id': id, 'linkmanStatus': status.name});
    linkman = await linkmanService.findOne(where: 'id=?', whereArgs: [id]);
    linkmanController.current = linkman;
    linkmanService.linkmen.remove(linkman!.peerId);
  }

  _changeSubscriptStatus(LinkmanStatus status) async {
    int id = linkman!.id!;
    await linkmanService.update({'id': id, 'subscriptStatus': status.name});
    linkman = await linkmanService.findOne(where: 'id=?', whereArgs: [id]);
    linkmanController.current = linkman;
    linkmanService.linkmen.remove(linkman!.peerId);
  }

  @override
  Widget build(BuildContext context) {
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
    linkmanController.removeListener(_update);
    super.dispose();
  }
}
