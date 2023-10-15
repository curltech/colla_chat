import 'package:colla_chat/entity/stock/event.dart';
import 'package:colla_chat/service/general_remote.dart';

class EventService extends GeneralRemoteService<Event> {
  EventService({required super.name});
}

final eventService = EventService(name: 'event');
