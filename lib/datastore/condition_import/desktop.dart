import 'package:colla_chat/plugin/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../platform.dart';
import '../../provider/app_data_provider.dart';

Future<CommonDatabase> openSqlite3({String name = 'colla_chat.db'}) async {
  if (!platformParams.web) {
    /// 除了web之外的创建打开数据库的方式
    final dbFolder = await getApplicationDocumentsDirectory();
    String path = p.join(dbFolder.path, name);
    CommonDatabase db = sqlite3.open(path);
    //logger.i('sqlite3 path:$path');
    appDataProvider.sqlite3Path = path;

    return db;
  }

  throw UnimplementedError('desktop');
}
