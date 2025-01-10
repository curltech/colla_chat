import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/datastore/postgres.dart';
import 'package:colla_chat/datastore/sqlite3.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:flutter/material.dart';

enum SourceType { sqlite, postgres }

class DataSource extends Explorable {
  static Widget sqliteImage = ImageUtil.buildImageWidget(
      imageContent: 'assets/images/sqlite.webp', width: 24);
  static Widget postgresImage = ImageUtil.buildImageWidget(
      imageContent: 'assets/images/postgres.webp', width: 24);

  final String sourceType;
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
}

class Database extends Explorable {
  Database(super.name);
}

class DataTable extends Explorable {
  DataTable(super.name);
}

class DataColumn extends Explorable {
  DataColumn(super.name);
}

class DataIndex extends Explorable {
  DataIndex(super.name);
}

typedef DataSourceNode = TreeNode<DataSource>;

typedef DataSchemaNode = TreeNode<DataSchema>;

typedef DatabaseNode = TreeNode<Database>;

typedef DataTableNode = TreeNode<DataTable>;

typedef DataColumnNode = TreeNode<DataColumn>;

typedef DataIndexNode = TreeNode<DataIndex>;
