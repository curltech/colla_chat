import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar_view.dart';
import '../../../../widgets/common/widget_mixin.dart';
import '../../../../widgets/data_bind/column_field_widget.dart';
import '../../../../widgets/data_bind/form_input_widget.dart';
import '../../../entity/chat/contact.dart';
import '../../../service/chat/contact.dart';
import 'linkman_list_widget.dart';

final List<ColumnFieldDef> linkmanColumnFieldDefs = [
  ColumnFieldDef(
      name: 'id',
      label: 'id',
      dataType: DataType.int,
      prefixIcon: const Icon(Icons.perm_identity)),
  ColumnFieldDef(
      name: 'name', label: 'name', prefixIcon: const Icon(Icons.person)),
  ColumnFieldDef(
      name: 'peerId',
      label: 'peerId',
      prefixIcon: const Icon(Icons.perm_identity)),
  ColumnFieldDef(
      name: 'email',
      label: 'email',
      prefixIcon: const Icon(Icons.email),
      textInputType: TextInputType.emailAddress),
  ColumnFieldDef(
      name: 'mobile',
      label: 'mobile',
      prefixIcon: const Icon(Icons.mobile_friendly)),
];

//邮件内容组件
class LinkmanEditWidget extends StatefulWidget with TileDataMixin {
  final LinkmanController controller;

  LinkmanEditWidget({Key? key, required this.controller}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanEditWidgetState();

  @override
  String get routeName => 'peer_endpoint_edit';

  @override
  bool get withLeading => true;

  @override
  Icon get icon => const Icon(Icons.desktop_windows);

  @override
  String get title => 'LinkmanEdit';
}

class _LinkmanEditWidgetState extends State<LinkmanEditWidget> {
  @override
  initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildFormInputWidget(BuildContext context) {
    var initValues = widget.controller.getInitValue(linkmanColumnFieldDefs);
    var formInputWidget = FormInputWidget(
      onOk: (Map<String, dynamic> values) {
        _onOk(values);
      },
      columnFieldDefs: linkmanColumnFieldDefs,
      initValues: initValues,
    );

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) {
    Linkman currentLinkman = Linkman.fromJson(values);
    linkmanService.upsert(currentLinkman).then((count) {
      widget.controller.update(currentLinkman);
    });
  }

  @override
  Widget build(BuildContext context) {
    var appBarView = AppBarView(
        title: widget.title,
        withLeading: widget.withLeading,
        child: _buildFormInputWidget(context));
    return appBarView;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
