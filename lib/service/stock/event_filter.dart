import 'package:colla_chat/entity/stock/event_filter.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';

final List<Option> inEventOption = [
  Option('红杏出墙', 'RedApricots', hint: '下跌盘整一段时间后，均线走平，形成弯月底，中阳放量站上13日线'),
  Option('鸿雁南回', 'SwanSouth', hint: '上涨过程中，缩量回调'),
  Option('三箭齐发', 'ThreeArrow', hint: '盘整一段时间后，均线汇聚走平，大阳放量'),
];

final List<Option> outEventOption = [
  Option('一剑穿心', 'SwordHeart', hint: '阴线，长上影线，量能放大'),
  Option('惊鸿照影', 'GreenShadow', hint: '阴线，最高价高于昨日最高价，最低价低于昨日最低价'),
  Option('石破天惊', 'StoneSky', hint: '阴线，最高价低于昨日最低价'),
];

class EventFilterService extends GeneralBaseService<EventFilter> {
  EventFilterService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return EventFilter.fromJson(map);
    };
  }
}

final EventFilterService eventFilterService = EventFilterService(
    tableName: 'stk_eventfilter',
    fields: ServiceLocator.buildFields(EventFilter('', ''), []),
    indexFields: ['eventCode', 'eventName']);
