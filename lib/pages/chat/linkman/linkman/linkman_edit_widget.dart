import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

final List<ColumnFieldDef> linkmanColumnFieldDefs = [
  ColumnFieldDef(
      name: 'peerId',
      label: 'PeerId',
      inputType: InputType.label,
      prefixIcon: const Icon(Icons.perm_identity)),
  ColumnFieldDef(
      name: 'name', label: 'Name', prefixIcon: const Icon(Icons.person)),
  ColumnFieldDef(
      name: 'alias', label: 'Alias', prefixIcon: const Icon(Icons.person_pin)),
  ColumnFieldDef(
      name: 'email',
      label: 'Email',
      prefixIcon: const Icon(Icons.email),
      textInputType: TextInputType.emailAddress),
  ColumnFieldDef(
      name: 'mobile',
      label: 'Mobile',
      prefixIcon: const Icon(Icons.mobile_friendly)),
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

    var formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: FormInputWidget(
          height: 330,
          onOk: (Map<String, dynamic> values) {
            _onOk(values);
          },
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
  }

  _addFriend({String? tip}) async {
    await _changeLinkmanStatus(LinkmanStatus.friend);
    // 加好友会发送自己的信息，回执将收到对方的信息
    await linkmanService.addFriend(linkman!.peerId, tip!);
    if (mounted) {
      DialogUtil.info(context,
          content:
              '${AppLocalizations.t('Linkman:')} ${linkman!.name}${AppLocalizations.t(' is added friend')}');
    }
  }

  _changeLinkmanStatus(LinkmanStatus status) async {
    int id = linkman!.id!;
    await linkmanService.update({'id': id, 'linkmanStatus': status.name});
    linkman = await linkmanService.findOne(where: 'id=?', whereArgs: [id]);
    linkmanController.current = linkman;
  }

  _changeSubscriptStatus(LinkmanStatus status) async {
    int id = linkman!.id!;
    await linkmanService.update({'id': id, 'subscriptStatus': status.name});
    linkman = await linkmanService.findOne(where: 'id=?', whereArgs: [id]);
    linkmanController.current = linkman;
  }

  Widget _buildAddFriendTextField(BuildContext context) {
    var controller = TextEditingController();
    var addFriendTextField = Container(
        padding: const EdgeInsets.all(10.0),
        child: CommonAutoSizeTextFormField(
          controller: controller,
          labelText: AppLocalizations.t('Add friend'),
          suffixIcon: IconButton(
            onPressed: () {
              _addFriend(tip: controller.text);
            },
            icon: Icon(
              Icons.person_add,
              color: myself.primary,
            ),
          ),
        ));

    return addFriendTextField;
  }

  Widget? _buildActionTiles(BuildContext context) {
    TileData? tileData;
    if (linkman != null) {
      if (linkman!.status == LinkmanStatus.friend.name) {
        tileData = TileData(
            title: 'Remove friend',
            prefix: const Icon(Icons.person_remove),
            onTap: (int index, String title, {String? subtitle}) async {
              await _changeLinkmanStatus(LinkmanStatus.stranger);
              if (mounted) {
                DialogUtil.info(context,
                    content:
                        '${AppLocalizations.t('Linkman:')} ${linkman!.name}${AppLocalizations.t(' is removed friend')}');
              }
            });
      }
    }
    DataListTile? tile;
    if (tileData != null) {
      DataListTile(
        tileData: tileData,
      );
    }
    return tile;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actionTiles = [];
    if (linkman != null) {
      if (linkman!.status != LinkmanStatus.friend.name) {
        actionTiles.add(_buildAddFriendTextField(context));
      }
    }
    Widget? tile = _buildActionTiles(context);
    if (tile != null) {
      actionTiles.add(const SizedBox(
        height: 15,
      ));
      actionTiles.add(tile);
    }
    // actionTiles.add(const SizedBox(
    //   height: 15,
    // ));
    actionTiles.add(_buildFormInputWidget(context));

    String title = 'Add linkman';
    int? id = linkman?.id;
    if (id != null) {
      title = 'Edit linkman';
    }
    var appBarView = AppBarView(
        title: title,
        withLeading: widget.withLeading,
        child: ListView(children: actionTiles));

    return appBarView;
  }

  @override
  void dispose() {
    linkmanController.removeListener(_update);
    super.dispose();
  }
}
