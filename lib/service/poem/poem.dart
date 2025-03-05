import 'dart:io';

import 'package:colla_chat/entity/dht/peerendpoint.dart';
import 'package:colla_chat/entity/poem/poem.dart';
import 'package:colla_chat/pages/chat/me/settings/advanced/peerendpoint/peer_endpoint_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/service/general_base.dart';
import 'package:colla_chat/service/servicelocator.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/transport/httpclient.dart';
import 'package:dio/dio.dart';

class PoemService extends GeneralBaseService<Poem> {
  PoemService({
    required super.tableName,
    required super.fields,
    super.uniqueFields,
    super.indexFields = const [
      'title',
      'author',
      'collection',
      'dynasty',
      'rhythmic'
    ],
    super.encryptFields,
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

  parseJson(String collection, String filename) async {
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
      String? title;
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

  dynamic send(String url, {dynamic data}) async {
    PeerEndpoint? defaultPeerEndpoint =
        peerEndpointController.defaultPeerEndpoint;
    if (defaultPeerEndpoint != null) {
      String? httpConnectAddress = defaultPeerEndpoint.httpConnectAddress;
      if (httpConnectAddress != null) {
        DioHttpClient? client = httpClientPool.get(httpConnectAddress);
        Response<dynamic> response = await client.send(url, data);
        if (response.statusCode == 200) {
          return response.data;
        }
      }
    }
  }

  /// 根据关键字搜索诗词
  Future<List<Poem>> sendSearchPoem(
      {String? title,
      String? author,
      String? rhythmic,
      String? dynasty,
      String? paragraphs,
      int from = 0,
      int limit = 10}) async {
    List<dynamic> data = await send('/poem/Search', data: {
      'title': title ?? '',
      'author': author ?? '',
      'rhythmic': rhythmic ?? '',
      'dynasty': dynasty ?? '',
      'paragraphs': paragraphs ?? '',
      'from': from,
      'limit': limit
    });
    List<Poem> poems = [];
    for (dynamic map in data) {
      Poem poem = Poem.fromJson(map);
      poems.add(poem);
      // poemService.store(poem);
    }

    return poems;
  }
}

final poemService = PoemService(
    tableName: "pm_poem", fields: ServiceLocator.buildFields(Poem('', ''), []));
