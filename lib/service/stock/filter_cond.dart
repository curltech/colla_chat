import 'package:colla_chat/entity/stock/filter_cond.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/general_remote.dart';
import 'package:colla_chat/service/servicelocator.dart';

class RemoteFilterCondService extends GeneralRemoteService<FilterCond> {
  List<FilterCond>? _filterConds;

  RemoteFilterCondService({required super.name}) {
    post = (Map map) {
      return FilterCond.fromRemoteJson(map);
    };
  }

  Future<List<FilterCond>?> findCachedAll() async {
    _filterConds ??= await super.sendFindAll();

    return _filterConds;
  }

  refresh() {
    _filterConds = null;
  }
}

final RemoteFilterCondService remoteFilterCondService =
    RemoteFilterCondService(name: 'filtercond');

class FilterCondService extends GeneralBaseService<FilterCond> {
  FilterCondService(
      {required super.tableName,
      required super.fields,
      required super.indexFields}) {
    post = (Map map) {
      return FilterCond.fromJson(map);
    };
  }

  store(FilterCond filterCond) async {
    FilterCond? old =
        await findOne(where: 'condcode=?', whereArgs: [filterCond.condCode]);
    if (old == null) {
      filterCond.id = null;
    } else {
      filterCond.id = old.id;
    }
    await upsert(filterCond);
  }
}

final FilterCondService filterCondService = FilterCondService(
    tableName: 'stk_filtercond',
    fields: ServiceLocator.buildFields(FilterCond('', '', ''), []),
    indexFields: ['condCode', 'name']);
