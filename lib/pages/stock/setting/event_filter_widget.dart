import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/stock/event_filter.dart';
import 'package:colla_chat/entity/stock/filter_cond.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/event_filter.dart';
import 'package:colla_chat/service/stock/filter_cond.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_data_table2.dart';
import 'package:colla_chat/widgets/data_bind/column_field_widget.dart';
import 'package:colla_chat/widgets/data_bind/form_input_widget.dart';
import 'package:flutter/material.dart';

class EventFilterController extends DataListController<EventFilter> {
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
        List<EventFilter> eventFilters = await remoteEventFilterService
            .sendFind(condiBean: {'event_code': _eventCode}, limit: 1000);
        replaceAll(eventFilters);
      } else {
        data.clear();
      }
      notifyListeners();
    }
  }
}

/// 自选股的控制器
final EventFilterController eventFilterController = EventFilterController();

///自选股和分组的查询界面
class EventFilterWidget extends StatefulWidget with TileDataMixin {
  EventFilterWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EventFilterWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'event_filter';

  @override
  IconData get iconData => Icons.filter;

  @override
  String get title => 'EventFilter';
}

class _EventFilterWidgetState extends State<EventFilterWidget>
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
        name: 'event_code',
        label: 'EventCode',
        inputType: InputType.label,
        prefixIcon: Icon(
          Icons.code,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'event_name',
        label: 'EventName',
        inputType: InputType.label,
        prefixIcon: Icon(
          Icons.person,
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
        name: 'cond_alias',
        label: 'CondAlias',
        prefixIcon: Icon(
          Icons.type_specimen_outlined,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'cond_name',
        label: 'condName',
        prefixIcon: Icon(
          Icons.person,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'cond_content',
        label: 'CondContent',
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
    PlatformDataColumn(
      label: '条件代码',
      name: 'condCode',
      width: 130,
    ),
    PlatformDataColumn(
      label: '条件名',
      name: 'condName',
      width: 180,
    ),
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

  final DataListController<FilterCond> filterCondController =
      DataListController<FilterCond>();

  late final List<PlatformDataColumn> filterCondColumns = [
    PlatformDataColumn(
      label: '条件代码',
      name: 'condCode',
      width: 150,
    ),
    PlatformDataColumn(
      label: '条件类型',
      name: 'condType',
      width: 100,
      onSort: (int index, bool ascending) =>
          filterCondController.sort((t) => t.condType, index, ascending),
    ),
    PlatformDataColumn(
      label: '条件名',
      name: 'name',
      width: 200,
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
  ];

  @override
  initState() {
    remoteFilterCondService.findCachedAll().then((value) {
      if (value != null) {
        filterCondController.replaceAll(value);
      } else {
        filterCondController.clear();
      }
    });
    eventFilterController.addListener(_update);
    super.initState();
  }

  _update() {
    setState(() {});
  }

  Widget _buildActionWidget(int index, dynamic eventFilter) {
    Widget actionWidget = IconButton(
      onPressed: () async {
        EventFilter? e =
            await remoteEventFilterService.sendDelete(entity: eventFilter);
        if (e != null) {
          eventFilterController.delete(index: index);
        }
      },
      icon: const Icon(
        Icons.remove_circle_outline,
        color: Colors.yellow,
      ),
    );

    return actionWidget;
  }

  _onDoubleTap(int index) {
    eventFilterController.currentIndex = index;
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
      controller: eventFilterController,
      onDoubleTap: _onDoubleTap,
    );
  }

  _buildEventFilterEditView(BuildContext context) {
    EventFilter? eventFilter = eventFilterController.current;
    if (eventFilter != null) {
      controller.setValues(eventFilter.toRemoteJson());
    } else {
      String? eventCode = eventFilterController.eventCode;
      String? eventName = eventFilterController.eventName;
      Map<String, dynamic> json = {};
      if (eventCode != null && eventName != null) {
        json['event_code'] = eventCode;
        json['event_name'] = eventName;
      }
      controller.setValues(json);
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
    EventFilter currentFilterCond = EventFilter.fromRemoteJson(values);
    if (eventFilterController.currentIndex == -1) {
      EventFilter? filterCond =
          await remoteEventFilterService.sendInsert(currentFilterCond);
      if (filterCond != null) {
        eventFilterController.insert(0, filterCond);
      }
    } else {
      EventFilter? eventFilter =
          await remoteEventFilterService.sendUpdate(currentFilterCond);
      if (eventFilter != null) {
        eventFilterController.replace(eventFilter);
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

  /// 过滤条件的多项选择框的表
  Widget _buildFilterCondListView(BuildContext context) {
    ButtonStyle style = StyleUtil.buildButtonStyle();
    ButtonStyle mainStyle = StyleUtil.buildButtonStyle(
        backgroundColor: myself.primary, elevation: 10.0);
    Widget view = Column(
      children: [
        ButtonBar(
          children: [
            TextButton(
              style: style,
              child: CommonAutoSizeText(AppLocalizations.t('Cancel')),
              onPressed: () {
                swiperController.move(0);
              },
            ),
            TextButton(
              style: mainStyle,
              child: CommonAutoSizeText(AppLocalizations.t('Refresh')),
              onPressed: () async {
                remoteFilterCondService.refresh();
                List<FilterCond>? filterConds =
                    await remoteFilterCondService.findCachedAll();
                if (filterConds != null) {
                  filterCondController.replaceAll(filterConds);
                } else {
                  filterCondController.clear();
                }
              },
            ),
            TextButton(
              style: mainStyle,
              child: CommonAutoSizeText(AppLocalizations.t('Ok')),
              onPressed: () async {
                String? eventCode = eventFilterController.eventCode;
                String? eventName = eventFilterController.eventName;
                if (eventCode == null || eventName == null) {
                  return;
                }
                List<FilterCond> filterConds = filterCondController.checked;
                for (var filterCond in filterConds) {
                  EventFilter eventFilter = EventFilter(eventCode, eventName);
                  eventFilter.condCode = filterCond.condCode;
                  eventFilter.condName = filterCond.name;
                  eventFilter.condContent = filterCond.content;
                  eventFilter.condParas = filterCond.condParas;
                  eventFilter.condAlias = filterCond.name;
                  eventFilter.codeAlias = filterCond.condCode;
                  EventFilter? filter =
                      await remoteEventFilterService.sendInsert(eventFilter);
                  if (filter != null) {
                    eventFilterController.insert(0, filter);
                  }
                }
                swiperController.move(0);
              },
            )
          ],
        ),
        Expanded(
            child: BindingDataTable2<FilterCond>(
          key: UniqueKey(),
          showCheckboxColumn: true,
          horizontalMargin: 10.0,
          columnSpacing: 0.0,
          platformDataColumns: filterCondColumns,
          controller: filterCondController,
        )),
      ],
    );

    return view;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> rightWidgets = [
      IconButton(
        tooltip: AppLocalizations.t('Add event filter'),
        onPressed: () {
          eventFilterController.currentIndex = -1;
          swiperController.move(2);
        },
        icon: const Icon(Icons.add_circle_outline),
      ),
      IconButton(
        tooltip: AppLocalizations.t('Refresh event filter'),
        onPressed: () async {
          if (eventFilterController.eventCode != null) {
            List<EventFilter> value =
                await remoteEventFilterService.sendFind(condiBean: {
              'event_code': eventFilterController.eventCode,
            }, limit: 1000);
            eventFilterController.replaceAll(value);
          }
        },
        icon: const Icon(Icons.refresh_outlined),
      ),
    ];
    return AppBarView(
        title:
            '${eventFilterController.eventCode ?? ''}-${eventFilterController.eventName ?? ''}',
        withLeading: true,
        rightWidgets: rightWidgets,
        child: Swiper(
          controller: swiperController,
          itemCount: 3,
          index: index,
          itemBuilder: (BuildContext context, int index) {
            Widget view = _buildEventFilterListView(context);
            if (index == 1) {
              view = _buildEventFilterEditView(context);
            }
            if (index == 2) {
              view = _buildFilterCondListView(context);
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
    eventFilterController.removeListener(_update);
    super.dispose();
  }
}
