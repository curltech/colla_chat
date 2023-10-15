import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/stock/event.dart';
import 'package:colla_chat/entity/stock/filter_cond.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/event.dart';
import 'package:colla_chat/service/stock/filter_cond.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/tool/number_format_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

final List<PlatformDataField> filterCondFieldDefs = [
  PlatformDataField(
      name: 'id',
      label: 'Id',
      inputType: InputType.label,
      prefixIcon: Icon(
        Icons.perm_identity_outlined,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'cond_code',
      label: 'CondCode',
      prefixIcon: Icon(
        Icons.code,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'cond_type',
      label: 'CondType',
      prefixIcon: Icon(
        Icons.type_specimen_outlined,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'name',
      label: 'Name',
      prefixIcon: Icon(
        Icons.person,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'content',
      label: 'Content',
      prefixIcon: Icon(
        Icons.content_paste,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'cond_paras',
      label: 'CondParas',
      prefixIcon: Icon(
        Icons.attribution_outlined,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'descr',
      label: 'Descr',
      prefixIcon: Icon(
        Icons.description_outlined,
        color: myself.primary,
      )),
];

/// 自选股的控制器
final DataListController<FilterCond> filterCondController =
    DataListController<FilterCond>();

///自选股和分组的查询界面
class FilterCondWidget extends StatefulWidget with TileDataMixin {
  FilterCondWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FilterCondWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'filter_cond';

  @override
  IconData get iconData => Icons.event_available_outlined;

  @override
  String get title => 'FilterCond';
}

class _FilterCondWidgetState extends State<FilterCondWidget>
    with TickerProviderStateMixin {
  final FormInputController controller =
      FormInputController(filterCondFieldDefs);
  SwiperController swiperController = SwiperController();
  int index = 0;
  final List<PlatformDataColumn> filterCondColumns = [
    PlatformDataColumn(
      label: '条件代码',
      name: 'cond_code',
      width: 150,
    ),
    PlatformDataColumn(
      label: '条件名',
      name: 'name',
      width: 200,
    ),
  ];

  @override
  initState() {
    super.initState();
    filterCondController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  List<DataColumn2> _buildFilterCondColumns() {
    List<DataColumn2> dataColumns = [];
    for (var shareColumn in filterCondColumns) {
      dataColumns.add(DataColumn2(
          label: Text(shareColumn.label),
          fixedWidth: shareColumn.width,
          numeric: shareColumn.dataType == DataType.double ||
              shareColumn.dataType == DataType.int));
    }
    dataColumns.add(const DataColumn2(label: Text('')));
    return dataColumns;
  }

  Future<List<DataRow2>> _buildFilterCondRows() async {
    List<DataRow2> rows = [];
    List<FilterCond> data = filterCondController.data;
    for (int index = 0; index < data.length; ++index) {
      FilterCond filterCond = data[index];
      var filterCondMap = JsonUtil.toJson(filterCond);
      List<DataCell> cells = [];
      for (PlatformDataColumn filterCondColumn in filterCondColumns) {
        String name = filterCondColumn.name;
        dynamic fieldValue = filterCondMap[name];
        if (fieldValue != null) {
          if (fieldValue is double) {
            fieldValue = NumberFormatUtil.stdDouble(fieldValue);
          } else {
            fieldValue = fieldValue.toString();
          }
        } else {
          fieldValue = '';
        }

        var dataCell = DataCell(Text(fieldValue!));
        cells.add(dataCell);
      }
      var dataCell = DataCell(IconButton(
        onPressed: () async {
          FilterCond? e = await filterCondService.delete(entity: filterCond);
          if (e != null) {
            filterCondController.delete(index: index);
          }
        },
        icon: const Icon(
          Icons.remove_circle_outline,
          color: Colors.yellow,
        ),
      ));
      cells.add(dataCell);
      var dataRow = DataRow2(
        selected: filterCondController.currentIndex == index,
        cells: cells,
        onDoubleTap: () {
          filterCondController.currentIndex = index;
          swiperController.move(1);
        },
      );
      rows.add(dataRow);
    }
    return rows;
  }

  Widget _buildEventListView(BuildContext context) {
    return FutureBuilder(
        future: _buildFilterCondRows(),
        builder: (BuildContext context, AsyncSnapshot<List<DataRow>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            var value = snapshot.data;
            if (value != null) {
              return DataTable2(
                key: UniqueKey(),
                dataRowHeight: 50,
                minWidth: 1000,
                dividerThickness: 0.0,
                columns: _buildFilterCondColumns(),
                rows: value,
              );
            }
          }
          return LoadingUtil.buildLoadingIndicator();
        });
  }

  _buildFilterCondEditView(BuildContext context) {
    FilterCond? filterCond = filterCondController.current;
    if (filterCond != null) {
      controller.setValues(JsonUtil.toJson(filterCond));
    }
    List<FormButtonDef> formButtonDefs = [
      FormButtonDef(
          label: 'Cancel',
          onTap: (Map<String, dynamic> values) {
            _onCancel(values);
          }),
      FormButtonDef(
          label: 'Ok',
          onTap: (Map<String, dynamic> values) {
            _onOk(values);
          }),
    ];
    var formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: FormInputWidget(
          height: appDataProvider.portraitSize.height * 0.7,
          controller: controller,
          formButtonDefs: formButtonDefs,
        ));

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) async {
    FilterCond currentFilterCond = FilterCond.fromJson(values);
    if (filterCondController.currentIndex == -1) {
      FilterCond? filterCond =
          await filterCondService.insert(currentFilterCond);
      if (filterCond != null) {
        filterCondController.insert(0, filterCond);
      }
    } else {
      FilterCond? filterCond =
          await filterCondService.update(currentFilterCond);
      if (filterCond != null) {
        filterCondController.replace(filterCond);
      }
    }
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Event has save completely'));
    }
  }

  _onCancel(Map<String, dynamic> values) async {
    swiperController.move(0);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      IconButton(
        tooltip: AppLocalizations.t('Add event'),
        onPressed: () {
          filterCondController.currentIndex = -1;
          swiperController.move(1);
          _buildFilterCondEditView(context);
        },
        icon: const Icon(Icons.add_circle_outline),
      ),
      IconButton(
        tooltip: AppLocalizations.t('Refresh event'),
        onPressed: () async {
          List<FilterCond> value = await filterCondService.findAll();
          filterCondController.replaceAll(value);
        },
        icon: const Icon(Icons.refresh_outlined),
      ),
    ];
    return AppBarView(
        title: widget.title,
        withLeading: true,
        rightWidgets: rightWidgets,
        child: Swiper(
          controller: swiperController,
          itemCount: 2,
          index: index,
          itemBuilder: (BuildContext context, int index) {
            Widget view = _buildEventListView(context);
            if (index == 1) {
              view = _buildFilterCondEditView(context);
            }
            return view;
          },
          onIndexChanged: (int index) {
            this.index = index;
          },
        ));
  }

  @override
  void dispose() {
    filterCondController.removeListener(_update);
    super.dispose();
  }
}
