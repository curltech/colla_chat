import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/stock/event.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/me/dayline_chart_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/event.dart';
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

final List<PlatformDataField> eventColumnFieldDefs = [
  PlatformDataField(
      name: 'eventCode',
      label: 'EventCode',
      inputType: InputType.label,
      prefixIcon: Icon(
        Icons.perm_identity,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'eventType',
      label: 'EventType',
      prefixIcon: Icon(
        Icons.type_specimen_outlined,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'eventName',
      label: 'EventName',
      prefixIcon: Icon(
        Icons.person,
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
final DataListController<Event> eventController = DataListController<Event>();

///自选股和分组的查询界面
class EventWidget extends StatefulWidget with TileDataMixin {
  EventWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EventWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'event';

  @override
  IconData get iconData => Icons.event_available_outlined;

  @override
  String get title => 'Event';
}

class _EventWidgetState extends State<EventWidget>
    with TickerProviderStateMixin {
  bool editMode = false;
  final FormInputController controller =
      FormInputController(eventColumnFieldDefs);
  SwiperController swiperController = SwiperController();
  int index = 0;
  final List<PlatformDataColumn> eventColumns = [
    PlatformDataColumn(
      label: '事件代码',
      name: 'eventCode',
    ),
    PlatformDataColumn(
      label: '事件类型',
      name: 'eventType',
    ),
    PlatformDataColumn(
      label: '事件名',
      name: 'eventName',
    ),
  ];

  @override
  initState() {
    super.initState();
    eventController.addListener(_update);
  }

  _update() {
    _buildEventRows();
  }

  List<DataColumn2> _buildEventColumns() {
    List<DataColumn2> dataColumns = [];
    for (var shareColumn in eventColumns) {
      dataColumns.add(DataColumn2(
          label: Text(shareColumn.label),
          fixedWidth: 130,
          numeric: shareColumn.dataType == DataType.double ||
              shareColumn.dataType == DataType.int));
    }
    return dataColumns;
  }

  Future<List<DataRow2>> _buildEventRows() async {
    List<DataRow2> rows = [];
    List<Event> data = eventController.data;
    if (data.isEmpty) {
      List<Event> value = await eventService.findAll();
      eventController.replaceAll(value);
      data = eventController.data;
    }
    for (int index = 0; index < data.length; ++index) {
      Event event = data[index];
      var eventMap = JsonUtil.toJson(event);
      List<DataCell> cells = [];
      for (PlatformDataColumn eventColumn in eventColumns) {
        String name = eventColumn.name;
        String? value;
        dynamic fieldValue = eventMap[name];
        if (fieldValue != null) {
          if (fieldValue is double) {
            fieldValue = NumberFormatUtil.stdDouble(fieldValue);
          } else {
            fieldValue = fieldValue.toString();
          }
        } else {
          fieldValue = '';
        }

        var dataCell = DataCell(Text(value!));
        cells.add(dataCell);
      }
      var dataRow = DataRow2(
        selected: eventController.currentIndex == index,
        cells: cells,
        onTap: () {
          eventController.currentIndex = index;
          editMode = true;
        },
      );
      rows.add(dataRow);
    }
    return rows;
  }

  Widget _buildEventListView(BuildContext context) {
    return FutureBuilder(
        future: _buildEventRows(),
        builder: (BuildContext context, AsyncSnapshot<List<DataRow>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            var value = snapshot.data;
            if (value != null) {
              return DataTable2(
                key: UniqueKey(),
                minWidth: 2000,
                dataRowHeight: 50,
                fixedLeftColumns: 1,
                dividerThickness: 0.0,
                columns: _buildEventColumns(),
                rows: value,
              );
            }
          }
          return LoadingUtil.buildLoadingIndicator();
        });
  }

  _buildEventEditView(BuildContext context) {
    Event? event = eventController.current;
    if (event != null) {
      controller.setValues(JsonUtil.toJson(event));
    }
    List<FormButtonDef> formButtonDefs = [
      FormButtonDef(
          label: 'Ok',
          onTap: (Map<String, dynamic> values) {
            _onOk(values);
          }),
      FormButtonDef(
          label: 'Cancel',
          onTap: (Map<String, dynamic> values) {
            _onCancel(values);
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
    Event currentEvent = Event.fromJson(values);
    if (eventController.currentIndex == -1) {
      await eventService.insert(currentEvent);
      eventController.add(currentEvent);
    } else {
      await eventService.update(currentEvent);
    }
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Event has save completely'));
    }
  }

  _onCancel(Map<String, dynamic> values) async {
    editMode = false;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      IconButton(
        tooltip: AppLocalizations.t('Add event'),
        onPressed: () {
          eventController.currentIndex = -1;
          editMode = true;
        },
        icon: const Icon(Icons.add_circle_outline),
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
              view = _buildEventEditView(context);
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
    eventController.removeListener(_update);
    super.dispose();
  }
}
