import 'package:animated_tree_view/tree_view/tree_node.dart';
import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/pages/datastore/database/data_source_node.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:get/get.dart';

class DataSourceController {
  final RxList<DataSource> dataSources = <DataSource>[].obs;
  final TreeNode<Explorable> root = TreeNode.root();

  DataSourceController() {
    init();
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
      String? port,
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
}

final DataSourceController dataSourceController = DataSourceController();
