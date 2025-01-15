import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/datastore/database/data_column_edit_widget.dart';
import 'package:colla_chat/pages/datastore/database/data_source_controller.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart'
    as data_source;
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final Rx<data_source.DataTable?> rxDataTable = Rx<data_source.DataTable?>(null);

class DataTableEditWidget extends StatelessWidget with TileDataMixin {
  @override
  bool get withLeading => true;

  @override
  String get routeName => 'data_table_edit';

  @override
  IconData get iconData => Icons.edit_attributes_outlined;

  @override
  String get title => 'DataTableEdit';

  DataTableEditWidget({super.key});

  List<PlatformDataField> buildDataTableDataFields(String sourceType) {
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

    return dataSourceDataFields;
  }

  FormInputController? formInputController;

  final Rx<List<data_source.DataColumn>?> dataColumns =
      Rx<List<data_source.DataColumn>?>(null);

  final Rx<data_source.DataColumn?> currentColumn =
      Rx<data_source.DataColumn?>(null);

  //DataTableNode信息编辑界面
  Widget _buildFormInputWidget(BuildContext context) {
    return Obx(() {
      data_source.DataTable dataTable = rxDataTable.value!;
      List<PlatformDataField> dataSourceDataFields =
          buildDataTableDataFields(SourceType.sqlite.name);
      formInputController = FormInputController(dataSourceDataFields);

      formInputController?.setValues(JsonUtil.toJson(dataTable));
      var formInputWidget = FormInputWidget(
        spacing: 15.0,
        height: 160,
        onOk: (Map<String, dynamic> values) {
          _onOk(values);
        },
        controller: formInputController!,
      );

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
        child: formInputWidget,
      );
    });
  }

  Future<data_source.DataTable?> _onOk(Map<String, dynamic> values) async {
    data_source.DataTable current = data_source.DataTable.fromJson(values);
    if (StringUtil.isEmpty(current.name)) {
      DialogUtil.error(content: AppLocalizations.t('Must has dataTable name'));
      return null;
    }
    data_source.DataTable dataTable = rxDataTable.value!;
    String? originalName = dataTable.name;
    if (originalName == null) {
      dataTable.name = current.name;
    } else {
      dataTable.name = current.name;
    }

    DialogUtil.info(content: 'Successfully update dataTable:${dataTable.name}');

    return current;
  }

  _buildColumns(BuildContext context) async {
    data_source.DataTable dataTable = rxDataTable.value!;
    if (dataTable.name == null) {
      return null;
    }
    dataColumns.value = await dataSourceController.findColumns(dataTable.name!);
  }

  List<TileData> _buildColumnTiles(BuildContext context) {
    List<TileData> tiles = [];
    if (dataColumns.value != null) {
      for (var dataColumn in dataColumns.value!) {
        tiles.add(TileData(
          prefix: Icon(Icons.view_column_outlined, color: myself.primary),
          title: dataColumn.name!,
          selected: dataColumn.name == currentColumn.value?.name,
          titleTail: dataColumn.dataType,
          onTap: (int index, String label, {String? subtitle}) {
            currentColumn.value = dataColumn;
            _buildColumnTiles(context);
          },
          onLongPress: (int index, String label, {String? subtitle}) {
            currentColumn.value = dataColumn;
            rxDataColumn.value = dataColumn;
            indexWidgetProvider.push('data_column_edit');
          },
        ));
      }
    }

    return tiles;
  }

  Widget _buildColumnsWidget(BuildContext context) {
    return Obx(() {
      List<TileData> columnTiles = _buildColumnTiles(context);

      return DataListView(
          itemCount: columnTiles.length,
          itemBuilder: (BuildContext context, int index) {
            return columnTiles[index];
          });
    });
  }

  Widget _buildButtonWidget(BuildContext context) {
    return OverflowBar(
      alignment: MainAxisAlignment.start,
      children: [
        IconButton(
            onPressed: () {
              data_source.DataColumn dataColumn = data_source.DataColumn();
              DataColumnNode dataColumnNode = DataColumnNode(data: dataColumn);
              rxDataColumn.value = dataColumnNode.data;
              indexWidgetProvider.push('data_column_edit');
            },
            icon: Icon(
              Icons.add,
              color: myself.primary,
            )),
        IconButton(
            onPressed: () {}, icon: Icon(Icons.remove, color: myself.primary)),
        IconButton(
            onPressed: () {
              rxDataColumn.value = currentColumn.value;
              indexWidgetProvider.push('data_column_edit');
            },
            icon: Icon(Icons.edit, color: myself.primary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _buildColumns(context);
    return AppBarView(
        title: title,
        withLeading: true,
        child: Column(children: [
          _buildFormInputWidget(context),
          _buildButtonWidget(context),
          Expanded(child: _buildColumnsWidget(context))
        ]));
  }
}
