import 'package:flutter/services.dart' show rootBundle;
import 'package:sqlite3/wasm.dart';

Future<CommonDatabase> openSqlite3({required String path}) async {
  //web下的创建打开数据库的方式
  final fs = await IndexedDbFileSystem.open(dbName: '/');
  var byteData = await rootBundle.load('assets/wasm/sqlite3.wasm');
  var source = byteData.buffer.asUint8List();

  try {
    WasmSqlite3 wasmSqlite3 = await WasmSqlite3.load(source);
    CommonDatabase db = wasmSqlite3.open(path);
    int userVersion = db.userVersion;
    print('wasm sqlite3 db userVersion is $userVersion');

    return db;
  } catch (e) {
    print('wasm sqlite3 db open failure:$e');
  }

  throw UnimplementedError('web');
}
