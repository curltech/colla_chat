import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_list_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
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
        padding: const EdgeInsets.all(15.0),
        child: FormInputWidget(
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
    await _changeStatus(LinkmanStatus.friend);
    // 加好友会发送自己的信息，回执将收到对方的信息
    await linkmanService.addFriend(linkman!.peerId, tip!);
    if (mounted) {
      DialogUtil.info(context,
          content:
              '${AppLocalizations.t('Linkman:')} ${linkman!.name}${AppLocalizations.t(' is added friend')}');
    }
  }

  _changeStatus(LinkmanStatus status) async {
    int id = linkman!.id!;
    await linkmanService.update({'id': id, 'status': status.name});
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
        child: TextFormField(
            autofocus: true,
            controller: controller,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              fillColor: Colors.grey.withOpacity(AppOpacity.lgOpacity),
              filled: true,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
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
              suffixIconColor: myself.primary,
            )));

    return addFriendTextField;
  }

  Widget _buildActionTiles(BuildContext context) {
    List<TileData> tileData = [];
    if (linkman != null) {
      if (linkman!.status == LinkmanStatus.friend.name) {
        tileData.add(
          TileData(
              title: 'Remove friend',
              prefix: const Icon(Icons.person_remove),
              onTap: (int index, String title, {String? subtitle}) async {
                await _changeStatus(LinkmanStatus.effective);
                if (mounted) {
                  DialogUtil.info(context,
                      content:
                          '${AppLocalizations.t('Linkman:')} ${linkman!.name}${AppLocalizations.t(' is removed friend')}');
                }
              }),
        );
      }
    }
    var listView = DataListView(
      tileData: tileData,
    );
    return listView;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actionTiles = [];
    if (linkman != null) {
      if (linkman!.status != LinkmanStatus.friend.name) {
        actionTiles.add(_buildAddFriendTextField(context));
        actionTiles.add(
          const SizedBox(
            height: 15,
          ),
        );
      }
    }
    actionTiles.add(_buildActionTiles(context));
    actionTiles.add(const SizedBox(
      height: 15,
    ));
    actionTiles.add(Expanded(
        child: SingleChildScrollView(child: _buildFormInputWidget(context))));

    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: Column(children: actionTiles));
    return appBarView;
  }

  @override
  void dispose() {
    linkmanController.removeListener(_update);
    super.dispose();
  }
}
