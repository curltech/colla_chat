import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/database/data_source_controller.dart';
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
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DataColumnEditWidget extends StatelessWidget with TileDataMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'data_column_edit';

  @override
  IconData get iconData => Icons.view_column_outlined;

  @override
  String get title => 'DataColumnEdit';

  late final PlatformReactiveFormController platformReactiveFormController;

  DataColumnEditWidget({super.key}) {
    List<PlatformDataField> dataColumnDataFields = buildDataColumnDataFields();
    platformReactiveFormController =
        PlatformReactiveFormController(dataColumnDataFields);
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
  Widget _buildPlatformReactiveForm(BuildContext context) {
    return Obx(() {
      data_source.DataColumnNode? dataColumnNode =
          dataSourceController.getDataColumnNode();
      if (dataColumnNode != null) {
        platformReactiveFormController.values =
            JsonUtil.toJson(dataColumnNode.value);
      }
      var platformReactiveForm = PlatformReactiveForm(
        spacing: 15.0,
        onSubmit: (Map<String, dynamic> values) {
          _onSubmit(values);
        },
        platformReactiveFormController: platformReactiveFormController,
      );

      return platformReactiveForm;
    });
  }

  data_source.DataColumn? _onSubmit(Map<String, dynamic> values) {
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
    DataTableNode? dataTableNode = dataSourceController.getDataTableNode();
    if (dataTableNode == null) {
      DialogUtil.error(
          content: AppLocalizations.t('Must has current data table'));
      return null;
    }
    data_source.DataColumn dataColumn;
    DataColumnNode? dataColumnNode = dataSourceController.getDataColumnNode();
    if (dataColumnNode == null) {
      dataColumn = current;
      dataSourceController.addDataColumn(dataColumn);
    } else {
      dataColumn = dataColumnNode.value as data_source.DataColumn;
      dataColumn.name = current.name;
      dataColumn.dataType = current.dataType;
      dataColumn.isKey = current.isKey;
      dataColumn.notNull = current.notNull;
      dataColumn.autoIncrement = current.autoIncrement;
    }

    DialogUtil.info(
        content: 'Successfully update dataColumn:${dataColumn.name}');

    return current;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title,
        withLeading: true,
        child: _buildPlatformReactiveForm(context));
  }
}
