import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart'
    as data_source;
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final Rx<data_source.DataColumn?> rxDataColumn =
    Rx<data_source.DataColumn?>(null);

class DataColumnEditWidget extends StatelessWidget with TileDataMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'data_column_edit';

  @override
  IconData get iconData => Icons.view_column_outlined;

  @override
  String get title => 'DataColumnEdit';

  late final FormInputController formInputController;

  DataColumnEditWidget({super.key}) {
    List<PlatformDataField> dataColumnDataFields = buildDataColumnDataFields();
    formInputController = FormInputController(dataColumnDataFields);
  }

  List<PlatformDataField> buildDataColumnDataFields() {
    List<Option<dynamic>> options = [];
    for (var value in SqliteDataType.values) {
      options.add(Option(value.name, value.name));
    }
    var dataSourceDataFields = [
      PlatformDataField(
          name: 'name',
          label: 'Name',
          prefixIcon: Icon(Icons.person, color: myself.primary)),
      PlatformDataField(
          name: 'dataType',
          label: 'DataType',
          prefixIcon: Icon(Icons.merge_type_outlined, color: myself.primary),
          inputType: InputType.radio,
          options: options),
      PlatformDataField(
          name: 'isKey',
          label: 'isKey',
          inputType: InputType.switcher,
          dataType: DataType.bool,
          prefixIcon: Icon(Icons.key, color: myself.primary)),
      PlatformDataField(
          name: 'notNull',
          label: 'NotNull',
          inputType: InputType.switcher,
          dataType: DataType.bool,
          prefixIcon: Icon(Icons.hourglass_empty, color: myself.primary)),
      PlatformDataField(
          name: 'autoIncrement',
          label: 'AutoIncrement',
          inputType: InputType.switcher,
          dataType: DataType.bool,
          prefixIcon: Icon(Icons.numbers_outlined, color: myself.primary)),
      PlatformDataField(
          name: 'comment',
          label: 'Comment',
          prefixIcon: Icon(Icons.comment, color: myself.primary)),
    ];

    return dataSourceDataFields;
  }

  //DataSourceNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    return Obx(() {
      data_source.DataColumn dataColumn = rxDataColumn.value!;
      formInputController.setValues(JsonUtil.toJson(dataColumn));
      var formInputWidget = FormInputWidget(
        spacing: 15.0,
        onOk: (Map<String, dynamic> values) {
          _onOk(values);
        },
        controller: formInputController,
      );

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
        child: formInputWidget,
      );
    });
  }

  data_source.DataColumn? _onOk(Map<String, dynamic> values) {
    data_source.DataColumn current = data_source.DataColumn.fromJson(values);
    if (StringUtil.isEmpty(current.name)) {
      DialogUtil.error(content: AppLocalizations.t('Must has dataColumn name'));
      return null;
    }
    if (StringUtil.isEmpty(current.dataType)) {
      DialogUtil.error(
          content: AppLocalizations.t('Must has dataColumn dataType'));
      return null;
    }
    data_source.DataColumn dataColumn = rxDataColumn.value!;
    String? originalName = dataColumn.name;
    if (originalName == null) {}
    dataColumn.name = current.name;
    dataColumn.dataType = current.dataType;
    dataColumn.isKey = current.isKey;
    dataColumn.notNull = current.notNull;
    dataColumn.autoIncrement = current.autoIncrement;

    DialogUtil.info(
        content: 'Successfully update dataColumn:${dataColumn.name}');

    return current;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title, withLeading: true, child: _buildFormInputWidget(context));
  }
}
