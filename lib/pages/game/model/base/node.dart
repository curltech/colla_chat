import 'dart:ui' as ui;

import 'package:colla_chat/pages/game/model/component/line_component.dart';
import 'package:colla_chat/pages/game/model/component/node_position_component.dart';

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
  /// src node的package+name
  String? srcName;

  /// dst node的package+name
  String? dstName;

  String? relationshipType;
  int? srcCardinality;
  int? dstCardinality;

  Node? src;
  Node? dst;

  NodeRelationship(this.src, this.dst, this.relationshipType) {
    srcName = '${src?.packageName ?? ''}.${src?.name}';
    dstName = '${dst?.packageName ?? ''}.${dst?.name}';
  }

  LineComponent? lineComponent;

  NodeRelationship.fromJson(Map json)
      : srcName = json['srcName'] == '' ? null : json['srcName'],
        dstName = json['dstName'] == '' ? null : json['dstName'],
        relationshipType = json['relationshipType'],
        srcCardinality = json['srcCardinality'],
        dstCardinality = json['dstCardinality'];

  Map<String, dynamic> toJson() {
    return {
      'srcName': srcName,
      'dstName': dstName,
      'relationshipType': relationshipType,
      'srcCardinality': srcCardinality,
      'dstCardinality': dstCardinality
    };
  }
}

abstract class Node {
  String name;
  String packageName;
  bool isAbstract;

  /// 节点的位置和大小
  double? x;
  double? y;
  double? width;
  double? height;

  ui.Image? image;

  NodePositionComponent? nodePositionComponent;

  Node(this.name, {this.isAbstract = false, this.packageName = ''});

  Node.fromJson(Map json)
      : name = json['name'] == '' ? null : json['name'],
        packageName = json['packageName'] ?? '',
        isAbstract = json['isAbstract'] == true || json['isAbstract'] == 1
            ? true
            : false,
        x = json['x'],
        y = json['y'],
        width = json['width'],
        height = json['height'];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'packageName': packageName,
      'isAbstract': isAbstract,
      'x': x,
      'y': y,
      'width': width,
      'height': height
    };
  }
}
