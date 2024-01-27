import 'dart:io';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

Future<CommonDatabase> openSqlite3({String name = 'colla_chat.db'}) async {
  if (!platformParams.web) {
    /// 除了web之外的创建打开数据库的方式
    final String dbFolder = platformParams.path;
    String path = p.join(dbFolder, name);
    File file = File(path);

    try {
      CommonDatabase db;
      if (file.existsSync()) {
        print('sqlite3 db $path exist, will be opened');
        db = sqlite3.open(path, mode: OpenMode.readWrite);
        db.userVersion = 1;
      } else {
        print('sqlite3 db $path is not exist,will be created');
        db = sqlite3.open(path, mode: OpenMode.readWriteCreate);
        db.userVersion = 0;
      }
      int userVersion = db.userVersion;
      print('sqlite3 db $path is set userVersion:$userVersion');
      appDataProvider.sqlite3Path = path;
      appDataProvider.dataLength = await file.length();

      return db;
    } catch (e) {
      print('sqlite3 db $path open failure:$e');
    }
  }

  throw UnimplementedError('desktop');
}
