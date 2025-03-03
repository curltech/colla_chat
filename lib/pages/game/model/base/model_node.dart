import 'dart:ui' as ui;
import 'dart:ui';

import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/component/attribute_text_component.dart';
import 'package:colla_chat/pages/game/model/component/method_text_component.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_field_widget.dart';

enum Scope { private, protected, public }

class Attribute {
  String name;
  late String scope;
  late String dataType;
  bool canBeNull = true;
  bool isPrimaryKey = false;
  int? length;
  int? scale;

  AttributeTextComponent? attributeTextComponent;

  Attribute(this.name, {String? dataType, String? scope}) {
    this.scope = scope ?? Scope.public.name;
    this.dataType = dataType ?? DataType.string.name;
  }

  Attribute.fromJson(Map json)
      : name = json['name'],
        scope = json['scope'],
        dataType = json['dataType'],
        canBeNull = json['canBeNull'] ?? true,
        isPrimaryKey = json['isPrimaryKey'] ?? true,
        length = json['length'],
        scale = json['scale'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({
      'name': name,
      'scope': scope,
      'dataType': dataType,
      'canBeNull': canBeNull,
      'isPrimaryKey': isPrimaryKey,
      'length': length,
      'scale': scale,
    });

    return json;
  }
}

class Method {
  String name;
  late String scope;
  late String returnType;

  MethodTextComponent? methodTextComponent;

  Method(this.name, {String? returnType, String? scope}) {
    this.scope = scope ?? Scope.public.name;
    this.returnType = returnType ?? DataType.string.name;
  }

  Method.fromJson(Map json)
      : name = json['name'],
        scope = json['scope'],
        returnType = json['returnType'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json.addAll({'name': name, 'scope': scope, 'returnType': returnType});

    return json;
  }
}

enum NodeType { shape, image, type, remark }

enum ShapeType {
  rect, //标准矩形
  rrect, //圆角矩形
  circle, //圆形
  oval, //椭圆
  diamond, //菱形
  hexagonal, //六边型
  octagonal, //八边型
  arcrect, //圆弧矩形
  dcircle, //环形
  paragraph, //文本框
  vertices, //路径
}

/// 模型节点
class ModelNode extends Node {
  static const String typeBaseMetaId = 'base-meta-type-000';
  static const String imageBaseMetaId = 'base-meta-image-000';
  static const String shapeBaseMetaId = 'base-meta-shape-000';
  static const String remarkBaseMetaId = 'base-meta-remark-000';

  late String nodeType;
  String? shapeType;
  String? metaId;

  /// 节点自定义的内容，对图像和图形节点来说，meta项目时需要填充，一般项目不需要有值
  String? content;

  int? fillColor; //填充颜色
  int? strokeColor; //边框颜色

  ui.Image? image;
  ModelNode? metaModelNode;

  List<Attribute> attributes = [];
  List<Method> methods = [];

  ModelNode({
    required String name,
    String? nodeType,
    String? id,
    this.metaId,
    this.shapeType,
    this.content,
    this.fillColor,
    this.strokeColor,
  }) : super(name, id: id) {
    this.nodeType = nodeType ?? NodeType.type.name;
  }

  ModelNode.fromJson(Map json) : super.fromJson(json) {
    nodeType = json['nodeType'] ?? NodeType.type.name;
    shapeType = json['shapeType'];
    metaId = json['metaId'];
    content = json['content'];
    dynamic fillColor = json['fillColor'];
    if (fillColor != null) {
      if (fillColor is Color) {
        this.fillColor = fillColor.value;
      }
      if (fillColor is int) {
        this.fillColor = fillColor;
      }
    }
    dynamic strokeColor = json['strokeColor'];
    if (strokeColor != null) {
      if (strokeColor is Color) {
        this.strokeColor = strokeColor.value;
      }
      if (strokeColor is int) {
        this.strokeColor = strokeColor;
      }
    }

    List<dynamic>? ss = json['attributes'];
    if (ss != null && ss.isNotEmpty) {
      for (var s in ss) {
        Attribute attribute = Attribute.fromJson(s);
        attributes.add(attribute);
      }
    }

    ss = json['methods'];
    if (ss != null && ss.isNotEmpty) {
      for (var s in ss) {
        Method method = Method.fromJson(s);
        methods.add(method);
      }
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();

    json.addAll({
      'nodeType': nodeType,
      'shapeType': shapeType,
      'content': content,
      'metaId': metaId,
      'fillColor': fillColor,
      'strokeColor': strokeColor,
      'attributes': JsonUtil.toJson(attributes),
      'methods': JsonUtil.toJson(methods)
    });
    return json;
  }
}
