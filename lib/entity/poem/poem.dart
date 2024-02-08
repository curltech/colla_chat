import 'package:colla_chat/entity/base.dart';

/// 诗词
class Poem extends BaseEntity {
  String? collection; // 书名
  String title; // 标题
  String? chapter; // 章节
  String? section; // 部分
  String? notes; // 注释
  String author; // 作者
  String? rhythmic; // 词牌
  String? paragraphs; // 段落
  String? poemType; // 诗词曲
  String? dynasty; // 朝代

  Poem(this.title, this.author);

  Poem.fromJson(super.json)
      : collection = json['collection'],
        title = json['title'],
        chapter = json['chapter'],
        section = json['section'],
        notes = json['notes'],
        author = json['author'],
        rhythmic = json['rhythmic'],
        paragraphs = json['paragraphs'],
        poemType = json['poemType'],
        dynasty = json['dynasty'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'collection': collection,
      'title': title,
      'chapter': chapter,
      'section': section,
      'notes': notes,
      'author': author,
      'rhythmic': rhythmic,
      'paragraphs': paragraphs,
      'poemType': poemType,
      'dynasty': dynasty,
    });
    return json;
  }
}
