import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
part 'base.g.dart';

abstract class BaseEntity extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get createDate => text().withLength(min: 6, max: 32)();

  TextColumn get updateDate =>
      text().named('updateDate').withLength(min: 6, max: 32)();
}

abstract class StatusEntity extends BaseEntity {
  TextColumn get status => text().withLength(min: 6, max: 32)();

  TextColumn get statusReason => text().withLength(min: 6, max: 32)();

  TextColumn get statusDate => text().withLength(min: 6, max: 32)();
}

@DataClassName('StockAccount')
class StockAccountDef extends StatusEntity {
  String get tableName => 'StockAccount';

  TextColumn get accountId => text().withLength(min: 6, max: 32)();

  TextColumn get accountName => text().withLength(min: 6, max: 32)();

  TextColumn get name => text().withLength(min: 6, max: 32)();

  TextColumn get subscription => text().withLength(min: 6, max: 32)();

  TextColumn get lastLoginDate => text().withLength(min: 6, max: 32)();

  TextColumn get lastReadDate => text().withLength(min: 6, max: 32)();

  TextColumn get roles => text().withLength(min: 6, max: 32)();
}

@DriftDatabase(tables: [StockAccountDef])
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
