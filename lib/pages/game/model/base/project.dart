import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flame/components.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;

/// 模型项目
class Project {
  static const double nodeWidth = 140;

  static const double nodeHeight = 85;

  static Vector2 nodeSize = Vector2(nodeWidth, nodeHeight);

  static const double nodePadding = 10;

  static const double pixelRatio = 1;

  late final String id;

  String name;

  final String metaId;

  Map<String, Subject> subjects = {};

  Project(this.name, this.metaId, {String? id}) {
    if (id == null) {
      this.id = const Uuid().v4().toString();
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
        metaId = json['metaId'],
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
      'subjects': JsonUtil.toJson(subjects.values.toList())
    };
  }
}
