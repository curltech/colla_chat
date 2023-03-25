import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/tool/permission_util.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

Future<CommonDatabase> openSqlite3({String name = 'colla_chat.db'}) async {
  if (!platformParams.web) {
    PermissionStatus status =
        await PermissionUtil.requestPermission(Permission.storage);
    if (status != PermissionStatus.granted) {
      throw UnimplementedError('No storage permission');
    }

    /// 除了web之外的创建打开数据库的方式
    final dbFolder = await PathUtil.getApplicationDirectory();
    String path = name;
    if (dbFolder != null) {
      path = p.join(dbFolder.path, name);
      CommonDatabase db = sqlite3.open(path);
      appDataProvider.sqlite3Path = path;

      return db;
    }
  }

  throw UnimplementedError('desktop');
}
