import 'package:animated_tree_view/tree_view/tree_node.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/datastore/postgres.dart';
import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:get/get.dart';

class DataSourceController {
  final RxList<DataSource> dataSources = <DataSource>[].obs;
  final TreeNode<Explorable> root = TreeNode.root();
  final Rx<DataSource?> current = Rx<DataSource?>(null);

  Rx<ExplorableNode?> currentNode = Rx<ExplorableNode?>(null);

  DataSourceController() {
    init();
  }

  save() async {
    String value = JsonUtil.toJsonString(dataSources.value.sublist(1));
    await localSecurityStorage.save('DataSources', value);
  }

  init() async {
    String filename = appDataProvider.sqlite3Path;
    await addDataSource('colla_chat',
        sourceType: SourceType.sqlite.name,
        filename: filename,
        dataStore: sqlite3);
    String? value = await localSecurityStorage.get('DataSources');
    List<dynamic> maps = JsonUtil.toJson(value);
    for (var map in maps) {
      DataSource dataSource = DataSource.fromJson(map);
      await addDataSource(dataSource.name!,
          sourceType: SourceType.sqlite.name, filename: dataSource.filename);
    }
  }

  Future<DataSourceNode> addDataSource(String name,
      {required String sourceType,
      String? filename,
      String? host,
      int? port,
      String? user,
      String? password,
      String? database,
      DataStore? dataStore}) async {
    DataSource dataSource =
        DataSource(name, sourceType: sourceType, dataStore: dataStore);
    if (sourceType == SourceType.sqlite.name) {
      if (dataStore == null) {
        dataSource.filename = filename!;
        dataSource.dataStore = Sqlite3(filename);
        await dataSource.dataStore!.open();
      } else {
        dataSource.filename = (dataStore as Sqlite3).dbPath;
        dataSource.dataStore = dataStore;
      }
    }
    if (sourceType == SourceType.postgres.name) {
      dataSource.host = host;
      dataSource.port = port;
      dataSource.user = user;
      dataSource.password = password;
      dataSource.database = database;
      dataSource.dataStore = Postgres(password: password!);
      dataSource.dataStore!.open();
    }
    dataSources.add(dataSource);
    save();
    current.value = dataSource;
    DataSourceNode dataSourceNode = DataSourceNode(data: dataSource);
    root.add(dataSourceNode);
    FolderNode folderNode = FolderNode(data: Folder('tables'));
    dataSourceNode.add(folderNode);
    findTables(folderNode);

    return dataSourceNode;
  }

  deleteDataSource({DataSourceNode? node}) {
    DataSource? dataSource;
    if (node != null) {
      dataSource = node.data;
      if (dataSource == dataSources[0]) {
        return;
      }
      node.delete();
    } else {
      dataSource = current.value;
      if (dataSource == dataSources[0]) {
        return;
      }
      current.value = null;
    }

    if (dataSource != null) {
      dataSources.remove(dataSource);
    }
    save();
  }

  findTables(FolderNode tableFolderNode) async {
    if (current.value != null &&
        current.value!.sourceType == SourceType.sqlite.name) {
      List<Map<dynamic, dynamic>> maps = await current.value!.dataStore!.find(
          'sqlite_master',
          where: 'type=?',
          whereArgs: ['table'],
          orderBy: 'name');
      for (var map in maps) {
        String name = map['name'];
        DataTable dataTable = DataTable(name);
        DataTableNode dataTableNode = DataTableNode(data: dataTable);
        tableFolderNode.add(dataTableNode);

        FolderNode columnFolderNode = FolderNode(data: Folder('columns'));
        dataTableNode.add(columnFolderNode);
        findColumns(name, columnFolderNode);

        FolderNode indexFolderNode = FolderNode(data: Folder('indexes'));
        dataTableNode.add(indexFolderNode);
      }
    }
  }

  findColumns(String tableName, FolderNode columnFolderNode) async {
    if (current.value != null &&
        current.value!.sourceType == SourceType.sqlite.name) {
      List<Map<dynamic, dynamic>> maps = await current.value!.dataStore!
          .select('PRAGMA table_info($tableName)');
      for (var map in maps) {
        String name = map['name'];
        String dataType = map['type'];
        int notnull = map['notnull'];
        int pk = map['pk'];
        DataColumn dataColumn = DataColumn(name);
        dataColumn.dataType = dataType;
        dataColumn.allowedNull = notnull == 0 ? false : true;
        columnFolderNode.add(DataColumnNode(data: dataColumn));
      }
    }
  }
}

final DataSourceController dataSourceController = DataSourceController();
