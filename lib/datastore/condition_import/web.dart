import 'package:flutter/services.dart' show rootBundle;
import 'package:sqlite3/common.dart';
import 'package:sqlite3/wasm.dart';

Future<CommonDatabase> openSqlite3({String name = 'colla_chat.db'}) async {
//   var platformParams = await PlatformParams.instance;
//   if (platformParams.web) {
  //web下的创建打开数据库的方式
  final fs = await IndexedDbFileSystem.open(dbName: '/');
  var byteData = await rootBundle.load('assets/wasm/sqlite3.wasm');
  var source = byteData.buffer.asUint8List();

  // final response = await http.get(Uri.parse('sqlite3.wasm'));
  // source = response.bodyBytes;

  WasmSqlite3 wasmSqlite3 =
      await WasmSqlite3.load(source, SqliteEnvironment(fileSystem: fs));
  CommonDatabase db = wasmSqlite3.open(name);
  //await fs.flush();

  return db;
}
