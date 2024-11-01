import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'dart:ui' as ui;

import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';

/// 模型主题
class Subject {
  late final String id;
  String name;

  /// 节点的位置和大小
  double? x;
  double? y;
  double? width;
  double? height;

  ui.Image? image;

  /// 基于主题域的节点列表
  Map<String, ModelNode> modelNodes = {};

  Map<String, NodeRelationship> relationships = {};

  Subject(this.name) {
    id = UniqueKey().toString();
  }

  add(NodeRelationship nodeRelationship) {
    relationships['${nodeRelationship.srcId}-${nodeRelationship.dstId}'] =
        nodeRelationship;
  }

  remove(NodeRelationship nodeRelationship) {
    relationships.remove('${nodeRelationship.srcId}-${nodeRelationship.dstId}');
  }

  void clear() {
    modelNodes.clear();
    relationships.clear();
  }

  Subject.fromJson(Map json)
      : id = json['id'],
        name = json['name'],
        x = json['x'],
        y = json['y'],
        width = json['width'],
        height = json['height'] {
    modelNodes = {};
    List<dynamic>? ss = json['modelNodes'];
    if (ss != null && ss.isNotEmpty) {
      for (var s in ss) {
        ModelNode modelNode = ModelNode.fromJson(s);
        modelNodes['${modelNode.packageName}.${modelNode.name}'] = modelNode;
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
      'width': width,
      'height': height,
      'modelNodes': JsonUtil.toJson(modelNodes.values.toList()),
      'relationships': JsonUtil.toJson(relationships.values.toList())
    };
  }
}
