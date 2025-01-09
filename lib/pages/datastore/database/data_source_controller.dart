import 'package:animated_tree_view/tree_view/tree_node.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
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

  init() {
    String filename =
        '/Users/jingsonghu/Library/Containers/io.curltech.colla/Data/Documents/colla_chat/colla_chat.db';
    addDataSource('colla_chat',
        sourceType: SourceType.sqlite.name, filename: filename);
  }

  DataSourceNode addDataSource(String name,
      {required String sourceType,
      String? filename,
      String? host,
      int? port,
      String? user,
      String? password,
      String? database}) {
    DataSource dataSource = DataSource(name, sourceType: sourceType);
    if (sourceType == SourceType.sqlite.name) {
      dataSource.filename = filename;
      dataSource.sqlite3.open(name: name);
    }
    if (sourceType == SourceType.postgres.name) {
      dataSource.host = host;
      dataSource.port = port;
      dataSource.user = user;
      dataSource.password = password;
      dataSource.database = database;
      dataSource.postgres.open(
          host: host!,
          port: port!,
          user: user!,
          password: password!,
          database: database!);
    }
    dataSources.add(dataSource);
    DataSourceNode dataSourceNode = DataSourceNode(data: dataSource);
    root.add(dataSourceNode);
    FolderNode folderNode = FolderNode(data: Folder('tables'));
    dataSourceNode.add(folderNode);

    return dataSourceNode;
  }

  deleteDataSource(DataSourceNode node) {
    DataSource? dataSource = node.data;
    if (dataSource != null) {
      dataSources.remove(dataSource);
    }
    node.delete();
  }

  findTables(FolderNode folderNode) {
    if (current != null && current!.sourceType == SourceType.sqlite.name) {
      List<Map<dynamic, dynamic>> maps = current!.sqlite3.find('sqlite_master',
          where: 'type=?', whereArgs: ['table'], orderBy: 'name');
    }
  }

  findColumns(String name, FolderNode folderNode) {
    if (current != null && current!.sourceType == SourceType.sqlite.name) {
      List<Map<dynamic, dynamic>> maps =
          current!.sqlite3.select('PRAGMA table_info($name)');
    }
  }
}

final DataSourceController dataSourceController = DataSourceController();
