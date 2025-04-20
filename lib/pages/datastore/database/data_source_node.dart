import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/data_bind/tree_view.dart';
import 'package:flutter/material.dart';

enum SourceType { sqlite, postgres }

enum SqliteDataType { INTEGER, INT, TEXT, REAL, BLOB }

class DataSource extends Explorable {
  static Widget sqliteImage = ImageUtil.buildImageWidget(
      imageContent: 'assets/image/sqlite.webp', width: 24);
  static Widget postgresImage = ImageUtil.buildImageWidget(
      imageContent: 'assets/image/postgres.webp', width: 24);

  String sourceType;
  String? filename;
  String? host;
  int? port;
  String? user;
  String? password;
  String? database;
  DataStore? dataStore;

  DataSource(super.name, {required this.sourceType, this.dataStore});

  DataSource.fromJson(super.json)
      : sourceType = json['sourceType'] ?? SourceType.sqlite.name,
        filename = json['filename'],
        host = json['host'],
        port = json['port'],
        user = json['user'],
        password = json['password'],
        database = json['database'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'sourceType': sourceType,
      'filename': filename,
      'host': host,
      'port': port,
      'user': user,
      'password': password,
      'database': database
    });
    return json;
  }
}

class DataSchema extends Explorable {
  DataSchema(super.name);

  DataSchema.fromJson(super.json) : super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();

    return json;
  }
}

class Folder extends Explorable {
  Folder(super.name);
}

class Database extends Explorable {
  Database(super.name);

  Database.fromJson(super.json) : super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();

    return json;
  }
}

class DataTable extends Explorable {
  DataTable(super.name);

  DataTable.fromJson(super.json) : super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();

    return json;
  }
}

class DataColumn extends Explorable {
  String? dataType;
  bool? notNull;
  bool? autoIncrement;
  bool? isKey;
  bool selected = false;

  DataColumn(super.name);

  DataColumn.fromJson(super.json)
      : dataType = json['dataType'],
        notNull = json['notNull'],
        autoIncrement = json['autoIncrement'],
        isKey = json['isKey'],
        selected = json['selected'] ?? false,
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'dataType': dataType,
      'notNull': notNull,
      'autoIncrement': autoIncrement,
      'isKey': isKey,
      'selected': selected,
    });

    return json;
  }
}

class DataIndex extends Explorable {
  bool? isUnique;
  String? columnNames;
  bool selected = false;

  DataIndex(super.name);

  DataIndex.fromJson(super.json)
      : isUnique = json['isUnique'],
        columnNames = json['columnNames'],
        selected = json['selected'] ?? false,
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'isUnique': isUnique,
      'columnNames': columnNames,
      'selected': selected,
    });

    return json;
  }
}

class DataSourceNode extends ExplorableNode {
  DataSourceNode(DataSource super.dataSource) {
    FolderNode folderNode = FolderNode(Folder('tables'));
    folderNode.parent = this;
    children.add(folderNode);
  }

  @override
  Widget? get icon {
    if ((value as DataSource).sourceType == SourceType.sqlite.name) {
      return DataSource.sqliteImage;
    } else if ((value as DataSource).sourceType == SourceType.postgres.name) {
      return DataSource.postgresImage;
    }
    return DataSource.sqliteImage;
  }

  FolderNode? getTableFolderNode() {
    return children.firstOrNull as FolderNode?;
  }

  List<DataTableNode>? getDataTableNodes() {
    FolderNode? folderNode = getTableFolderNode();
    if (folderNode == null) {
      return null;
    }
    return folderNode.children.map((node) => node as DataTableNode).toList();
  }

  DataTableNode? getDataTableNode(String tableName) {
    List<DataTableNode>? dataTableNodes = getDataTableNodes();
    if (dataTableNodes == null) {
      return null;
    }
    for (var dataTableNode in dataTableNodes) {
      if (dataTableNode.value.name == tableName) {
        return dataTableNode;
      }
    }
    return null;
  }

  DataTableNode? addDataTableNode(DataTable dataTable) {
    FolderNode? folderNode = getTableFolderNode();
    if (folderNode == null) {
      return null;
    }
    DataTableNode dataTableNode = DataTableNode(dataTable);
    dataTableNode.parent = folderNode;
    folderNode.children.add(dataTableNode);

    return dataTableNode;
  }

  bool deleteDataTableNode(DataTableNode dataTableNode) {
    FolderNode? folderNode = getTableFolderNode();
    if (folderNode == null) {
      return false;
    }
    return folderNode.children.remove(dataTableNode);
  }
}

