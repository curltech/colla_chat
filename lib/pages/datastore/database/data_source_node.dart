import 'package:animated_tree_view/animated_tree_view.dart' as animated;
import 'package:checkable_treeview/checkable_treeview.dart' as checkable;
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/tool/image_util.dart';
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

  DataSource({super.name, required this.sourceType, this.dataStore});

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
  DataSchema({super.name});

  DataSchema.fromJson(super.json) : super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();

    return json;
  }
}

class Folder extends Explorable {
  Folder({super.name});
}

typedef FolderNode = animated.TreeNode<Folder>;

class Database extends Explorable {
  Database({super.name});

  Database.fromJson(super.json) : super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();

    return json;
  }
}

class DataTable extends Explorable {
  DataTable({super.name});

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
  bool checked = false;

  DataColumn({super.name});

  DataColumn.fromJson(super.json)
      : dataType = json['dataType'],
        notNull = json['notNull'],
        autoIncrement = json['autoIncrement'],
        isKey = json['isKey'],
        checked = json['checked'] ?? false,
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'dataType': dataType,
      'notNull': notNull,
      'autoIncrement': autoIncrement,
      'isKey': isKey,
      'checked': checked,
    });

    return json;
  }
}

class DataIndex extends Explorable {
  bool? isUnique;
  String? columnNames;

  DataIndex({super.name});

  DataIndex.fromJson(super.json)
      : isUnique = json['isUnique'],
        columnNames = json['columnNames'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'isUnique': isUnique,
      'columnNames': columnNames,
    });

    return json;
  }
}

typedef DataSourceNode = animated.TreeNode<DataSource>;

typedef DataSchemaNode = animated.TreeNode<DataSchema>;

typedef DatabaseNode = animated.TreeNode<Database>;

typedef DataTableNode = animated.TreeNode<DataTable>;

typedef DataColumnNode = animated.TreeNode<DataColumn>;

typedef DataIndexNode = animated.TreeNode<DataIndex>;
