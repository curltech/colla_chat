import 'dart:io';

import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/datastore/postgres.dart';
import 'package:colla_chat/datastore/sql_builder.dart';
import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart'
    as data_source;
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/tree_view.dart';
import 'package:get/get.dart';

class DataSourceController extends DataListController<DataSourceNode> {
  TreeViewController? treeViewController;
  final Rx<DataTableNode?> currentDataTableNode = Rx<DataTableNode?>(null);
  final Rx<ExplorableNode?> currentNode = Rx<ExplorableNode?>(null);

  DataSourceController();

  @override
  set current(DataSourceNode? element) {
    for (var ele in data) {
      ele.isCurrent.value = false;
    }
    element?.isCurrent.value = true;
    super.current = element;
  }

  Future<void> save() async {
    String value =
        JsonUtil.toJsonString(data.value.map((node) => node.value).toList());
    await localSecurityStorage.save('DataSources', value);
  }

  Future<void> init() async {
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
    bool changed = false;

    for (var ds in dataSources) {
      data_source.DataSource dataSource = data_source.DataSource.fromJson(ds);
      if (dataSource.name == 'colla_chat') {
        include = true;
      }
      if (dataSource.filename != null) {
        File file = File(dataSource.filename!);
        if (file.existsSync()) {
          await addDataSource(dataSource);
        } else {
          changed = true;
        }
      } else {
        changed = true;
      }
    }
    if (changed) {
      await save();
    }

    if (!include) {
      String filename = appDataProvider.sqlite3Path;
      data_source.DataSource dataSource = data_source.DataSource('colla_chat',
          sourceType: data_source.SourceType.sqlite.name);
      dataSource.filename = filename;
      await addDataSource(dataSource, dataStore: sqlite3);
      save();
    }

    treeViewController = TreeViewController(data.value);
  }

  Future<DataSourceNode> addDataSource(data_source.DataSource dataSource,
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

    DataSourceNode dataSourceNode = DataSourceNode(dataSource);
    add(dataSourceNode);
    updateTableNodes(dataSourceNode: dataSourceNode);

    return dataSourceNode;
  }

  void deleteDataSource({DataSourceNode? dataSourceNode}) {
    data_source.DataSource? dataSource;
    if (dataSourceNode != null) {
      dataSource = dataSourceNode.value as data_source.DataSource?;
      if (dataSource!.name == 'colla_chat') {
        return;
      }
      data.remove(dataSourceNode);
    } else {
      dataSource = current?.value as data_source.DataSource?;
      if (dataSource!.name == 'colla_chat') {
        return;
      }
    }
    delete();
    save();
  }

  data_source.DataSource? getDataSource({DataSourceNode? dataSourceNode}) {
    dataSourceNode ??= current;
    if (dataSourceNode == null) {
      return null;
    }
    data_source.DataSource? dataSource =
        dataSourceNode.value as data_source.DataSource?;

    return dataSource;
  }

  /// 当前数据源的所有表
  List<DataTableNode>? getDataTableNodes({DataSourceNode? dataSourceNode}) {
    dataSourceNode ??= current;
    if (dataSourceNode == null) {
      return null;
    }

    return dataSourceNode.getDataTableNodes();
  }

  void setCurrentDataTableNode(
      {DataTableNode? current, DataSourceNode? dataSourceNode}) {
    List<DataTableNode>? dataTableNodes = getDataTableNodes();
    if (dataTableNodes != null && dataTableNodes.isNotEmpty) {
      for (DataTableNode dataTableNode in dataTableNodes) {
        if (current == dataTableNode) {
          dataTableNode.isCurrent.value = true;
        } else {
          dataTableNode.isCurrent.value = false;
        }
      }
    }
    currentDataTableNode.value = current;
  }

  /// 当前表的所有列
  List<DataColumnNode>? getDataColumnNodes(
      {DataSourceNode? dataSourceNode, DataTableNode? dataTableNode}) {
    dataSourceNode ??= current;
    if (dataSourceNode == null) {
      return null;
    }
    dataTableNode ??= getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return null;
    }

