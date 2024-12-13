import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flame/components.dart';
import 'dart:ui' as ui;

/// 模型项目
class Project {
  static const double nodeWidth = 140;

  static const double nodeHeight = 85;

  static Vector2 nodeSize = Vector2(nodeWidth, nodeHeight);

  static const double nodePadding = 10;

  static const double pixelRatio = 1;

  static const baseMetaId = 'base-meta-project-000';

  late final String id;

  String name;

  final String metaId;

  /// 用于是否截取图形节点的图像，对于元模型是需要的，此图形用于按钮图片，对于普通模型是不需要的
  bool meta = false;

  Map<String, Subject> subjects = {};

  Project(
    this.name,
    this.metaId, {
    String? id,
    this.meta = false,
  }) {
    if (id == null) {
      this.id = StringUtil.uuid();
    } else {
      this.id = id;
    }
  }

  void clear() {
    subjects.clear();
  }

  ui.Rect get rect {
    double minX = 0;
    double minY = 0;
    double maxX = 0;
    double maxY = 0;
    for (Subject subject in subjects.values) {
      ui.Rect rect = subject.rect;
      if (rect.left < minX) {
        minX = rect.left;
      }
      if (rect.top < minY) {
        minY = rect.top;
      }
      if (rect.right > maxX) {
        maxX = rect.right;
      }
      if (rect.bottom > maxY) {
        maxY = rect.bottom;
      }
    }

    return ui.Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Project.fromJson(Map json)
      : id = json['id'],
        metaId = json['metaId'] ?? baseMetaId,
        meta = json['meta'] ?? false,
        name = json['name'] {
    subjects = {};
    List<dynamic>? ss = json['subjects'];
    if (ss != null && ss.isNotEmpty) {
      for (var s in ss) {
        Subject subject = Subject.fromJson(s);
        subjects[subject.name] = subject;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'metaId': metaId,
      'meta': meta,
      'subjects': JsonUtil.toJson(subjects.values.toList())
    };
  }
}
