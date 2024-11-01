import 'dart:ui' as ui;

import 'package:colla_chat/pages/game/model/component/line_component.dart';
import 'package:colla_chat/pages/game/model/component/node_position_component.dart';
import 'package:flutter/material.dart';

abstract class Node {
  late final String id;
  String name;

  /// 节点的位置和大小
  double? x;
  double? y;
  double? width;
  double? height;
  String? imageContent;

  ui.Image? image;

  NodePositionComponent? nodePositionComponent;

  Node(this.name) {
    id = UniqueKey().toString();
  }

  Node.fromJson(Map json)
      : id = json['id'],
        name = json['name'],
        imageContent = json['imageContent'],
        x = json['x'],
        y = json['y'],
        width = json['width'],
        height = json['height'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageContent': imageContent,
      'x': x,
      'y': y,
      'width': width,
      'height': height
    };
  }
}

//泛化（Generalization）：继承关系，实线带三角形箭头，指向父类。
//实现（Realization）：实现关系，虚线带三角形箭头，指向接口。
//关联（Association）：拥有的关系，实线带普通箭头，指向被拥有者。
//聚合（Aggregation）：整体与部分的关系，实线带空心菱形，指向整体。
//组合（Composition）：整体和部分的关系，但不能离开整体单独存在。实线实心菱形，指向整体。
//依赖（Dependency）：使用的关系，即一个类的实现需要另一个类的协助。虚线普通箭头，指向被使用者
enum RelationshipType {
  generalization,
  realization,
  association,
  aggregation,
  composition,
  dependency
}

class NodeRelationship {
  /// src node的id
  late String srcId;

  /// dst node的id
  late String dstId;

  String? relationshipType;
  int? srcCardinality;
  int? dstCardinality;

  Node? src;
  Node? dst;

  NodeRelationship(this.src, this.dst, this.relationshipType) {
    srcId = src!.id;
    dstId = dst!.id;
  }

  LineComponent? lineComponent;

  NodeRelationship.fromJson(Map json)
      : srcId = json['srcId'],
        dstId = json['dstId'],
        relationshipType = json['relationshipType'],
        srcCardinality = json['srcCardinality'],
        dstCardinality = json['dstCardinality'];

  Map<String, dynamic> toJson() {
    return {
      'srcId': srcId,
      'dstId': dstId,
      'relationshipType': relationshipType,
      'srcCardinality': srcCardinality,
      'dstCardinality': dstCardinality
    };
  }
}
