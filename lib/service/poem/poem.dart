import 'dart:io';

import 'package:colla_chat/entity/poem/poem.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:path/path.dart' as p;

class PoemService extends GeneralBaseService<Poem> {
  PoemService({
    required super.tableName,
    required super.fields,
    required super.indexFields,
    super.encryptFields = const [],
  }) {
    post = (Map map) {
      return Poem.fromJson(map);
    };
  }

  Future<List<Poem>> findByTitle(
    String title,
  ) async {
    String where = 'title=?';
    List<Object> whereArgs = [title];
    var poem = await find(
      where: where,
      whereArgs: whereArgs,
    );

    return poem;
  }

  Future<List<Poem>> findByAuthor(
    String author,
  ) async {
    String where = 'author=?';
    List<Object> whereArgs = [author];
    var poem = await find(
      where: where,
      whereArgs: whereArgs,
    );

    return poem;
  }

  Future<List<Poem>> findByRhythmic(
    String rhythmic,
  ) async {
    String where = 'rhythmic=?';
    List<Object> whereArgs = [rhythmic];
    var poem = await find(
      where: where,
      whereArgs: whereArgs,
    );

    return poem;
  }

  parseJson(String path) async {
    Directory directory = Directory(path);
    if (!directory.existsSync()) {
      return;
    }
    List<FileSystemEntity> entries = directory.listSync();
    for (var entry in entries) {
      FileStat stat = entry.statSync();
      if (stat.type == FileSystemEntityType.directory) {
        Directory dir = Directory(entry.path);
        String collection = p.basename(entry.path);
        List<FileSystemEntity> fileEntries = dir.listSync();
        for (var fileEntry in fileEntries) {
          FileStat fileStat = fileEntry.statSync();
          if (fileStat.type == FileSystemEntityType.file) {
            String filename = fileEntry.path;
            if (filename.endsWith('json')) {
              String? title = p.basenameWithoutExtension(filename);
              File file = File(filename);
              String jsonStr = file.readAsStringSync();
              List<dynamic> list = [];
              dynamic json = JsonUtil.toJson(jsonStr);
              if (json is List) {
                list = json;
              }
              if (json is Map) {
                list = [json];
              }
              for (var map in list) {
                if (map['title'] != null) {
                  title = map['title'];
                }
                String? author = map['author'];
                Poem poem = Poem(title ?? '', author ?? '');
                poem.collection = collection;
                String? chapter = map['chapter'];
                poem.chapter = chapter;
                String? section = map['section'];
                poem.section = section;
                dynamic content = map['content'];
                if (content is String) {
                  poem.paragraphs = content;
                }
                if (content is List) {
                  poem.paragraphs = content.join();
                }
                if (poem.paragraphs == null) {
                  dynamic paragraphs = map['paragraphs'];
                  if (paragraphs is String) {
                    poem.paragraphs = paragraphs;
                  }
                  if (paragraphs is List) {
                    poem.paragraphs = paragraphs.join();
                  }
                }
                String? rhythmic = map['rhythmic'];
                poem.rhythmic = rhythmic;
                dynamic tags = map['tags'];
                if (tags is String) {
                  poem.notes = tags;
                }
                if (tags is List) {
                  poem.notes = tags.join();
                }
                try {
                  await poemService.insert(poem);
                } catch (e) {
                  logger.e('title:$title insert error:$e');
                }
              }
            }
          }
        }
      }
    }
  }
}

final poemService = PoemService(
    tableName: "poem",
    indexFields: ['title', 'author', 'collection', 'dynasty', 'rhythmic'],
    fields: ServiceLocator.buildFields(Poem('', ''), []));
