import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';

/// 模型项目
class Project {
  static const double nodeWidth = 140;

  static const double nodePadding = 10;

  static const double pixelRatio = 1;

  late final String id;

  String name;

  Map<String, Subject> subjects = {};

  Project(this.name) {
    id = UniqueKey().toString();
  }

  void clear() {
    subjects.clear();
  }

  Project.fromJson(Map json)
      : id = json['id'],
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
      'subjects': JsonUtil.toJson(subjects.values.toList())
    };
  }
}
