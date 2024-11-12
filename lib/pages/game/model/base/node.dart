import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/component/node_frame_component.dart';
import 'package:colla_chat/pages/game/model/component/node_relationship_component.dart';
import 'package:uuid/uuid.dart';

abstract class Node {
  late final String id;
  String name;

  /// 节点的位置和大小
  double? x;
  double? y;
  double? width;
  double? height;

  NodeFrameComponent? nodeFrameComponent;

  Node(this.name, {String? id}) {
    if (id == null) {
      this.id = const Uuid().v4().toString();
    } else {
      this.id = id;
    }
  }

  Node.fromJson(Map json)
      : id = json['id'],
        name = json['name'],
        x = json['x'],
        y = json['y'],
        width = json['width'],
        height = json['height'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'x': x,
      'y': y,
      'width': width,
      'height': height
    };
  }
}

//关联（Association）：拥有的关系，实线带普通箭头，指向被拥有者。
//泛化（Generalization）：继承关系，实线带三角形箭头，指向父节点。
//实现（Realization）：实现关系，虚线带三角形箭头，指向接口。
//聚合（Aggregation）：整体与部分的关系，实线带空心菱形，指向整体。
//组合（Composition）：整体和部分的关系，但不能离开整体单独存在。实线实心菱形，指向整体。
//依赖（Dependency）：使用的关系，即一个节点的实现需要另一个节点的协助。虚线普通箭头，指向被使用者
//引用（Reference）：引用的关系，即一个节点的注释。虚线无箭头
enum RelationshipType {
  association,
  generalization,
  realization,
  aggregation,
  composition,
  dependency,
  reference,
}

class NodeRelationship {
  /// src node的id
  late String srcId;

  /// dst node的id
  late String dstId;

  late String relationshipType;
  Set<String>? allowRelationshipTypes;
  int? srcCardinality;
  int? dstCardinality;

  ModelNode? src;
  ModelNode? dst;

  NodeRelationship(
    this.src,
    this.dst, {
    String? relationshipType,
    this.allowRelationshipTypes,
    this.srcCardinality,
    this.dstCardinality,
  }) {
    srcId = src!.id;
    dstId = dst!.id;
    this.relationshipType =
        relationshipType ?? RelationshipType.association.name;
  }

  NodeRelationshipComponent? nodeRelationshipComponent;

  NodeRelationship.fromJson(Map json)
      : srcId = json['srcId'],
        dstId = json['dstId'],
        relationshipType =
            json['relationshipType'] ?? RelationshipType.association.name,
        srcCardinality = json['srcCardinality'],
        dstCardinality = json['dstCardinality'] {
    dynamic types = json['allowRelationshipTypes'];
    if (types != null && types.isNotEmpty) {
      if (types is Set<dynamic>) {
        types = types.toList();
      }
      allowRelationshipTypes = {};
      if (types is List<dynamic>) {
        for (var type in types) {
          allowRelationshipTypes!.add(type.toString());
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'srcId': srcId,
      'dstId': dstId,
      'relationshipType': relationshipType,
      'allowRelationshipTypes': allowRelationshipTypes?.toList(),
      'srcCardinality': srcCardinality,
      'dstCardinality': dstCardinality
    };
  }
}
