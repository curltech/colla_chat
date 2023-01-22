import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman/linkman_edit_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
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
      name: 'name',
      label: 'Name',
      inputType: InputType.label,
      prefixIcon: const Icon(Icons.person)),
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
class LinkmanInfoWidget extends StatefulWidget with TileDataMixin {
  late final LinkmanEditWidget linkmanEditWidget;

  LinkmanInfoWidget({Key? key}) : super(key: key) {
    linkmanEditWidget = LinkmanEditWidget();
    indexWidgetProvider.define(linkmanEditWidget);
  }

  @override
  State<StatefulWidget> createState() => _LinkmanInfoWidgetState();

  @override
  String get routeName => 'linkman_info';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.person);

  @override
  String get title => 'Linkman information';
}

class _LinkmanInfoWidgetState extends State<LinkmanInfoWidget> {
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
    linkman!.alias = currentLinkman.alias;
    linkman!.mobile = currentLinkman.mobile;
    linkman!.email = currentLinkman.email;
    await linkmanService.store(linkman!);
  }

  _addFriend({String? tip}) async {
    await _changeStatus(LinkmanStatus.friend);
    // 加好友会发送自己的信息，回执将收到对方的信息
    await linkmanService.addFriend(linkman!.peerId, tip!);
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
              fillColor: Colors.black.withOpacity(0.1),
              filled: true,
              border: InputBorder.none,
              labelText: AppLocalizations.t('Add friend'),
              suffixIcon: IconButton(
                onPressed: () {
                  _addFriend(tip: controller.text);
                },
                icon: const Icon(Icons.person_add),
              ),
            )));

    return addFriendTextField;
  }

  Widget _buildActionCard(BuildContext context) {
    List<Widget> actionWidgets = [];
    double height = 180;
    final List<ActionData> actionData = [];
    if (linkman != null) {
      if (linkman!.status == LinkmanStatus.friend.name) {
        actionData.add(
          ActionData(
              label: AppLocalizations.t('Remove friend'),
              icon: const Icon(Icons.person_remove),
              onTap: (int index, String label, {String? value}) {
                _changeStatus(LinkmanStatus.stranger);
              }),
        );
      } else {
        actionWidgets.add(_buildAddFriendTextField(context));
      }
      if (linkman!.status == LinkmanStatus.blacklist.name) {
        actionData.add(
          ActionData(
              label: AppLocalizations.t('Remove blacklist'),
              icon: const Icon(Icons.person_outlined),
              onTap: (int index, String label, {String? value}) {
                _changeStatus(LinkmanStatus.stranger);
              }),
        );
      } else {
        actionData.add(ActionData(
            label: AppLocalizations.t('Add blacklist'),
            icon: const Icon(Icons.person_off),
            onTap: (int index, String label, {String? value}) {
              _changeStatus(LinkmanStatus.blacklist);
            }));
      }
      if (linkman!.status == LinkmanStatus.blacklist.name) {
        actionData.add(
          ActionData(
              label: AppLocalizations.t('Remove subscript'),
              icon: const Icon(Icons.unsubscribe),
              onTap: (int index, String label, {String? value}) {
                _changeSubscriptStatus(LinkmanStatus.stranger);
              }),
        );
      } else {
        actionData.add(ActionData(
            label: AppLocalizations.t('Add subscript'),
            icon: const Icon(Icons.subscriptions),
            onTap: (int index, String label, {String? value}) {
              _changeSubscriptStatus(LinkmanStatus.subscript);
            }));
      }
    }
    actionWidgets.add(DataActionCard(
      actions: actionData,
      height: height,
      crossAxisCount: 4,
    ));
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: Column(children: actionWidgets),
    );
  }

  @override
  Widget build(BuildContext context) {
    var linkmanInfoCard = Column(children: [
      _buildActionCard(context),
      _buildFormInputWidget(context),
    ]);
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: linkmanInfoCard);
    return appBarView;
  }

  @override
  void dispose() {
    linkmanController.removeListener(_update);
    super.dispose();
  }
}
