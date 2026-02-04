import 'package:carousel_slider_plus/carousel_options.dart';
import 'package:colla_chat/entity/stock/event_filter.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/stock/stock_widget.dart';
import 'package:colla_chat/pages/stock/trade/in_out_event_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/stock/event_filter.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/platform_carousel.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/binging_trina_data_grid.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_data_field.dart';
import 'package:colla_chat/widgets/data_bind/form/platform_reactive_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:reactive_forms/reactive_forms.dart';

class EventFilterController extends DataListController<EventFilter> {
  final Rx<String?> _eventCode = Rx<String?>(null);
  final Rx<String?> _eventName = Rx<String?>(null);

  String? get eventCode {
    return _eventCode.value;
  }

  String? get eventName {
    return _eventName.value;
  }

  Future<void> setEventCode(String? eventCode, {String? eventName}) async {
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

/// 管理自定义的事件过滤器，事件过滤器的条件为股票的查询条件
class EventFilterWidget extends StatelessWidget with DataTileMixin {
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
        label: AppLocalizations.t('id'),
        inputType: InputType.label,
        prefixIcon: Icon(
          Icons.perm_identity_outlined,
          color: myself.primary,
        )),
    PlatformDataField(
      name: 'eventCode',
      label: AppLocalizations.t('eventCode'),
      prefixIcon: Icon(
        Icons.code,
        color: myself.primary,
      ),
      validators: [Validators.required],
      validationMessages: {
        ValidationMessage.required: (_) => 'The eventCode must not be empty',
      },
    ),
    PlatformDataField(
      name: 'eventName',
      label: AppLocalizations.t('eventName'),
      prefixIcon: Icon(
        Icons.person,
        color: myself.primary,
      ),
      validators: [Validators.required],
      validationMessages: {
        ValidationMessage.required: (_) => 'The eventName must not be empty',
      },
    ),
    PlatformDataField(
      name: 'condContent',
      label: AppLocalizations.t('condContent'),
      minLines: 4,
      prefixIcon: Icon(
        Icons.content_paste,
        color: myself.primary,
      ),
      validators: [Validators.required],
      validationMessages: {
        ValidationMessage.required: (_) => 'The condContent must not be empty',
      },
    ),
    PlatformDataField(
        name: 'condParas',
        label: AppLocalizations.t('condParas'),
        prefixIcon: Icon(
          Icons.attribution_outlined,
          color: myself.primary,
        )),
    PlatformDataField(
        name: 'descr',
        label: AppLocalizations.t('Descr'),
        prefixIcon: Icon(
          Icons.description_outlined,
          color: myself.primary,
        )),
  ];
  late final PlatformReactiveFormController platformReactiveFormController =
      PlatformReactiveFormController(eventFilterDataField);
  final PlatformCarouselController controller = PlatformCarouselController();
  final RxInt index = 0.obs;

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
            inoutEventController.setEventCode(eventFilter.eventCode,
                eventName: eventFilter.eventName);
            stockController.push('in_out_event');
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

  void _onDoubleTap(int index) {
    eventFilterController.setCurrentIndex = index;
    controller.move(1);
  }

  Widget _buildEventFilterListView(BuildContext context) {
    final List<PlatformDataColumn> eventFilterColumns = [
      PlatformDataColumn(
        label: AppLocalizations.t('eventCode'),
        name: 'eventCode',
        width: 150,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('eventName'),
        name: 'eventName',
        width: 150,
      ),
      PlatformDataColumn(
        label: AppLocalizations.t('condContent'),
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
      platformDataColumns: eventFilterColumns,
      controller: eventFilterController,
      onDoubleTap: _onDoubleTap,
    );
  }

  Container _buildEventFilterEditView(BuildContext context) {
    EventFilter? eventFilter = eventFilterController.current;
    if (eventFilter != null) {
      platformReactiveFormController.values = eventFilter.toJson();
    } else {
      String? eventCode = eventFilterController.eventCode;
      String? eventName = eventFilterController.eventName;
      Map<String, dynamic> json = {};
      if (eventCode != null && eventName != null) {
        json['eventCode'] = eventCode;
        json['eventName'] = eventName;
      }
      platformReactiveFormController.values = json;
    }
    var platformReactiveForm = Container(
        padding: const EdgeInsets.all(10.0),
        child: PlatformReactiveForm(
          height: appDataProvider.portraitSize.height * 0.7,
          spacing: 5.0,
          platformReactiveFormController: platformReactiveFormController,
          onSubmit: (Map<String, dynamic> values) {
            _onSubmit(context, values);
          },
        ));

    return platformReactiveForm;
  }

  Future<void> _onSubmit(
      BuildContext context, Map<String, dynamic> values) async {
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

  Future<void> _onCopy(Map<String, dynamic> values) async {
    platformReactiveFormController.setValue('id', null);
    eventFilterController.setCurrentIndex = -1;
  }

  Widget _buildRightWidget(BuildContext context) {
    return Obx(() {
      List<Widget> rightWidgets = [];
      if (index.value == 0) {
        rightWidgets.addAll([
          IconButton(
            tooltip: AppLocalizations.t('Add'),
            onPressed: () {
              eventFilterController.setCurrentIndex = -1;
              controller.move(1);
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
        ]);
      }
      if (index.value == 1) {
        rightWidgets.addAll([
          IconButton(
            tooltip: AppLocalizations.t('List'),
            onPressed: () {
              eventFilterController.setCurrentIndex = -1;
              controller.move(0);
            },
            icon: const Icon(Icons.list_alt_outlined),
          ),
        ]);
      }
      return Row(children: rightWidgets);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      helpPath: routeName,
      isAppBar: false,
      rightWidgets: [_buildRightWidget(context)],
      child: Obx(() {
        return PlatformCarouselWidget(
          controller: controller,
          itemCount: 2,
          initialPage: index.value,
          itemBuilder: (BuildContext context, int index, {int? realIndex}) {
            Widget view = _buildEventFilterListView(context);
            if (index == 1) {
              view = _buildEventFilterEditView(context);
            }
            return view;
          },
          onPageChanged: (int index,
              {PlatformSwiperDirection? direction,
              int? oldIndex,
              CarouselPageChangedReason? reason}) {
            this.index.value = index;
          },
        );
      }),
    );
  }
}
