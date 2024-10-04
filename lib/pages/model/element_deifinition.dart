import 'package:flutter/material.dart';

class ElementDefinition {
  final String packageName;
  final String name;
  final bool isAbstract;
  final Map<String, Type> attributes = {};
  final List<String> methods = [];
  final List<String> rules = [];
  Widget? image;

  ElementDefinition(this.name, this.isAbstract, this.packageName);
}

/// 一对一，包含的一对多，组合的一对多，多对多
enum RelationshipType { direct, contain, composite, many }

class RelationshipDefinition {
  final ElementDefinition src;
  final ElementDefinition dst;
  final RelationshipType relationshipType;
  int? srcCount;
  int? dstCount;

  RelationshipDefinition(this.src, this.dst, this.relationshipType);
}
