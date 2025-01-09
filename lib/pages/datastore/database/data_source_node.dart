import 'package:animated_tree_view/animated_tree_view.dart';
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
  String? port;
  String? user;
  String? password;
  String? database;

  final Sqlite3 sqlite3 = Sqlite3();

  DataSource(super.name, {required this.sourceType});

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

class Schema extends Explorable {
  Schema(super.name);
}

class Database extends Explorable {
  Database(super.name);
}

class Table extends Explorable {
  Table(super.name);
}

class Column extends Explorable {
  Column(super.name);
}

class Index extends Explorable {
  Index(super.name);
}

typedef DataSourceNode = TreeNode<DataSource>;

typedef SchemaNode = TreeNode<Schema>;

typedef DatabaseNode = TreeNode<Database>;

typedef TableNode = TreeNode<Table>;

typedef ColumnNode = TreeNode<Column>;

typedef IndexNode = TreeNode<Index>;
