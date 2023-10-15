import 'package:colla_chat/entity/stock/event.dart';
import 'package:colla_chat/entity/stock/filter_cond.dart';
import 'package:colla_chat/service/general_remote.dart';

class FilterCondService extends GeneralRemoteService<FilterCond> {
  FilterCondService({required super.name}) {
    post = (Map map) {
      return FilterCond.fromJson(map);
    };
  }
}

final FilterCondService filterCondService =
    FilterCondService(name: 'filtercond');
