import 'package:animated_tree_view/tree_view/tree_node.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/datastore/postgres.dart';
import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:get/get.dart';

class DataSourceController {
  final RxList<DataSource> dataSources = <DataSource>[].obs;
  final TreeNode<Explorable> root = TreeNode.root();
  int _current = -1;
  Rx<ExplorableNode?> currentNode = Rx<ExplorableNode?>(null);

  DataSourceController() {
    init();
  }

  DataSource? get current {
    if (_current > -1 && _current < dataSources.length) {
      return dataSources[_current];
    }
    return null;
  }

  set current(DataSource? dataSource) {
    if (dataSource == null) {
      _current = -1;
    } else {
      _current = dataSources.indexOf(dataSource);
    }
  }

  init() async {
    String filename = appDataProvider.sqlite3Path;
    await addDataSource('colla_chat',
        sourceType: SourceType.sqlite.name,
        filename: filename,
        dataStore: sqlite3);
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
    current = dataSource;
    DataSourceNode dataSourceNode = DataSourceNode(data: dataSource);
    root.add(dataSourceNode);
    FolderNode folderNode = FolderNode(data: Folder('tables'));
    dataSourceNode.add(folderNode);
    findTables(folderNode);

    return dataSourceNode;
  }

  deleteDataSource(DataSourceNode node) {
    DataSource? dataSource = node.data;
    if (dataSource != null) {
      dataSources.remove(dataSource);
    }
    node.delete();
  }

  findTables(FolderNode folderNode) async {
    if (current != null && current!.sourceType == SourceType.sqlite.name) {
      List<Map<dynamic, dynamic>> maps = await current!.dataStore!.find(
          'sqlite_master',
          where: 'type=?',
          whereArgs: ['table'],
          orderBy: 'name');
      for (var map in maps) {
        String name = map['name'];
        DataTable dataTable = DataTable(name);
        DataTableNode dataTableNode = DataTableNode(data: dataTable);
        folderNode.add(dataTableNode);
      }
    }
  }

  findColumns(String name, FolderNode folderNode) async {
    if (current != null && current!.sourceType == SourceType.sqlite.name) {
      List<Map<dynamic, dynamic>> maps =
          await current!.dataStore!.select('PRAGMA table_info($name)');
    }
  }
}

final DataSourceController dataSourceController = DataSourceController();
