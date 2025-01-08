import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:colla_chat/pages/datastore/explorable_node.dart';

enum SourceType { sqlite, postgres }

class DataSource extends Explorable {
  final String sourceType;

  DataSource(super.name, {required this.sourceType});
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
