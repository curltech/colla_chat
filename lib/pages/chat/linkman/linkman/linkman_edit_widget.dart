import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
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

//联系人编辑组件，加减联系人好友，黑名单，订阅，改变联系人的名称
class LinkmanEditWidget extends StatefulWidget with TileDataMixin {
  LinkmanEditWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanEditWidgetState();

  @override
  String get routeName => 'linkman_edit';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.person_add);

  @override
  String get title => 'Linkman edit';
}

class _LinkmanEditWidgetState extends State<LinkmanEditWidget> {
  Linkman? linkman;

  @override
  initState() {
    super.initState();
    linkman = linkmanController.current;
    linkmanController.addListener(_update);
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

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: Text(AppLocalizations.t(widget.title)),
        withLeading: widget.withLeading,
        child: _buildFormInputWidget(context));
    return appBarView;
  }

  @override
  void dispose() {
    linkmanController.removeListener(_update);
    super.dispose();
  }
}
