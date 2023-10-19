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
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

class LocalEventFilterController extends DataListController<EventFilter> {
  String? _eventCode;
  String? _eventName;

  String? get eventCode {
    return _eventCode;
  }

  String? get eventName {
    return _eventName;
  }

  setEventCode(String? eventCode, {String? eventName}) async {
    if (_eventCode != eventCode) {
      _eventCode = eventCode;
      _eventName = eventName;
      if (_eventCode != null) {
        List<EventFilter> eventFilters = await eventFilterService
            .find(where: 'eventCode=?', whereArgs: [_eventCode!]);
        replaceAll(eventFilters);
      } else {
        data.clear();
      }
      notifyListeners();
    }
  }
}

/// 自选股的控制器
final LocalEventFilterController localEventFilterController =
    LocalEventFilterController();

///自选股和分组的查询界面
class LocalEventFilterWidget extends StatefulWidget with TileDataMixin {
  LocalEventFilterWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LocalEventFilterWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'local_event_filter';

  @override
  IconData get iconData => Icons.filter;

  @override
  String get title => 'LocalEventFilter';
}

class _LocalEventFilterWidgetState extends State<LocalEventFilterWidget>
    with TickerProviderStateMixin {
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
    // PlatformDataField(
    //     name: 'condCode',
    //     label: 'CondCode',
    //     prefixIcon: Icon(
    //       Icons.control_point_duplicate_outlined,
    //       color: myself.primary,
    //     )),
    // PlatformDataField(
    //     name: 'condName',
    //     label: 'CondName',
    //     prefixIcon: Icon(
    //       Icons.person,
    //       color: myself.primary,
    //     )),
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
  late final FormInputController controller =
      FormInputController(eventFilterDataField);
  SwiperController swiperController = SwiperController();
  int index = 0;
  late final List<PlatformDataColumn> eventFilterColumns = [
    PlatformDataColumn(
      label: '事件代码',
      name: 'eventCode',
      width: 90,
    ),
    PlatformDataColumn(
      label: '事件名',
      name: 'eventName',
      width: 80,
    ),
    // PlatformDataColumn(
    //   label: '条件代码',
    //   name: 'condCode',
    //   width: 130,
    // ),
    // PlatformDataColumn(
    //   label: '条件名',
    //   name: 'condName',
    //   width: 180,
    // ),
    PlatformDataColumn(
      label: '条件内容',
      name: 'condContent',
      width: 270,
    ),
    PlatformDataColumn(
      label: '条件参数',
      name: 'condParas',
      width: 100,
    ),
    PlatformDataColumn(
        label: '',
        name: 'action',
        inputType: InputType.custom,
        buildSuffix: _buildActionWidget),
  ];

  @override
  initState() {
    localEventFilterController.addListener(_update);
    super.initState();
  }

  _update() {
    setState(() {});
  }

  Widget _buildActionWidget(int index, dynamic eventFilter) {
    Widget actionWidget = Row(
      children: [
        IconButton(
          onPressed: () async {
            bool? confirm = await DialogUtil.confirm(context,
                content: 'Do you confirm to delete event filter?');
            if (confirm == true) {
              eventFilterService.delete(entity: eventFilter);
              localEventFilterController.delete(index: index);
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
    localEventFilterController.currentIndex = index;
    swiperController.move(1);
  }

  Widget _buildEventFilterListView(BuildContext context) {
    return BindingDataTable2<EventFilter>(
      key: UniqueKey(),
      showCheckboxColumn: false,
      horizontalMargin: 10.0,
      columnSpacing: 0.0,
      fixedLeftColumns: 1,
      platformDataColumns: eventFilterColumns,
      controller: localEventFilterController,
      onDoubleTap: _onDoubleTap,
    );
  }

  _buildEventFilterEditView(BuildContext context) {
    EventFilter? eventFilter = localEventFilterController.current;
    if (eventFilter != null) {
      controller.setValues(eventFilter.toJson());
    } else {
      String? eventCode = localEventFilterController.eventCode;
      String? eventName = localEventFilterController.eventName;
      Map<String, dynamic> json = {};
      if (eventCode != null && eventName != null) {
        json['eventCode'] = eventCode;
        json['eventName'] = eventName;
      }
      controller.setValues(json);
    }
    List<FormButton> formButtonDefs = [
      FormButton(
          label: 'Cancel',
          onTap: (Map<String, dynamic> values) {
            _onCancel(values);
          }),
      FormButton(
          label: 'Copy',
          onTap: (Map<String, dynamic> values) {
            _onCopy(values);
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
          spacing: 5.0,
          controller: controller,
          formButtons: formButtonDefs,
        ));

    return formInputWidget;
  }

  _onOk(Map<String, dynamic> values) async {
    EventFilter currentFilterCond = EventFilter.fromJson(values);
    if (currentFilterCond.id == null) {
      await eventFilterService.insert(currentFilterCond);
      if (currentFilterCond.id != null) {
        localEventFilterController.insert(0, currentFilterCond);
      }
    } else {
      await eventFilterService.update(currentFilterCond);
    }
    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('EventFilter has save completely'));
    }
  }

  _onCopy(Map<String, dynamic> values) async {
    controller.setValue('id', null);
    localEventFilterController.currentIndex = -1;
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
          localEventFilterController.currentIndex = -1;
          swiperController.move(1);
        },
        icon: const Icon(Icons.add_circle_outline),
      ),
      IconButton(
        tooltip: AppLocalizations.t('Refresh'),
        onPressed: () async {
          if (localEventFilterController.eventCode != null) {
            List<EventFilter> value = await eventFilterService.find(
                where: 'eventCode=?',
                whereArgs: [localEventFilterController.eventCode!]);
            localEventFilterController.replaceAll(value);
          } else {
            List<EventFilter> value = await eventFilterService.findAll();
            localEventFilterController.replaceAll(value);
          }
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
            Widget view = _buildEventFilterListView(context);
            if (index == 1) {
              view = _buildEventFilterEditView(context);
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
    localEventFilterController.removeListener(_update);
    super.dispose();
  }
}
