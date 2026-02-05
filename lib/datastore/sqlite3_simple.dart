import 'package:colla_chat/datastore/sql_builder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:sqlite3_simple/sqlite3_simple.dart' as sqlite3_simple;
import 'package:colla_chat/datastore/sqlite3.dart';

/// sqlite3的simple全文检索
class Sqlite3Simple {
  Future<void> init() async {
    sqlite.sqlite3.loadSimpleExtension();
    final docDir = await getApplicationDocumentsDirectory();
    final jiebaDictPath = join(docDir.path, "cpp_jieba");
    final jiebaDictSql = await sqlite.sqlite3
        .saveJiebaDict(jiebaDictPath, overwriteWhenExist: false);
    sqlite3.run(Sql(jiebaDictSql));
    sqlite3.run(Sql("SELECT jieba_query('Jieba分词初始化（提前加载避免后续等待）')"));
  }

  Future<void> initFts5(
      String tableName,
      String fts5TableName,
      String uniqueField,
      List<String> indexFields,
      List<String> unindexFields) async {
    /// FTS5虚表
    String clause = 'CREATE VIRTUAL TABLE $fts5TableName USING fts5(';
    for (var indexField in indexFields) {
      clause = '$clause$indexField,';
    }
    for (var unindexField in unindexFields) {
      clause = '$clause$unindexField UNINDEXED,';
    }

    clause =
        '$clause tokenize = "simple", content = "$tableName", content_rowid = "$uniqueField")';
    sqlite3.run(Sql(clause));

    /// 触发器
    String newInsert = 'INSERT INTO $fts5TableName(rowid, ';
    for (var indexField in indexFields) {
      newInsert = '$newInsert$indexField,';
    }
    for (var unindexField in unindexFields) {
      newInsert = '$newInsert$unindexField,';
    }
    newInsert = ') VALUES (new.$uniqueField';
    for (var indexField in indexFields) {
      newInsert = '$newInsert new.$indexField,';
    }
    for (var unindexField in unindexFields) {
      newInsert = '$newInsert new.$unindexField,';
    }
    String deleteInsert = 'INSERT INTO $fts5TableName($fts5TableName, rowid, ';
    for (var indexField in indexFields) {
      deleteInsert = '$deleteInsert$indexField,';
    }
    for (var unindexField in unindexFields) {
      deleteInsert = '$deleteInsert$unindexField,';
    }
    deleteInsert = '$deleteInsert VALUES ("delete",';
    for (var indexField in indexFields) {
      deleteInsert = '$deleteInsert old.$indexField,';
    }
    for (var unindexField in unindexFields) {
      deleteInsert = '$deleteInsert old.$unindexField,';
    }
    String insertTrigger =
        'CREATE TRIGGER ${tableName}_insert AFTER INSERT ON $tableName BEGIN $newInsert END;';
    sqlite3.run(Sql(insertTrigger));
    String deleteTrigger =
        'CREATE TRIGGER ${tableName}_delete AFTER DELETE ON $tableName BEGIN $deleteInsert END;';
    sqlite3.run(Sql(deleteTrigger));
    String updateTrigger =
        'CREATE TRIGGER ${tableName}_update AFTER UPDATE ON $tableName BEGIN $deleteInsert $newInsert END;';
    sqlite3.run(Sql(updateTrigger));
  }

  /// 通过指定分词器 [tokenizer] 搜索， [tokenizer] 取值：jieba, simple
  sqlite.ResultSet search(
      String fts5TableName,
      String uniqueField,
      List<String> indexFields,
      List<String> unindexFields,
      String value,
      String tokenizer) {
    const wrapperSql = "'${ZeroWidth.start}', '${ZeroWidth.end}'";

    String clause = '''
      SELECT 
        rowid AS $uniqueField, ''';
    for (var indexField in indexFields) {
      clause =
          '$clause simple_highlight($fts5TableName, 0, $wrapperSql) AS $indexField,';
    }
    for (var unindexField in unindexFields) {
      clause = '$clause $unindexField,';
    }
    clause = '''$clause FROM $fts5TableName 
      WHERE $fts5TableName MATCH ${tokenizer}_query(?);
    ''';
    final sqlite.ResultSet resultSet = sqlite3.select(clause, [value]);

    return resultSet;
  }
}

class ZeroWidth {
  ZeroWidth._();

  static const start = "\u200B";
  static const end = "\u200C";
}
