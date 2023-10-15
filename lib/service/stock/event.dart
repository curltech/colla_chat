import 'package:colla_chat/entity/stock/event.dart';
import 'package:colla_chat/service/general_remote.dart';

class EventService extends GeneralRemoteService<Event> {
  EventService({required super.name}) {
    post = (Map map) {
      return Event.fromJson(map);
    };
  }
}

final EventService eventService = EventService(name: 'event');
