import 'package:colla_chat/entity/stock/event.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/general_remote.dart';
import 'package:colla_chat/service/servicelocator.dart';

class RemoteEventService extends GeneralRemoteService<Event> {
  RemoteEventService({required super.name}) {
    post = (Map map) {
      return Event.fromRemoteJson(map);
    };
  }
}

final RemoteEventService remoteEventService = RemoteEventService(name: 'event');

class EventService extends GeneralBaseService<Event> {
  EventService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return Event.fromJson(map);
    };
  }

  store(Event event) async {
    Event? old =
        await findOne(where: 'eventcode=?', whereArgs: [event.eventCode]);
    if (old == null) {
      event.id = null;
    } else {
      event.id = old.id;
    }
    await upsert(event);
  }
}

final EventService eventService = EventService(
    tableName: 'stk_event',
    fields: ServiceLocator.buildFields(Event('', ''), []),
    indexFields: ['eventCode', 'eventType']);
