import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/stock/event_filter.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/trade/in_out_event_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/event_filter.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EventFilterController extends DataListController<EventFilter> {
  final Rx<String?> _eventCode = Rx<String?>(null);
  final Rx<String?> _eventName = Rx<String?>(null);

  String? get eventCode {
    return _eventCode.value;
  }

  String? get eventName {
    return _eventName.value;
  }

  setEventCode(String? eventCode, {String? eventName}) async {
    _eventCode(eventCode);
    _eventName(eventName);
    if (eventCode != null) {
      List<EventFilter> eventFilters = await eventFilterService
          .find(where: 'eventCode=?', whereArgs: [_eventCode.value!]);
      replaceAll(eventFilters);
    } else {
      data.clear();
    }
  }
}

/// 自选股的控制器
final EventFilterController eventFilterController = EventFilterController();

///自选股和分组的查询界面
class EventFilterWidget extends StatelessWidget with TileDataMixin {
  EventFilterWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'event_filter';

  @override
  IconData get iconData => Icons.filter;

  @override
  String get title => 'EventFilter';

  

  final List<PlatformDataField> eventFilterDataField = [
    PlatformDataField(
        name: 'id',
        label: 'Id',
        inputType: InputType.label,
        prefixIcon: Icon(
          Icons.perm_identity_outlined,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'eventCode',
        label: 'EventCode',
        prefixIcon: Icon(
          Icons.code,
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
        name: 'condContent',
        label: 'CondContent',
        minLines: 4,
        prefixIcon: Icon(
          Icons.content_paste,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'condParas',
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
  late final FormInputController formInputController =
      FormInputController(eventFilterDataField);
  SwiperController swiperController = SwiperController();
  RxInt index = 0.obs;

  Widget _buildActionWidget(
      BuildContext context, int index, dynamic eventFilter) {
    Widget actionWidget = Row(
      children: [
        IconButton(
          onPressed: () async {
            bool? confirm = await DialogUtil.confirm(
                content: 'Do you confirm to delete event filter?');
            if (confirm == true) {
              eventFilterService.delete(entity: eventFilter);
              eventFilterController.delete(index: index);
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
            await inoutEventController.setEventCode(eventFilter.eventCode,
                eventName: eventFilter.eventName);
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
    eventFilterController.setCurrentIndex = index;
    swiperController.move(1);
  }

  Widget _buildEventFilterListView(BuildContext context) {
    final List<PlatformDataColumn> eventFilterColumns = [
      PlatformDataColumn(
        label: '事件代码',
        name: 'eventCode',
        width: 80,
      ),
      PlatformDataColumn(
        label: '事件名',
        name: 'eventName',
        width: 100,
      ),
      PlatformDataColumn(
        label: '条件内容',
        name: 'condContent',
        width: 270,
      ),
      PlatformDataColumn(
          label: '',
          name: 'action',
          inputType: InputType.custom,
          buildSuffix: (int index, dynamic eventFilter) {
            return _buildActionWidget(context, index, eventFilter);
          }),
    ];
    return BindingTrinaDataGrid<EventFilter>(
      key: UniqueKey(),
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      fixedLeftColumns: 1,
      dataRowHeight: 100,
      platformDataColumns: eventFilterColumns,
      controller: eventFilterController,
      onDoubleTap: _onDoubleTap,
    );
  }

  _buildEventFilterEditView(BuildContext context) {
    EventFilter? eventFilter = eventFilterController.current;
    if (eventFilter != null) {
      formInputController.setValues(eventFilter.toJson());
    } else {
      String? eventCode = eventFilterController.eventCode;
      String? eventName = eventFilterController.eventName;
      Map<String, dynamic> json = {};
      if (eventCode != null && eventName != null) {
        json['eventCode'] = eventCode;
        json['eventName'] = eventName;
      }
      formInputController.setValues(json);
    }
    List<FormButton> formButtonDefs = [
      FormButton(
          label: 'Copy',
          onTap: (Map<String, dynamic> values) {
            _onCopy(values);
          }),
      FormButton(
          label: 'Ok',
          onTap: (Map<String, dynamic> values) {
            _onOk(context, values);
          }),
    ];
    var formInputWidget = Container(
        padding: const EdgeInsets.all(10.0),
        child: FormInputWidget(
          height: appDataProvider.portraitSize.height * 0.7,
          spacing: 5.0,
          controller: formInputController,
          formButtons: formButtonDefs,
        ));

    return Column(
      children: [
        OverflowBar(
          alignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                _onCancel();
              },
            ),
          ],
        ),
        formInputWidget,
      ],
    );
  }

  _onOk(BuildContext context, Map<String, dynamic> values) async {
    EventFilter currentFilterCond = EventFilter.fromJson(values);
    if (currentFilterCond.id == null) {
      await eventFilterService.insert(currentFilterCond);
      if (currentFilterCond.id != null) {
        eventFilterController.insert(0, currentFilterCond);
      }
    } else {
      await eventFilterService.update(currentFilterCond);
    }
    DialogUtil.info(
        content: AppLocalizations.t('EventFilter has save completely'));
  }

  _onCopy(Map<String, dynamic> values) async {
    formInputController.setValue('id', null);
    eventFilterController.setCurrentIndex = -1;
  }

  _onCancel() async {
    swiperController.move(0);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      IconButton(
        tooltip: AppLocalizations.t('Add'),
        onPressed: () {
          eventFilterController.setCurrentIndex = -1;
          swiperController.move(1);
        },
        icon: const Icon(Icons.add_circle_outline),
      ),
      IconButton(
        tooltip: AppLocalizations.t('Refresh'),
        onPressed: () async {
          if (eventFilterController.eventCode != null) {
            List<EventFilter> value = await eventFilterService.find(
                where: 'eventCode=?',
                whereArgs: [eventFilterController.eventCode!]);
            eventFilterController.replaceAll(value);
          } else {
            List<EventFilter> value = await eventFilterService.findAll();
            eventFilterController.replaceAll(value);
          }
        },
        icon: const Icon(Icons.refresh_outlined),
      ),
    ];
    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: true,
      rightWidgets: rightWidgets,
      child: Obx(() {
        return Swiper(
          controller: swiperController,
          itemCount: 2,
          index: index.value,
          itemBuilder: (BuildContext context, int index) {
            Widget view = _buildEventFilterListView(context);
            if (index == 1) {
              view = _buildEventFilterEditView(context);
            }
            return view;
          },
          onIndexChanged: (int index) {
            this.index.value = index;
          },
        );
      }),
    );
  }
}
