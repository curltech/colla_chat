import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/stock/event.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
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

final List<PlatformDataField> eventFieldDefs = [
  PlatformDataField(
      name: 'id',
      label: 'Id',
      inputType: InputType.label,
      prefixIcon: Icon(
        Icons.perm_identity_outlined,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'event_code',
      label: 'EventCode',
      prefixIcon: Icon(
        Icons.code,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'event_type',
      label: 'EventType',
      prefixIcon: Icon(
        Icons.type_specimen_outlined,
        color: myself.primary,
      )),
  PlatformDataField(
      name: 'event_name',
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
  final FormInputController controller =
      FormInputController(eventFieldDefs);
  SwiperController swiperController = SwiperController();
  int index = 0;
  final List<PlatformDataColumn> eventColumns = [
    PlatformDataColumn(
      label: '事件代码',
      name: 'event_code',
    ),
    PlatformDataColumn(
      label: '事件类型',
      name: 'event_type',
    ),
    PlatformDataColumn(
      label: '事件名',
      name: 'event_name',
    ),
  ];

  @override
  initState() {
    super.initState();
    eventController.addListener(_update);
  }

  _update() {
    setState(() {});
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
    dataColumns.add(const DataColumn2(label: Text('')));
    return dataColumns;
  }

  Future<List<DataRow2>> _buildEventRows() async {
    List<DataRow2> rows = [];
    List<Event> data = eventController.data;
    for (int index = 0; index < data.length; ++index) {
      Event event = data[index];
      var eventMap = JsonUtil.toJson(event);
      List<DataCell> cells = [];
      for (PlatformDataColumn eventColumn in eventColumns) {
        String name = eventColumn.name;
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

        var dataCell = DataCell(Text(fieldValue!));
        cells.add(dataCell);
      }
      var dataCell = DataCell(IconButton(
        onPressed: () async {
          Event? e = await eventService.delete(entity: event);
          if (e != null) {
            eventController.delete(index: index);
          }
        },
        icon: const Icon(
          Icons.remove_circle_outline,
          color: Colors.yellow,
        ),
      ));
      cells.add(dataCell);
      var dataRow = DataRow2(
        selected: eventController.currentIndex == index,
        cells: cells,
        onDoubleTap: () {
          eventController.currentIndex = index;
          swiperController.move(1);
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
                dataRowHeight: 50,
                minWidth: 1000,
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
    Event currentEvent = Event.fromJson(values);
    if (eventController.currentIndex == -1) {
      await eventService.insert(currentEvent);
      eventController.insert(0, currentEvent);
    } else {
      Event? event = await eventService.update(currentEvent);
      if (event != null) {
        eventController.replace(event);
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
          eventController.currentIndex = -1;
          swiperController.move(1);
          _buildEventEditView(context);
        },
        icon: const Icon(Icons.add_circle_outline),
      ),
      IconButton(
        tooltip: AppLocalizations.t('Refresh event'),
        onPressed: () async {
          List<Event> value = await eventService.findAll();
          eventController.replaceAll(value);
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