    return dataTableNode.getDataColumnNodes();
  }

  /// 当前索引控制器
  List<DataIndexNode>? getDataIndexNodes(
      {DataSourceNode? dataSourceNode, DataTableNode? dataTableNode}) {
    dataSourceNode ??= current;
    if (dataSourceNode == null) {
      return null;
    }
    dataTableNode ??= getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return null;
    }

    return dataTableNode.getDataIndexNodes();
  }

  DataTableNode? addDataTable(
    data_source.DataTable dataTable, {
    DataSourceNode? dataSourceNode,
  }) {
    dataSourceNode ??= current;
    if (dataSourceNode == null) {
      return null;
    }
    return dataSourceNode.addDataTableNode(dataTable);
  }

  /// 在数据库中创建表，要求数据源和列控制器存在
  String? createDataTable(
      {DataSourceNode? dataSourceNode,
      DataTableNode? dataTableNode,
      bool mock = true}) {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
    }
    if (dataTableNode == null) {
      dataTableNode = getDataTableNode(dataSourceNode: dataSourceNode);
      if (dataTableNode == null) {
        return null;
      }
    }
    String sql = 'create table if not exists ${dataTableNode.value.name}\n';
    sql += '(\n';
    List<DataColumnNode>? dataColumnNodes = getDataColumnNodes();
    if (dataColumnNodes != null && dataColumnNodes.isNotEmpty) {
      String keyColumns = '';
      for (int i = 0; i < dataColumnNodes.length; ++i) {
        data_source.DataColumn dataColumn =
            dataColumnNodes[i].value as data_source.DataColumn;
        String columnName = dataColumn.name;
        String dataType = dataColumn.dataType!;
        bool? notNull = dataColumn.notNull;
        if (notNull != null && notNull) {
          sql += '    $columnName   $dataType not null,\n';
        } else {
          sql += '    $columnName   $dataType,\n';
        }
        if (dataColumn.isKey != null && dataColumn.isKey!) {
          if (keyColumns.isEmpty) {
            keyColumns += columnName;
          } else {
            keyColumns += ',$columnName';
          }
        }
      }
      if (keyColumns.isNotEmpty) {
        sql += '    constraint ${dataTableNode.value.name}_pk\n';
        sql += '    primary key($keyColumns)\n';
      }
    }
    sql += ');';
    if (!mock) {
      dataSource.dataStore?.run(Sql(sql));
    }

    return sql;
  }

  void removeDataTableNode({
    DataSourceNode? dataSourceNode,
    DataTableNode? dataTableNode,
  }) {
    dataSourceNode ??= current;
    if (dataSourceNode == null) {
      return;
    }
    dataTableNode ??= currentDataTableNode.value;
    if (dataTableNode == null) {
      return;
    }
    dataSourceNode.deleteDataTableNode(dataTableNode);

    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return;
    }
    String sql = 'drop table if exists ${dataTableNode.value.name}\n';
    dataSource.dataStore?.run(Sql(sql));
  }

  /// 根据数据源和表名获取表
  DataTableNode? getDataTableNode({DataSourceNode? dataSourceNode}) {
    dataSourceNode ??= current;
    if (dataSourceNode == null) {
      return null;
    }

    return currentDataTableNode.value;
  }

  /// 对数据源加表
  Future<Null> updateDataTables(
    List<data_source.DataTable> dataTables, {
    DataSourceNode? dataSourceNode,
  }) async {
    DataSourceNode? dataSourceNode = current;
    if (dataSourceNode == null) {
      return null;
    }
    for (data_source.DataTable dataTable in dataTables) {
      DataTableNode? dataTableNode = dataSourceNode.addDataTableNode(dataTable);
      if (dataTableNode != null) {
        await updateColumnNodes(
            dataSourceNode: dataSourceNode, dataTableNode: dataTableNode);
        await updateIndexNodes(
            dataSourceNode: dataSourceNode, dataTableNode: dataTableNode);
      }
    }
  }

  /// 在数据库中加列，要求数据源，表和列控制器存在
  Null addDataColumn(data_source.DataColumn dataColumn,
      {DataSourceNode? dataSourceNode, DataTableNode? dataTableNode}) {
    DataSourceNode? dataSourceNode = current;
    if (dataSourceNode == null) {
      return null;
    }
    dataTableNode ??= getDataTableNode();
    if (dataTableNode == null) {
      return null;
    }

    dataTableNode.addDataColumns([dataColumn]);
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
    }
    dataSource.dataStore?.run(Sql(
        'alter table ${dataTableNode.value.name} add column ${dataColumn.name};'));
  }

  /// 在数据库中删除列，要求数据源，表和列控制器存在
  bool removeDataColumnNode(DataColumnNode dataColumnNode,
      {DataSourceNode? dataSourceNode, DataTableNode? dataTableNode}) {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return false;
    }
    DataTableNode? dataTableNode =
        getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return false;
    }
    dataSource.dataStore?.run(Sql(
        'alter table ${dataTableNode.value.name} drop column ${dataColumnNode.value.name};'));
    dataTableNode.deleteDataColumnNode(dataColumnNode: dataColumnNode);

    return true;
  }

  DataColumnNode? getDataColumnNode(
      {DataSourceNode? dataSourceNode,
      DataTableNode? dataTableNode,
      String? columnName}) {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
    }
    dataTableNode = getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return null;
    }
    if (columnName == null) {
      if (currentNode.value != null && currentNode.value! is DataColumnNode) {
        columnName = currentNode.value!.value.name;
      }
    }
    if (columnName != null) {
      return dataTableNode.getDataColumnNode(columnName);
    }

    return null;
  }

  Null setCurrentDataColumnNode(
    DataColumnNode current, {
    DataSourceNode? dataSourceNode,
    DataTableNode? dataTableNode,
  }) {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
    }
    dataTableNode ??= getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return null;
    }
    List<DataColumnNode>? dataColumnNode = dataTableNode.getDataColumnNodes();
    if (dataColumnNode != null && dataColumnNode.isNotEmpty) {
      for (DataColumnNode dataColumnNode in dataColumnNode) {
        if (current == dataColumnNode) {
          dataColumnNode.isCurrent.value = true;
        } else {
          dataColumnNode.isCurrent.value = false;
        }
      }
    }
    currentNode.value = current;
  }

  bool? addDataIndex(DataIndex dataIndex,
      {DataSourceNode? dataSourceNode,
      DataTableNode? dataTableNode,
      bool mock = true}) {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return false;
    }
    dataTableNode ??= getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return null;
    }
    dataTableNode.addDataIndexes([dataIndex]);
    return null;
  }

  String? createDataIndex(
      {DataSourceNode? dataSourceNode,
      DataTableNode? dataTableNode,
      DataIndexNode? dataIndexNode,
      bool mock = true}) {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
    }
    dataTableNode ??= getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return null;
    }
    if (dataIndexNode == null) {
      if (currentNode.value != null &&
          currentNode.value!.value is data_source.DataIndex) {
        dataIndexNode = currentNode.value! as DataIndexNode;
      }
    }
    if (dataIndexNode == null) {
      return null;
    }
    String indexName = dataIndexNode.value.name;
    var dataIndex = dataIndexNode.value as data_source.DataIndex;
    String columnNames = dataIndex.columnNames!;
    String sql = '';
    if (dataIndex.isUnique != null && dataIndex.isUnique!) {
      sql += 'create unique index if not exists $indexName\n';
    } else {
      sql += 'create index if not exists $indexName\n';
    }
    sql += 'on ${dataTableNode.value.name}($columnNames);\n';
    if (!mock) {
      dataSource.dataStore?.run(Sql(sql));
    }

    return sql;
  }

  bool removeDataIndexNode(DataIndexNode dataIndexNode,
      {DataSourceNode? dataSourceNode, DataTableNode? dataTableNode}) {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return false;
    }
    dataTableNode ??= getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return false;
    }
    dataSource.dataStore
        ?.run(Sql('drop index if exists ${dataIndexNode.value.name}'));

    return dataTableNode.deleteDataIndexNode(dataIndexNode: dataIndexNode);
  }

  DataIndexNode? getDataIndexNode(
      {DataSourceNode? dataSourceNode,
      DataTableNode? dataTableNode,
      String? indexName}) {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
    }
    dataTableNode ??= getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return null;
    }
    if (indexName == null) {
      if (currentNode.value != null && currentNode.value! is DataIndexNode) {
        indexName = currentNode.value!.value.name;
      }
    }
    if (indexName != null) {
      return dataTableNode.getDataIndexNode(indexName);
    }
    return null;
  }

  Null setCurrentDataIndexNode(
    DataIndexNode? current, {
    DataSourceNode? dataSourceNode,
    DataTableNode? dataTableNode,
  }) {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
    }
    dataTableNode ??= getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return null;
    }
    List<DataIndexNode>? dataIndexNodes = dataTableNode.getDataIndexNodes();
    if (dataIndexNodes != null && dataIndexNodes.isNotEmpty) {
      for (DataIndexNode dataIndexNode in dataIndexNodes) {
        if (current == dataIndexNode) {
          dataIndexNode.isCurrent.value = true;
        } else {
          dataIndexNode.isCurrent.value = false;
        }
      }
    }
    currentNode.value = current;
  }

  /// 获取数据源的所有表
  Future<List<data_source.DataTable>?> findTables({
    DataSourceNode? dataSourceNode,
  }) async {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
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
        data_source.DataTable dataTable = data_source.DataTable(name);
        dataTables.add(dataTable);
      }
    }

    return dataTables;
  }

  /// 把数据源的表加入节点
  Future<Null> updateTableNodes({
    DataSourceNode? dataSourceNode,
  }) async {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
    }
    List<data_source.DataTable>? dataTables =
        await findTables(dataSourceNode: dataSourceNode);
    if (dataTables == null || dataTables.isEmpty) {
      return;
    }

    await updateDataTables(dataTables, dataSourceNode: dataSourceNode);
  }

  /// 获取数据源的表的所有字段
  Future<List<data_source.DataColumn>?> findColumns(
      {DataSourceNode? dataSourceNode, DataTableNode? dataTableNode}) async {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
    }
    dataTableNode ??= getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return null;
    }
    String tableName = dataTableNode.value.name;
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
        data_source.DataColumn dataColumn = data_source.DataColumn(name);
        dataColumn.dataType = dataType;
        dataColumn.notNull = notnull == 0 ? false : true;
        dataColumn.isKey = pk == 0 ? false : true;
        dataColumns.add(dataColumn);
      }
    }

    return dataColumns;
  }

  /// 把数据源的表的所有字段加入节点
  Future<List<DataColumnNode>?> updateColumnNodes({
    DataSourceNode? dataSourceNode,
    DataTableNode? dataTableNode,
  }) async {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
    }
    List<data_source.DataColumn>? dataColumns = await findColumns(
        dataSourceNode: dataSourceNode, dataTableNode: dataTableNode);
    if (dataColumns == null || dataColumns.isEmpty) {
      return null;
    }
    dataTableNode ??= getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return null;
    }
    dataTableNode.deleteDataColumnNode();

    return dataTableNode.addDataColumns(dataColumns);
  }

  /// 获取数据源的表的所有的索引
  Future<List<DataIndex>?> findIndexes(
      {DataSourceNode? dataSourceNode, DataTableNode? dataTableNode}) async {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
    }
    dataTableNode ??= getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return null;
    }
    List<DataIndex> dataIndexes = [];
    if (dataSource.sourceType == data_source.SourceType.sqlite.name) {
      List<Map<dynamic, dynamic>> maps = await dataSource.dataStore!.find(
          'sqlite_master',
          where: 'type=? and tbl_name=?',
          whereArgs: ['index', dataTableNode.value.name],
          orderBy: 'name');
      if (maps.isEmpty) {
        return dataIndexes;
      }
      for (var map in maps) {
        String name = map['name'];
        String sql = map['sql'];
        int start = sql.lastIndexOf('(');
        int end = sql.lastIndexOf(')');
        data_source.DataIndex dataIndex = data_source.DataIndex(name);
        dataIndexes.add(dataIndex);
        if (sql.startsWith('CREATE UNIQUE INDEX')) {
          dataIndex.isUnique = true;
        }
        dataIndex.columnNames = sql.substring(start + 1, end);
      }
    }

    return dataIndexes;
  }

  /// 把数据源的表的索引加入节点
  Future<List<DataIndexNode>?> updateIndexNodes({
    DataSourceNode? dataSourceNode,
    DataTableNode? dataTableNode,
  }) async {
    data_source.DataSource? dataSource =
        getDataSource(dataSourceNode: dataSourceNode);
    if (dataSource == null) {
      return null;
    }
    dataTableNode ??= getDataTableNode(dataSourceNode: dataSourceNode);
    if (dataTableNode == null) {
      return null;
    }
    List<DataIndex>? dataIndexes = await findIndexes(
        dataSourceNode: dataSourceNode, dataTableNode: dataTableNode);
    if (dataIndexes == null || dataIndexes.isEmpty) {
      return null;
    }
    dataTableNode.deleteDataIndexNode();

    return dataTableNode.addDataIndexes(dataIndexes);
  }
}

final DataSourceController dataSourceController = DataSourceController();
