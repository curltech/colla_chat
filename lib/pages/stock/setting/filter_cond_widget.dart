import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/stock/filter_cond.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/filter_cond.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

/// 自选股的控制器
final DataListController<FilterCond> filterCondController =
    DataListController<FilterCond>();

///自选股和分组的查询界面
class FilterCondWidget extends StatefulWidget with TileDataMixin {
  FilterCondWidget({super.key});

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
  final List<PlatformDataField> filterCondDataField = [
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
  late final FormInputController controller =
      FormInputController(filterCondDataField);
  SwiperController swiperController = SwiperController();
  int index = 0;
  late final List<PlatformDataColumn> filterCondColumns = [
    PlatformDataColumn(
      label: '条件代码',
      name: 'condCode',
      width: 150,
    ),
    PlatformDataColumn(
      label: '条件名',
      name: 'name',
      width: 200,
    ),
    PlatformDataColumn(
      label: '条件类型',
      name: 'condType',
      width: 100,
      onSort: (int index, bool ascending) => filterCondController.sort(
          (t) => t.condType, index, 'condType', ascending),
    ),
    PlatformDataColumn(
      label: '条件公式',
      name: 'content',
      width: 250,
    ),
    PlatformDataColumn(
      label: '条件参数',
      name: 'condParas',
      width: 200,
    ),
    PlatformDataColumn(
        label: '',
        name: 'action',
        inputType: InputType.custom,
        buildSuffix: _buildActionWidget),
  ];

  @override
  initState() {
    super.initState();
    filterCondController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildActionWidget(int index, dynamic filterCond) {
    Widget actionWidget = IconButton(
      onPressed: () async {
        bool? confirm = await DialogUtil.confirm(context,
            content: 'Do you confirm to delete filterCond?');
        if (confirm == true) {
          FilterCond? e =
              await remoteFilterCondService.sendDelete(entity: filterCond);
          if (e != null) {
            filterCondController.delete(index: index);
          }
        }
      },
      icon: const Icon(
        Icons.remove_circle_outline,
        color: Colors.yellow,
      ),
      tooltip: AppLocalizations.t('Delete'),
    );

    return actionWidget;
  }

  _onDoubleTap(int index) {
    filterCondController.currentIndex = index;
    swiperController.move(1);
  }

  Widget _buildFilterCondListView(BuildContext context) {
    return BindingDataTable2<FilterCond>(
      key: UniqueKey(),
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      fixedLeftColumns: 1,
      platformDataColumns: filterCondColumns,
      controller: filterCondController,
      onDoubleTap: _onDoubleTap,
    );
  }

  _buildFilterCondEditView(BuildContext context) {
    FilterCond? filterCond = filterCondController.current;
    if (filterCond != null) {
      controller.setValues(filterCond.toRemoteJson());
    } else {
      controller.setValues({});
    }
    List<FormButton> formButtonDefs = [
      FormButton(
          label: 'Cancel',
          onTap: (Map<String, dynamic> values) {
            _onCancel(values);
          }),
      FormButton(
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
          formButtons: formButtonDefs,
        ));

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) async {
    FilterCond currentFilterCond = FilterCond.fromRemoteJson(values);
    if (filterCondController.currentIndex == -1) {
      FilterCond? filterCond =
          await remoteFilterCondService.sendInsert(currentFilterCond);
      if (filterCond != null) {
        filterCondController.insert(0, filterCond);
      }
    } else {
      FilterCond? filterCond =
          await remoteFilterCondService.sendUpdate(currentFilterCond);
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
        tooltip: AppLocalizations.t('Add'),
        onPressed: () {
          filterCondController.currentIndex = -1;
          swiperController.move(1);
          _buildFilterCondEditView(context);
        },
        icon: const Icon(Icons.add_circle_outline),
      ),
      IconButton(
        tooltip: AppLocalizations.t('Refresh'),
        onPressed: () async {
          List<FilterCond> value = await remoteFilterCondService.sendFindAll();
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
            Widget view = _buildFilterCondListView(context);
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
