import 'package:colla_chat/entity/stock/event.dart';
import 'package:colla_chat/service/general_remote.dart';

class FilterCondService extends GeneralRemoteService<Event> {
  FilterCondService({required super.name}) {
    post = (Map map) {
      return Event.fromJson(map);
    };
  }
}

final FilterCondService filterCondService =
    FilterCondService(name: 'filterCond');
