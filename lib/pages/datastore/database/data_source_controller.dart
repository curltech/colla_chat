import 'package:animated_tree_view/tree_view/tree_node.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/datastore/postgres.dart';
import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/pages/datastore/database/data_index_edit_widget.dart';
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
    DataSource dataSource =
        DataSource(name: 'colla_chat', sourceType: SourceType.sqlite.name);
    dataSource.filename = filename;
    await addDataSource(dataSource, dataStore: sqlite3);
    String? value = await localSecurityStorage.get('DataSources');
    List<dynamic> maps = JsonUtil.toJson(value);
    for (var map in maps) {
      DataSource dataSource = DataSource.fromJson(map);
      await addDataSource(dataSource);
    }
  }

  Future<DataSourceNode> addDataSource(DataSource dataSource,
      {DataStore? dataStore}) async {
    String sourceType = dataSource.sourceType;
    if (sourceType == SourceType.sqlite.name) {
      if (dataStore == null) {
        dataSource.dataStore = Sqlite3(dataSource.filename!);
        await dataSource.dataStore!.open();
      } else {
        dataSource.filename = (dataStore as Sqlite3).dbPath;
        dataSource.dataStore = dataStore;
      }
    }
    if (sourceType == SourceType.postgres.name) {
      dataSource.dataStore = Postgres(password: dataSource.password!);
      dataSource.dataStore!.open();
    }
    dataSources.add(dataSource);
    save();
    current.value = dataSource;
    DataSourceNode dataSourceNode = DataSourceNode(data: dataSource);
    root.add(dataSourceNode);
    FolderNode folderNode = FolderNode(data: Folder(name: 'tables'));
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
        DataTable dataTable = DataTable(name: name);
        DataTableNode dataTableNode = DataTableNode(data: dataTable);
        tableFolderNode.add(dataTableNode);

        FolderNode columnFolderNode = FolderNode(data: Folder(name: 'columns'));
        dataTableNode.add(columnFolderNode);
        updateColumnNodes(name, columnFolderNode);

        FolderNode indexFolderNode = FolderNode(data: Folder(name: 'indexes'));
        dataTableNode.add(indexFolderNode);
        updateIndexNodes(name, indexFolderNode);
      }
    }
  }

  Future<List<DataColumn>?> findColumns(String tableName) async {
    if (current.value != null &&
        current.value!.sourceType == SourceType.sqlite.name) {
      List<Map<dynamic, dynamic>> maps = await current.value!.dataStore!
          .select('PRAGMA table_info($tableName)');
      if (maps.isEmpty) {
        return null;
      }
      List<DataColumn> dataColumns = [];
      for (var map in maps) {
        String name = map['name'];
        String dataType = map['type'];
        int notnull = map['notnull'];
        int pk = map['pk'];
        DataColumn dataColumn = DataColumn(name: name);
        dataColumn.dataType = dataType;
        dataColumn.notNull = notnull == 0 ? false : true;
        dataColumns.add(dataColumn);
      }

      return dataColumns;
    }

    return null;
  }

  updateColumnNodes(String tableName, FolderNode columnFolderNode) async {
    List<DataColumn>? dataColumns = await findColumns(tableName);
    if (dataColumns == null || dataColumns.isEmpty) {
      return;
    }
    for (var dataColumn in dataColumns) {
      columnFolderNode.add(DataColumnNode(data: dataColumn));
    }
  }

  Future<List<DataIndex>?> findIndexes(String tableName) async {
    if (current.value != null &&
        current.value!.sourceType == SourceType.sqlite.name) {
      List<Map<dynamic, dynamic>> maps = await current.value!.dataStore!.find(
          'sqlite_master',
          where: 'type=? and tbl_name=?',
          whereArgs: ['index', tableName],
          orderBy: 'name');
      if (maps.isEmpty) {
        return null;
      }
      List<DataIndex> dataIndexes = [];
      for (var map in maps) {
        String name = map['name'];
        String sql = map['sql'];
        int start=sql.lastIndexOf('(');
        int end=sql.lastIndexOf(')');
        DataIndex dataIndex = DataIndex(name: name);
        dataIndex.columnNames=sql.substring(start,end);
        dataIndexes.add(dataIndex);
      }

      return dataIndexes;
    }

    return null;
  }

  updateIndexNodes(String tableName, FolderNode indexesFolderNode) async {
    List<DataIndex>? dataIndexes = await findIndexes(tableName);
    if (dataIndexes == null || dataIndexes.isEmpty) {
      return;
    }
    for (var dataIndex in dataIndexes) {
      indexesFolderNode.add(DataIndexNode(data: dataIndex));
    }
  }
}

final DataSourceController dataSourceController = DataSourceController();
