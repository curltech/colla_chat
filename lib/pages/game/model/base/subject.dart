import 'dart:ui' as ui;

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/component/subject_component.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';

/// 模型主题，每个主题将占据一块区域，主题之间相邻，大小为10个节点x6个节点
class Subject {
  static const String baseMetaId = 'base-meta-subject-000';
  late final String id;
  String name;

  /// 当modelNodes为空时的初始位置
  double? x;
  double? y;

  /// 基于主题域的节点列表
  Map<String, ModelNode> modelNodes = {};

  Map<String, NodeRelationship> relationships = {};

  SubjectComponent? subjectComponent;

  Subject(this.name, {String? id, this.x, this.y}) {
    if (id == null) {
      this.id = StringUtil.uuid();
    } else {
      this.id = id;
    }
  }

  ui.Rect get rect {
    if (modelNodes.isEmpty) {
      if (x != null && y != null) {
        return ui.Rect.fromLTWH(
            x!,
            y!,
            Project.nodeWidth * 2 + Project.nodePadding,
            Project.nodeHeight * 2 + Project.nodePadding);
      } else {
        return const ui.Rect.fromLTWH(
            0,
            0,
            Project.nodeWidth * 2 + Project.nodePadding,
            Project.nodeHeight * 2 + Project.nodePadding);
      }
    }
    ModelNode node = modelNodes.values.toList().first;
    double minX = node.x!;
    double minY = node.y!;
    double maxX = node.x!;
    double maxY = node.y!;
    for (ModelNode modelNode in modelNodes.values) {
      double? x = modelNode.x;
      double width = modelNode.width;
      if (x != null) {
        if (x < minX) {
          minX = x;
        }
        x += width;
        if (x > maxX) {
          maxX = x;
        }
      }
      double? y = modelNode.y;
      double height = modelNode.height;
      if (y != null) {
        if (y < minY) {
          minY = y;
        }
        y += height;
        if (y > maxY) {
          maxY = y;
        }
      }
    }

    ui.Rect rect = ui.Rect.fromLTRB(
        minX - 3 * Project.nodePadding,
        minY - Project.nodePadding * 4,
        maxX + 8 * Project.nodePadding,
        maxY + 3 * Project.nodePadding);

    x = rect.left;
    y = rect.top;

    return rect;
  }

  add(NodeRelationship nodeRelationship) {
    relationships['${nodeRelationship.srcId}-${nodeRelationship.dstId}'] =
        nodeRelationship;
  }

  NodeRelationship? remove(NodeRelationship nodeRelationship) {
    return relationships
        .remove('${nodeRelationship.srcId}-${nodeRelationship.dstId}');
  }

  bool containsKey(NodeRelationship nodeRelationship) {
    return relationships
        .containsKey('${nodeRelationship.srcId}-${nodeRelationship.dstId}');
  }

  void clear() {
    modelNodes.clear();
    relationships.clear();
  }

  Subject.fromJson(Map json)
      : id = json['id'],
        name = json['name'],
        x = json['x'],
        y = json['y'] {
    modelNodes = {};
    List<dynamic>? ss = json['modelNodes'];
    if (ss != null && ss.isNotEmpty) {
      for (var s in ss) {
        ModelNode modelNode = ModelNode.fromJson(s);
        modelNodes[modelNode.id] = modelNode;
      }
    }
    relationships = {};
    ss = json['relationships'];
    if (ss != null && ss.isNotEmpty) {
      for (var s in ss) {
        NodeRelationship nodeRelationship = NodeRelationship.fromJson(s);
        relationships['${nodeRelationship.srcId}-${nodeRelationship.dstId}'] =
            nodeRelationship;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'x': x,
      'y': y,
      'modelNodes': JsonUtil.toJson(modelNodes.values.toList()),
      'relationships': JsonUtil.toJson(relationships.values.toList())
    };
  }
}
