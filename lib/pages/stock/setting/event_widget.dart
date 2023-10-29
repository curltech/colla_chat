import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/stock/event.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/setting/event_filter_widget.dart';
import 'package:colla_chat/pages/stock/trade/in_out_event_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/event.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

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
  final List<PlatformDataField> eventDataField = [
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
  late final FormInputController controller;
  SwiperController swiperController = SwiperController();
  int index = 0;
  late final List<PlatformDataColumn> eventColumns;

  @override
  initState() {
    controller = FormInputController(eventDataField);
    eventController.addListener(_update);
    eventColumns = [
      PlatformDataColumn(
        label: '事件代码',
        name: 'eventCode',
        width: 120,
        onSort: (int index, bool ascending) =>
            eventController.sort((t) => t.eventCode, index,'eventCode', ascending),
      ),
      PlatformDataColumn(
        label: '事件类型',
        name: 'eventType',
        width: 120,
      ),
      PlatformDataColumn(
        label: '事件名',
        name: 'eventName',
        width: 140,
      ),
      PlatformDataColumn(
          label: '',
          name: 'action',
          inputType: InputType.custom,
          buildSuffix: _buildActionWidget),
    ];
    super.initState();
  }

  _update() {
    setState(() {});
  }

  Widget _buildActionWidget(int index, dynamic event) {
    Widget actionWidget = Row(
      children: [
        IconButton(
          onPressed: () async {
            bool? confirm = await DialogUtil.confirm(context,
                content: 'Do you confirm to delete event?');
            if (confirm == true) {
              Event? e = await remoteEventService.sendDelete(entity: event);
              if (e != null) {
                eventController.delete(index: index);
              }
            }
          },
          icon: const Icon(
            Icons.remove_circle_outline,
            color: Colors.yellow,
          ),
          tooltip: AppLocalizations.t('Delete'),
        ),
        IconButton(
          onPressed: () async {
            await eventFilterController.setEventCode(event.eventCode,
                eventName: event.eventName);
            indexWidgetProvider.push('event_filter');
          },
          icon: const Icon(
            Icons.filter,
            color: Colors.yellow,
          ),
          tooltip: AppLocalizations.t('EventFilter'),
        ),
        IconButton(
          onPressed: () async {
            await inoutEventController.setEventCode(event.eventCode,
                eventName: event.eventName);
            indexWidgetProvider.push('in_out_event');
          },
          icon: const Icon(
            Icons.event,
            color: Colors.yellow,
          ),
          tooltip: AppLocalizations.t('InoutEvent'),
        )
      ],
    );
    return actionWidget;
  }

  _onDoubleTap(int index) {
    eventController.currentIndex = index;
    swiperController.move(1);
  }

  Widget _buildEventListView(BuildContext context) {
    return BindingDataTable2<Event>(
      key: UniqueKey(),
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      platformDataColumns: eventColumns,
      controller: eventController,
      onDoubleTap: _onDoubleTap,
    );
  }

  _buildEventEditView(BuildContext context) {
    Event? event = eventController.current;
    if (event != null) {
      controller.setValues(event.toRemoteJson());
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
    Event currentEvent = Event.fromRemoteJson(values);
    if (eventController.currentIndex == -1) {
      Event? event = await remoteEventService.sendInsert(currentEvent);
      if (event != null) {
        eventController.insert(0, event);
      }
    } else {
      Event? event = await remoteEventService.sendUpdate(currentEvent);
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
        tooltip: AppLocalizations.t('Add'),
        onPressed: () {
          eventController.currentIndex = -1;
          swiperController.move(1);
          _buildEventEditView(context);
        },
        icon: const Icon(Icons.add_circle_outline),
      ),
      IconButton(
        tooltip: AppLocalizations.t('Refresh'),
        onPressed: () async {
          List<Event> value = await remoteEventService.sendFindAll();
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
