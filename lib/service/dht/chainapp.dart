import 'package:colla_chat/service/servicelocator.dart';

import '../../entity/dht/chainapp.dart';
import '../general_base.dart';

class ChainAppService extends GeneralBaseService<ChainApp> {
  ChainAppService(
      {required super.tableName,
      required super.fields,
        super.uniqueFields,
        super.indexFields,
        super.encryptFields}) {
    post = (Map map) {
      return ChainApp.fromJson(map);
    };
  }
}

final chainAppService = ChainAppService(
    tableName: "blc_chainapp",
    fields: ServiceLocator.buildFields(ChainApp(), []),
    indexFields: const <String>[]);
