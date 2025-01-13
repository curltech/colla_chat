import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final Rx<DataSourceNode?> rxDataSourceNode = Rx<DataSourceNode?>(null);

class DataSourceEditWidget extends StatelessWidget with TileDataMixin {
  DataSourceEditWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'data_source_edit';

  @override
  IconData get iconData => Icons.edit_attributes_outlined;

  @override
  String get title => 'DataSourceEdit';

  List<PlatformDataField> buildDataSourceDataFields(String sourceType) {
    var dataSourceDataFields = [
      PlatformDataField(
          name: 'name',
          label: 'Name',
          prefixIcon: Icon(Icons.person, color: myself.primary)),
      PlatformDataField(
          name: 'comment',
          label: 'Comment',
          prefixIcon: Icon(Icons.comment, color: myself.primary)),
    ];
    if (sourceType == SourceType.sqlite.name) {
      dataSourceDataFields.add(PlatformDataField(
          name: 'filename',
          label: 'Filename',
          prefixIcon: Icon(Icons.file_open_outlined, color: myself.primary),
          suffixIcon: IconButton(
              onPressed: () async {
                XFile? xfile = await FileUtil.selectFile();
                if (xfile != null) {
                  formInputController?.setValue('filename', xfile.path);
                }
              },
              icon: Icon(Icons.arrow_circle_down_outlined,
                  color: myself.primary))));
    }
    if (sourceType == SourceType.postgres.name) {
      dataSourceDataFields.add(PlatformDataField(
          name: 'host',
          label: 'Host',
          prefixIcon: Icon(Icons.desktop_mac_outlined, color: myself.primary)));
      dataSourceDataFields.add(PlatformDataField(
          name: 'port',
          label: 'Port',
          dataType: DataType.int,
          prefixIcon: Icon(Icons.import_export, color: myself.primary)));
      dataSourceDataFields.add(PlatformDataField(
          name: 'user',
          label: 'User',
          prefixIcon:
              Icon(Icons.perm_contact_cal_outlined, color: myself.primary)));
      dataSourceDataFields.add(PlatformDataField(
          name: 'password',
          label: 'Password',
          prefixIcon: Icon(Icons.password, color: myself.primary)));
      dataSourceDataFields.add(PlatformDataField(
          name: 'database',
          label: 'Database',
          prefixIcon: Icon(Icons.data_usage_outlined, color: myself.primary)));
    }

    return dataSourceDataFields;
  }

  FormInputController? formInputController;

  //DataSourceNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    if (rxDataSourceNode.value == null) {
      rxDataSourceNode.value = DataSourceNode(
          data: DataSource('', sourceType: SourceType.sqlite.name));
    }
    DataSource dataSource = rxDataSourceNode.value!.data!;
    List<Option<dynamic>> options = [];
    for (var value in SourceType.values) {
      options.add(Option(value.name, value.name));
    }
    List<PlatformDataField> dataSourceDataFields =
        buildDataSourceDataFields(dataSource.sourceType);
    dataSourceDataFields.insert(
        1,
        PlatformDataField(
            name: 'sourceType',
            label: 'SourceType',
            prefixIcon: Icon(Icons.merge_type_outlined, color: myself.primary),
            inputType: InputType.select,
            options: options));
    formInputController = FormInputController(dataSourceDataFields);

    formInputController?.setValues(JsonUtil.toJson(dataSource));
    var formInputWidget = FormInputWidget(
      spacing: 15.0,
      onOk: (Map<String, dynamic> values) {
        _onOk(values);
      },
      controller: formInputController!,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
      child: formInputWidget,
    );
  }

  DataSource? _onOk(Map<String, dynamic> values) {
    DataSource current = DataSource.fromJson(values);
    if (StringUtil.isEmpty(current.name)) {
      DialogUtil.error(content: AppLocalizations.t('Must has dataSource name'));
      return null;
    }
    if (StringUtil.isEmpty(current.sourceType)) {
      DialogUtil.error(
          content: AppLocalizations.t('Must has dataSource sourceType'));
      return null;
    }
    DataSource dataSource = rxDataSourceNode.value!.data!;
    dataSource.name = current.name;
    dataSource.sourceType = current.sourceType;
    if (current.sourceType == SourceType.sqlite.name) {
      if (StringUtil.isEmpty(current.filename)) {
        DialogUtil.error(
            content: AppLocalizations.t('Must has dataSource filename'));
        return null;
      }
      dataSource.filename = current.filename;
    }
    if (current.sourceType == SourceType.postgres.name) {
      if (StringUtil.isEmpty(current.host)) {
        DialogUtil.error(
            content: AppLocalizations.t('Must has dataSource host'));
        return null;
      }
      dataSource.host = current.host;
      dataSource.port = current.port;
      dataSource.user = current.user;
      dataSource.password = current.password;
      dataSource.database = current.database;
    }

    DialogUtil.info(
        content: 'Successfully update dataSource:${dataSource.name}');

    return current;
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title, withLeading: true, child: _buildFormInputWidget(context));
  }
}
