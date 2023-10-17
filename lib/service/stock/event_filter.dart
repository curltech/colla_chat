import 'package:colla_chat/entity/stock/event.dart';
import 'package:colla_chat/entity/stock/event_filter.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/general_remote.dart';
import 'package:colla_chat/service/servicelocator.dart';

class RemoteEventFilterService extends GeneralRemoteService<EventFilter> {
  RemoteEventFilterService({required super.name}) {
    post = (Map map) {
      return EventFilter.fromJson(map);
    };
  }
}

final RemoteEventFilterService remoteEventFilterService =
    RemoteEventFilterService(name: 'eventfilter');

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
    tableName: 'stk_eventFilter',
    fields: ServiceLocator.buildFields(EventFilter('', ''), []),
    indexFields: ['eventCode', 'eventType', 'condCode', 'condName']);
