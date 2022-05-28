import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../platform.dart';

Future<CommonDatabase> openSqlite3({String name = 'colla_chat.db'}) async {
  var platformParams = await PlatformParams.instance;
  if (!platformParams.web) {
    /// 除了web之外的创建打开数据库的方式
    final dbFolder = await getApplicationDocumentsDirectory();
    String path = p.join(dbFolder.path, name);
    CommonDatabase db = sqlite3.open(path);

    return db;
  }

  throw UnimplementedError('desktop');
}
