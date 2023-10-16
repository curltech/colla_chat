import 'package:colla_chat/entity/stock/event.dart';
import 'package:colla_chat/entity/stock/event_filter.dart';
import 'package:colla_chat/service/general_remote.dart';

class EventFilterService extends GeneralRemoteService<EventFilter> {
  EventFilterService({required super.name}){
    post = (Map map) {
      return EventFilter.fromJson(map);
    };
  }
}

final EventFilterService eventFilterService = EventFilterService(name: 'eventfilter');
