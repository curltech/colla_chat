import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/common/app_bar_view.dart';
import '../../../../../widgets/common/widget_mixin.dart';
import '../../../../../widgets/data_bind/column_field_widget.dart';
import '../../../../../widgets/data_bind/form_input_widget.dart';
import '../../../../entity/chat/contact.dart';
import '../../../../l10n/localization.dart';
import '../../../../service/chat/contact.dart';

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

//联系人编辑组件
class LinkmanEditWidget extends StatefulWidget with TileDataMixin {
  final Linkman? linkman;

  LinkmanEditWidget({Key? key, this.linkman}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinkmanEditWidgetState();

  @override
  String get routeName => 'linkman_edit';

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
  }

  Widget _buildFormInputWidget(BuildContext context) {
    Map<String, dynamic> initValues = {};
    if (widget.linkman != null) {
      var values = JsonUtil.toJson(widget.linkman);
      for (var linkmanColumnFieldDef in linkmanColumnFieldDefs) {
        var value = values[linkmanColumnFieldDef.name];
        if (value != null) {
          initValues[linkmanColumnFieldDef.name] = value;
        }
      }
    }
    var formInputWidget = FormInputWidget(
      onOk: (Map<String, dynamic> values) {
        _onOk(values);
      },
      columnFieldDefs: linkmanColumnFieldDefs,
      initValues: initValues,
    );

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) async {
    Linkman currentLinkman = Linkman.fromJson(values);
    await linkmanService.upsert(currentLinkman);
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
    super.dispose();
  }
}