class DataTableNode extends ExplorableNode {
  DataTableNode(DataTable super.dataTable) {
    FolderNode columnFolderNode = FolderNode(Folder('columns'));
    columnFolderNode.parent = this;
    children.add(columnFolderNode);

    FolderNode indexFolderNode = FolderNode(Folder('indexes'));
    indexFolderNode.parent = this;
    children.add(indexFolderNode);
  }

  @override
  Widget? get icon {
    return Icon(Icons.table_view_outlined, color: myself.primary);
  }

  FolderNode? getColumnFolderNode() {
    return children.firstOrNull as FolderNode?;
  }

  FolderNode? getIndexFolderNode() {
    return children.lastOrNull as FolderNode?;
  }

  List<DataColumnNode>? getDataColumnNodes() {
    FolderNode? folderNode = getColumnFolderNode();
    if (folderNode == null) {
      return null;
    }
    return folderNode.children.value
        .map((node) => node as DataColumnNode)
        .toList() as List<DataColumnNode>?;
  }

  List<DataIndexNode>? getDataIndexNodes() {
    FolderNode? folderNode = getIndexFolderNode();
    if (folderNode == null) {
      return null;
    }
    return folderNode.children.value
        .map((node) => node as DataIndexNode)
        .toList() as List<DataIndexNode>?;
  }

  DataColumnNode? getDataColumnNode(String columnName) {
    List<DataColumnNode>? dataColumnNodes = getDataColumnNodes();
    if (dataColumnNodes == null) {
      return null;
    }
    for (var dataColumnNode in dataColumnNodes) {
      if (dataColumnNode.value.name == columnName) {
        return dataColumnNode;
      }
    }
    return null;
  }

  DataIndexNode? getDataIndexNode(String indexName) {
    List<DataIndexNode>? dataIndexNodes = getDataIndexNodes();
    if (dataIndexNodes == null) {
      return null;
    }
    for (var dataIndexNode in dataIndexNodes) {
      if (dataIndexNode.value.name == indexName) {
        return dataIndexNode;
      }
    }
    return null;
  }

  List<DataColumnNode>? addDataColumns(List<DataColumn> dataColumns) {
    FolderNode? folderNode = getColumnFolderNode();
    if (folderNode == null) {
      return null;
    }
    List<DataColumnNode> dataColumnNodes = [];
    for (DataColumn dataColumn in dataColumns) {
      DataColumnNode dataColumnNode = DataColumnNode(dataColumn);
      dataColumnNode.parent = folderNode;
      folderNode.children.add(dataColumnNode);
      dataColumnNodes.add(dataColumnNode);
    }
    return dataColumnNodes;
  }

  deleteDataColumnNode({DataColumnNode? dataColumnNode}) {
    FolderNode? folderNode = getColumnFolderNode();
    if (folderNode == null) {
      return;
    }
    if (dataColumnNode == null) {
      folderNode.children.clear();
    } else {
      folderNode.children
          .removeWhere((item) => item.value.name == dataColumnNode.value.name);
    }
  }

  List<DataIndexNode>? addDataIndexes(List<DataIndex> dataIndexes) {
    FolderNode? folderNode = getIndexFolderNode();
    if (folderNode == null) {
      return null;
    }
    List<DataIndexNode> dataIndexNodes = [];
    for (DataIndex dataIndex in dataIndexes) {
      DataIndexNode dataIndexNode = DataIndexNode(dataIndex);
      dataIndexNode.parent = folderNode;
      folderNode.children.add(dataIndexNode);
      dataIndexNodes.add(dataIndexNode);
    }

    return dataIndexNodes;
  }

  deleteDataIndexNode({DataIndexNode? dataIndexNode}) {
    FolderNode? folderNode = getIndexFolderNode();
    if (folderNode == null) {
      return false;
    }
    if (dataIndexNode == null) {
      folderNode.children.clear();
    } else {
      folderNode.children
          .removeWhere((item) => item.value.name == dataIndexNode.value.name);
    }
  }
}

class DataColumnNode extends ExplorableNode {
  DataColumnNode(DataColumn super.dataColumn);

  @override
  Widget? get icon {
    Icon icon;
    var dataColumn = (value as DataColumn);
    if (dataColumn.isKey != null && dataColumn.isKey!) {
      icon = Icon(Icons.key, color: myself.primary);
    } else {
      icon = Icon(Icons.view_column_outlined, color: myself.primary);
    }

    return icon;
  }
}

class DataIndexNode extends ExplorableNode {
  DataIndexNode(DataIndex super.dataIndex);

  @override
  Widget? get icon {
    return Icon(Icons.content_paste_search, color: myself.primary);
  }
}

class FolderNode extends ExplorableNode {
  FolderNode(Folder super.folder);

  @override
  Widget? get icon {
    return isExpanded.value
        ? Icon(Icons.folder_open, color: myself.primary)
        : Icon(Icons.folder, color: myself.primary);
  }
}
