import 'package:animated_tree_view/animated_tree_view.dart' as animated;
import 'package:checkable_treeview/checkable_treeview.dart' as checkable;
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/datastore/postgres.dart';
import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart'
    as data_source;
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DataSourceController extends DataListController<data_source.DataSource> {
  animated.TreeViewController? treeViewController;
  final checkableTreeViewKey = GlobalKey<checkable.TreeViewState<Explorable>>();
  final AnimatedExplorableNode animatedRoot = AnimatedExplorableNode.root();
  final List<CheckableExplorableNode> checkableRoot = [];

  Rx<AnimatedExplorableNode?> currentNode = Rx<AnimatedExplorableNode?>(null);

  final RxMap<String, DataTableController> dataTableControllers =
      <String, DataTableController>{}.obs;

  DataSourceController() {
    init();
  }

  save() async {
    String value = JsonUtil.toJsonString(data.value);
    await localSecurityStorage.save('DataSources', value);
  }

  @override
  clear() {
    animatedRoot.clear();
    checkableRoot.clear();
    super.clear();
  }

  init() async {
    clear();
    String? value = await localSecurityStorage.get('DataSources');
    List<dynamic>? dataSources;
    try {
      if (value != null) {
        dataSources = JsonUtil.toJson(value);
      }
    } catch (e) {
      logger.e('get data sources failure:$e');
    }
    dataSources ??= [];
    bool include = false;

    for (var ds in dataSources) {
      data_source.DataSource dataSource = data_source.DataSource.fromJson(ds);
      if (dataSource.name == 'colla_chat') {
        include = true;
      }
      await addDataSource(dataSource);
    }

    if (!include) {
      String filename = appDataProvider.sqlite3Path;
      data_source.DataSource dataSource = data_source.DataSource(
          name: 'colla_chat', sourceType: data_source.SourceType.sqlite.name);
      dataSource.filename = filename;
      await addDataSource(dataSource, dataStore: sqlite3);
      save();
    }

    for (var child in animatedRoot.childrenAsList) {
      treeViewController?.collapseNode(child as animated.ITreeNode);
    }
  }

  Future<data_source.DataSourceNode> addDataSource(
      data_source.DataSource dataSource,
      {DataStore? dataStore}) async {
    String sourceType = dataSource.sourceType;
    if (sourceType == data_source.SourceType.sqlite.name) {
      if (dataStore == null) {
        dataSource.dataStore = Sqlite3(dataSource.filename!);
        await dataSource.dataStore!.open();
      } else {
        dataSource.filename = (dataStore as Sqlite3).dbPath;
        dataSource.dataStore = dataStore;
      }
    }
    if (sourceType == data_source.SourceType.postgres.name) {
      dataSource.dataStore = Postgres(password: dataSource.password!);
      dataSource.dataStore!.open();
    }
    add(dataSource);
    data_source.DataSourceNode dataSourceNode =
        data_source.DataSourceNode(data: dataSource);
    animatedRoot.add(dataSourceNode);
    checkableRoot.add(CheckableExplorableNode(
        label: Text(dataSource.name!), value: dataSource));
    data_source.FolderNode folderNode =
        data_source.FolderNode(data: data_source.Folder(name: 'tables'));
    dataSourceNode.add(folderNode);
    updateTableNodes(folderNode);

    return dataSourceNode;
  }

  deleteDataSource({data_source.DataSourceNode? node}) {
    data_source.DataSource? dataSource;
    if (node != null) {
      dataSource = node.data;
      if (dataSource!.name == 'colla_chat') {
        return;
      }
      node.delete();
    } else {
      dataSource = current;
      if (dataSource!.name == 'colla_chat') {
        return;
      }
    }
    delete();
    save();
  }

  /// 当前表控制器
  DataTableController? getDataTableController(
      {data_source.DataSource? dataSource}) {
    if (dataSource == null) {
      dataSource = dataSourceController.current;
      if (dataSource == null) {
        return null;
      }
    }
    DataTableController? dataTableController =
        dataSourceController.dataTableControllers[dataSource.name];

    return dataTableController;
  }

  /// 当前列控制器
  DataListController<data_source.DataColumn>? getDataColumnController(
      {data_source.DataSource? dataSource, String? tableName}) {
    if (dataSource == null) {
      dataSource = dataSourceController.current;
      if (dataSource == null) {
        return null;
      }
    }
    DataTableController? dataTableController =
        dataSourceController.dataTableControllers[dataSource.name];
    if (dataTableController == null) {
      return null;
    }
    if (tableName == null) {
      data_source.DataTable? dataTable = dataTableController.current;
      if (dataTable == null) {
        return null;
      }
      tableName = dataTable.name;
    }

    DataListController<data_source.DataColumn>? dataColumnController =
        dataTableController.dataColumnControllers[tableName];

    return dataColumnController;
  }

  /// 当前索引控制器
  DataListController<data_source.DataIndex>? getDataIndexController(
      {data_source.DataSource? dataSource, String? tableName}) {
    if (dataSource == null) {
      dataSource = dataSourceController.current;
      if (dataSource == null) {
        return null;
      }
    }
    DataTableController? dataTableController =
        dataSourceController.dataTableControllers[dataSource.name];
    if (dataTableController == null) {
      return null;
    }
    if (tableName == null) {
      data_source.DataTable? dataTable = dataTableController.current;
      if (dataTable == null) {
        return null;
      }
      tableName = dataTable.name;
    }
    DataListController<data_source.DataIndex>? dataIndexController =
        dataTableController.dataIndexControllers[tableName];

    return dataIndexController;
  }

  /// 根据数据源和表名获取表
  data_source.DataTable? getDataTable(
      {data_source.DataSource? dataSource, String? tableName}) {
    DataTableController? dataTableController =
        getDataTableController(dataSource: dataSource);
    if (dataTableController == null) {
      return null;
    }
    if (tableName == null) {
      data_source.DataTable? dataTable = dataTableController.current;
      if (dataTable == null) {
        return null;
      }
      tableName = dataTable.name;
    }
    for (var dataTable in dataTableController.data) {
      if (tableName == dataTable.name) {
        return dataTable;
      }
    }

    return null;
  }

  setCurrentDataTable(data_source.DataTable? dataTable,
      {data_source.DataSource? dataSource}) {
    DataTableController? dataTableController =
        getDataTableController(dataSource: dataSource);
    if (dataTableController == null) {
      return;
    }
    dataTableController.current = dataTable;
  }

  /// 对数据源加表
  addDataTables(
    List<data_source.DataTable> dataTables, {
    data_source.DataSource? dataSource,
  }) {
    if (dataSource == null) {
      dataSource = dataSourceController.current;
      if (dataSource == null) {
        return null;
      }
    }
    DataTableController? dataTableController;
    if (!dataTableControllers.containsKey(dataSource.name)) {
      dataTableControllers[dataSource.name!] =
          DataTableController(dataSource.name!);
    }
    dataTableController = dataTableControllers[dataSource.name!];
    dataTableController?.replaceAll(dataTables);
  }

  data_source.DataColumn? getDataColumn(
      {data_source.DataSource? dataSource,
      String? tableName,
      String? columnName}) {
    DataListController<data_source.DataColumn>? dataColumnController =
        getDataColumnController(dataSource: dataSource, tableName: tableName);
    if (dataColumnController == null) {
      return null;
    }
    if (columnName == null) {
      data_source.DataColumn? dataColumn = dataColumnController.current;
      if (dataColumn == null) {
        return null;
      }
      columnName = dataColumn.name;
    }
    for (var dataColumn in dataColumnController.data) {
      if (columnName == dataColumn.name) {
        return dataColumn;
      }
    }

    return null;
  }

  setCurrentDataColumn(
    data_source.DataColumn dataColumn, {
    data_source.DataSource? dataSource,
    String? tableName,
  }) {
    DataListController<data_source.DataColumn>? dataColumnController =
        getDataColumnController(dataSource: dataSource, tableName: tableName);
    if (dataColumnController == null) {
      return null;
    }
    dataColumnController.current = dataColumn;
  }

  data_source.DataIndex? getDataIndex(
      {data_source.DataSource? dataSource,
      String? tableName,
      String? indexName}) {
    DataListController<data_source.DataIndex>? dataIndexController =
        getDataIndexController(dataSource: dataSource, tableName: tableName);
    if (dataIndexController == null) {
      return null;
    }
    if (indexName == null) {
      data_source.DataIndex? dataIndex = dataIndexController.current;
      if (dataIndex == null) {
        return null;
      }
      indexName = dataIndex.name;
    }
    for (var dataIndex in dataIndexController.data) {
      if (indexName == dataIndex.name) {
        return dataIndex;
      }
    }

    return null;
  }

  setCurrentDataIndex(
    data_source.DataIndex? dataIndex, {
    data_source.DataSource? dataSource,
    String? tableName,
  }) {
    DataListController<data_source.DataIndex>? dataIndexController =
        getDataIndexController(dataSource: dataSource, tableName: tableName);
    if (dataIndexController == null) {
      return null;
    }
    dataIndexController.current = dataIndex;
  }

  /// 获取数据源的所有表
  Future<List<data_source.DataTable>?> findTables(
      {data_source.DataSource? dataSource}) async {
    if (dataSource == null) {
      dataSource = dataSourceController.current;
      if (dataSource == null) {
        return null;
      }
    }
    List<data_source.DataTable> dataTables = [];
    if (dataSource.sourceType == data_source.SourceType.sqlite.name) {
      List<Map<dynamic, dynamic>> maps = await dataSource.dataStore!.find(
          'sqlite_master',
          where: 'type=?',
          whereArgs: ['table'],
          orderBy: 'name');
      for (var map in maps) {
        String name = map['name'];
        data_source.DataTable dataTable = data_source.DataTable(name: name);
        dataTables.add(dataTable);
      }
    }

    return dataTables;
  }

  /// 把数据源的表加入节点
  updateTableNodes(data_source.FolderNode tableFolderNode,
      {data_source.DataSource? dataSource}) async {
    List<data_source.DataTable>? dataTables =
        await findTables(dataSource: dataSource);
    if (dataTables == null || dataTables.isEmpty) {
      return;
    }

    addDataTables(dataTables, dataSource: dataSource);
    for (var dataTable in dataTables) {
      data_source.DataTableNode dataTableNode =
          data_source.DataTableNode(data: dataTable);
      tableFolderNode.add(dataTableNode);
      data_source.FolderNode columnFolderNode =
          data_source.FolderNode(data: data_source.Folder(name: 'columns'));
      dataTableNode.add(columnFolderNode);

      data_source.FolderNode indexFolderNode =
          data_source.FolderNode(data: data_source.Folder(name: 'indexes'));
      dataTableNode.add(indexFolderNode);
    }
  }

  /// 获取数据源的表的所有字段
  Future<List<data_source.DataColumn>?> findColumns(
      {data_source.DataSource? dataSource, String? tableName}) async {
    if (dataSource == null) {
      dataSource = dataSourceController.current;
      if (dataSource == null) {
        return null;
      }
    }
    if (tableName == null) {
      data_source.DataTable? dataTable = getDataTable(dataSource: dataSource);
      if (dataTable != null) {
        tableName = dataTable.name;
      }
    }
    if (tableName == null) {
      return null;
    }
    List<data_source.DataColumn> dataColumns = [];
    if (dataSource.sourceType == data_source.SourceType.sqlite.name) {
      List<Map<dynamic, dynamic>> maps =
          await dataSource.dataStore!.select('PRAGMA table_info($tableName)');
      if (maps.isEmpty) {
        return dataColumns;
      }
      for (var map in maps) {
        String name = map['name'];
        String dataType = map['type'];
        int notnull = map['notnull'];
        int pk = map['pk'];
        data_source.DataColumn dataColumn = data_source.DataColumn(name: name);
        dataColumn.dataType = dataType;
        dataColumn.notNull = notnull == 0 ? false : true;
        dataColumn.isKey = pk == 0 ? false : true;
        dataColumns.add(dataColumn);
      }
    }

    return dataColumns;
  }

  /// 把数据源的表的所有字段加入节点
  updateColumnNodes(
    data_source.FolderNode columnFolderNode, {
    data_source.DataSource? dataSource,
    String? tableName,
  }) async {
    List<data_source.DataColumn>? dataColumns =
        await findColumns(dataSource: dataSource, tableName: tableName);
    if (dataColumns == null || dataColumns.isEmpty) {
      return;
    }
    if (dataSource == null) {
      dataSource = dataSourceController.current;
      if (dataSource == null) {
        return null;
      }
    }
    DataTableController? dataTableController =
        dataSourceController.dataTableControllers[dataSource.name];
    if (dataTableController == null) {
      return null;
    }
    if (tableName == null) {
      return;
    }
    DataListController<data_source.DataColumn>? dataColumnController =
        dataTableController.dataColumnControllers[tableName];
    if (dataColumnController == null) {
      dataColumnController = DataListController<data_source.DataColumn>();
      dataTableController.dataColumnControllers[tableName] =
          dataColumnController;
    }
    dataColumnController.replaceAll(dataColumns);
    for (var dataColumn in dataColumns) {
      columnFolderNode.add(data_source.DataColumnNode(data: dataColumn));
    }
  }

  /// 获取数据源的表的所有的索引
  Future<List<data_source.DataIndex>?> findIndexes(
      {data_source.DataSource? dataSource, String? tableName}) async {
    if (dataSource == null) {
      dataSource = dataSourceController.current;
      if (dataSource == null) {
        return null;
      }
    }
    if (tableName == null) {
      data_source.DataTable? dataTable = getDataTable(dataSource: dataSource);
      if (dataTable != null) {
        tableName = dataTable.name;
      }
    }
    if (tableName == null) {
      return null;
    }
    List<data_source.DataIndex> dataIndexes = [];
    if (dataSource.sourceType == data_source.SourceType.sqlite.name) {
      List<Map<dynamic, dynamic>> maps = await dataSource.dataStore!.find(
          'sqlite_master',
          where: 'type=? and tbl_name=?',
          whereArgs: ['index', tableName],
          orderBy: 'name');
      if (maps.isEmpty) {
        return dataIndexes;
      }
      for (var map in maps) {
        String name = map['name'];
        String sql = map['sql'];
        int start = sql.lastIndexOf('(');
        int end = sql.lastIndexOf(')');
        data_source.DataIndex dataIndex = data_source.DataIndex(name: name);
        if (sql.startsWith('CREATE UNIQUE INDEX')) {
          dataIndex.isUnique = true;
        }
        dataIndex.columnNames = sql.substring(start + 1, end);
        dataIndexes.add(dataIndex);
      }
    }

    return dataIndexes;
  }

  /// 把数据源的表的索引加入节点
  updateIndexNodes(
    data_source.FolderNode indexesFolderNode, {
    data_source.DataSource? dataSource,
    String? tableName,
  }) async {
    List<data_source.DataIndex>? dataIndexes =
        await findIndexes(dataSource: dataSource, tableName: tableName);
    if (dataIndexes == null || dataIndexes.isEmpty) {
      return;
    }
    if (dataSource == null) {
      dataSource = dataSourceController.current;
      if (dataSource == null) {
        return null;
      }
    }
    DataTableController? dataTableController =
        dataSourceController.dataTableControllers[dataSource.name];
    if (dataTableController == null) {
      return null;
    }
    if (tableName == null) {
      return;
    }
    DataListController<data_source.DataIndex>? dataIndexController =
        getDataIndexController(dataSource: dataSource, tableName: tableName);
    if (dataIndexController == null) {
      dataIndexController = DataListController<data_source.DataIndex>();
      dataTableController.dataIndexControllers[tableName] = dataIndexController;
    }
    dataIndexController.replaceAll(dataIndexes);
    for (var dataIndex in dataIndexes) {
      indexesFolderNode.add(data_source.DataIndexNode(data: dataIndex));
    }
  }
}

final DataSourceController dataSourceController = DataSourceController();

/// 数据表的控制器，代表某数据源的所有表
class DataTableController extends DataListController<data_source.DataTable> {
  final String dataSource;

  DataTableController(this.dataSource);

  /// 数据表的所有字段
  final RxMap<String, DataListController<data_source.DataColumn>>
      dataColumnControllers =
      <String, DataListController<data_source.DataColumn>>{}.obs;

  /// 数据表的所有索引
  final RxMap<String, DataListController<data_source.DataIndex>>
      dataIndexControllers =
      <String, DataListController<data_source.DataIndex>>{}.obs;
}
