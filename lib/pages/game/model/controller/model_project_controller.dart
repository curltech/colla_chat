import 'dart:io';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

class ModelProjectController {
  /// 元模型
  final RxMap<String, Project> metaProjects = <String, Project>{}.obs;
  final RxString currentMetaId = RxString(Project.baseMetaId);

  /// 当前模型
  final Rx<Project?> currentProject = Rx<Project?>(null);

  /// 当前展示模型
  final Rx<Project?> project = Rx<Project?>(null);

  /// 当前模型的文件名
  final Rx<String?> filename = Rx<String?>(null);
  final Rx<String?> currentSubjectName = Rx<String?>(null);
  final Rx<ModelNode?> selectedSrcModelNode = Rx<ModelNode?>(null);
  final Rx<ModelNode?> selectedDstModelNode = Rx<ModelNode?>(null);
  final Rx<NodeRelationship?> selectedRelationship =
      Rx<NodeRelationship?>(null);
  final RxBool canAddSubject = false.obs;
  final Rx<ModelNode?> canAddModelNode = Rx<ModelNode?>(null);
  final ModelNode typeModelNode = ModelNode(
      name: 'type',
      nodeType: NodeType.type.name,
      x: -260,
      y: -260,
      id: ModelNode.typeBaseMetaId);
  final ModelNode imageModelNode = ModelNode(
      name: 'image',
      nodeType: NodeType.image.name,
      x: -260,
      y: -60,
      id: ModelNode.imageBaseMetaId);
  final ModelNode shapeModelNode = ModelNode(
      name: 'shape',
      nodeType: NodeType.shape.name,
      x: 60,
      y: -60,
      id: ModelNode.shapeBaseMetaId);
  final ModelNode remarkModelNode = ModelNode(
      name: 'remark',
      nodeType: NodeType.remark.name,
      x: 60,
      y: -260,
      id: ModelNode.remarkBaseMetaId);

  ModelProjectController() {
    initMetaProject();
    registerAssetMetaProject();
  }

  void initMetaProject() {
    Project metaProject =
        Project(Project.baseMetaId, Project.baseMetaId, id: Project.baseMetaId);
    Subject subject =
        Subject(Subject.baseMetaId, id: Subject.baseMetaId, x: -300, y: -300);
    subject.modelNodes = {
      typeModelNode.id: typeModelNode,
      imageModelNode.id: imageModelNode,
      shapeModelNode.id: shapeModelNode,
      remarkModelNode.id: remarkModelNode,
    };
    subject.relationships = {};
    NodeRelationship nodeRelationship = NodeRelationship(
        typeModelNode, typeModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {
          RelationshipType.association.name,
          RelationshipType.generalization.name,
          RelationshipType.realization.name,
          RelationshipType.aggregation.name,
          RelationshipType.composition.name,
          RelationshipType.dependency.name,
        });
    subject.add(nodeRelationship);
    nodeRelationship = NodeRelationship(imageModelNode, imageModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);
    nodeRelationship = NodeRelationship(shapeModelNode, shapeModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);

    nodeRelationship = NodeRelationship(typeModelNode, imageModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);
    nodeRelationship = NodeRelationship(imageModelNode, typeModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);

    nodeRelationship = NodeRelationship(imageModelNode, shapeModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);
    nodeRelationship = NodeRelationship(shapeModelNode, imageModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);

    nodeRelationship = NodeRelationship(typeModelNode, shapeModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);
    nodeRelationship = NodeRelationship(shapeModelNode, typeModelNode,
        relationshipType: RelationshipType.association.name,
        allowRelationshipTypes: {RelationshipType.association.name});
    subject.add(nodeRelationship);

    nodeRelationship = NodeRelationship(imageModelNode, remarkModelNode,
        relationshipType: RelationshipType.reference.name,
        allowRelationshipTypes: {RelationshipType.reference.name});
    subject.add(nodeRelationship);
    nodeRelationship = NodeRelationship(shapeModelNode, remarkModelNode,
        relationshipType: RelationshipType.reference.name,
        allowRelationshipTypes: {RelationshipType.reference.name});
    subject.add(nodeRelationship);
    nodeRelationship = NodeRelationship(typeModelNode, remarkModelNode,
        relationshipType: RelationshipType.reference.name,
        allowRelationshipTypes: {RelationshipType.reference.name});
    subject.add(nodeRelationship);

    metaProject.subjects = {subject.name: subject};

    metaProjects[metaProject.id] = metaProject;
  }

  Subject? getCurrentSubject() {
    if (project.value != null && currentSubjectName.value != null) {
      return project.value!.subjects[currentSubjectName.value];
    }
    return null;
  }

  ModelNode? getModelNode(String id) {
    if (project.value != null) {
      for (Subject subject in project.value!.subjects.values) {
        return subject.modelNodes[id];
      }
    }

    return null;
  }

  ModelNode? getMetaModelNode(String id) {
    Project? metaProject = metaProjects[currentMetaId.value];
    if (metaProject != null) {
      for (Subject subject in metaProject.subjects.values) {
        return subject.modelNodes[id];
      }
    }

    return null;
  }

  void removeModelNode(ModelNode modelNode) {
    if (project.value != null) {
      for (Subject subject in project.value!.subjects.values) {
        if (subject.modelNodes.containsKey(modelNode.id)) {
          subject.modelNodes.remove(modelNode.id);

          return;
        }
      }
    }
  }

  void removeRelationship(NodeRelationship relationship) {
    if (project.value != null) {
      for (Subject subject in project.value!.subjects.values) {
        if (subject.containsKey(relationship)) {
          subject.remove(relationship);

          return;
        }
      }
    }
  }

  List<ModelNode>? getAllMetaModelNodes() {
    List<ModelNode>? modelNodes;
    Project? metaProject;
    if (project.value == null) {
      metaProject = metaProjects[Project.baseMetaId];
    } else {
      metaProject = metaProjects[project.value!.metaId];
    }
    if (metaProject == null) {
      return null;
    }
    List<Subject> subjects = metaProject.subjects.values.toList();
    for (Subject subject in subjects) {
      if (subject.modelNodes.isNotEmpty) {
        modelNodes ??= [];
      }
      modelNodes!.addAll(subject.modelNodes.values);
    }

    return modelNodes;
  }

  Set<RelationshipType>? getAllAllowRelationshipTypes(
      String srcId, String dstId) {
    Set<RelationshipType>? relationshipTypes;
    Project? metaProject;
    if (project.value == null) {
      metaProject = metaProjects[Project.baseMetaId];
    } else {
      metaProject = metaProjects[project.value!.metaId];
    }
    if (metaProject == null) {
      return null;
    }
    List<Subject> subjects = metaProject.subjects.values.toList();
    for (Subject subject in subjects) {
      if (subject.relationships.isNotEmpty) {
        relationshipTypes ??= {};
      }
      for (NodeRelationship nodeRelationship in subject.relationships.values) {
        Set<String>? allowRelationshipTypes =
            nodeRelationship.allowRelationshipTypes;
        if (nodeRelationship.srcId == srcId &&
            nodeRelationship.dstId == dstId) {
          for (String allowRelationshipType
              in allowRelationshipTypes.toList()) {
            RelationshipType? type = StringUtil.enumFromString(
                RelationshipType.values, allowRelationshipType);
            if (type != null) {
              relationshipTypes!.add(type);
            }
          }
        }
      }
    }

    return relationshipTypes;
  }

  void registerAssetMetaProject() {
    _registerAssetMetaProject('product_model');
    _registerAssetMetaProject('class_model');
    _registerAssetMetaProject('process_model');
  }

  Future<void> _registerAssetMetaProject(String filename) async {
    String content = await rootBundle.loadString('assets/model/$filename.json');
    Map<String, dynamic> json = JsonUtil.toJson(content);
    Project metaProject = Project.fromJson(json);
    if (!metaProject.meta) {
      metaProject.meta = true;
    }

    metaProjects[metaProject.id] = metaProject;
  }

  /// 注册元模型，覆盖原来加载的
  Future<void> registerMetaProject(String content) async {
    Map<String, dynamic> json = JsonUtil.toJson(content);
    Project metaProject = Project.fromJson(json);
    String filename = p.join(platformParams.path, '${metaProject.id}.json');
    File file = File(filename);
    if (file.existsSync()) {
      file.deleteSync();
    }
    if (!metaProject.meta) {
      metaProject.meta = true;
      content = JsonUtil.toJsonString(metaProject);
    }
    file.writeAsStringSync(content);

    metaProjects[metaProject.id] = metaProject;
  }

  /// 根据metaId打开应用目录下已经注册的元模型项目
  Future<Project?> openMetaProject(String metaId) async {
    String filename = p.join(platformParams.path, '$metaId.json');
    File file = File(filename);
    if (file.existsSync()) {
      String content = await file.readAsString();
      Map<String, dynamic> json = JsonUtil.toJson(content);
      Project metaProject = Project.fromJson(json);
      metaProject.meta = true;

      return metaProject;
    }

    return null;
  }

  /// 根据json内容打开，检查并加载模型项目
  Future<Project?> openProject(String content) async {
    reset();
    Map<String, dynamic> json = JsonUtil.toJson(content);
    Project project = Project.fromJson(json);
    String metaId = project.metaId;
    if (!metaProjects.containsKey(metaId)) {
      Project? metaProject =
          await modelProjectController.openMetaProject(metaId);

      if (metaProject == null) {
        throw 'meta project is not exist';
      }
      metaProjects[metaId] = metaProject;
    }

    currentMetaId.value = metaId;
    currentProject.value = project;
    this.project.value = project;

    if (project.subjects.isEmpty) {
      return project;
    }
    currentSubjectName.value = project.subjects.values.first.name;
    for (Subject subject in project.subjects.values) {
      for (ModelNode modelNode in subject.modelNodes.values.toList()) {
        String? metaId = modelNode.metaId;
        if (metaId != null) {
          ModelNode? metaModelNode = getMetaModelNode(metaId);
          modelNode.metaModelNode = metaModelNode;
        }
      }
      for (NodeRelationship relationship
          in subject.relationships.values.toList()) {
        ModelNode? modelNode = getModelNode(relationship.srcId);
        if (modelNode == null) {
          subject.remove(relationship);
        } else {
          modelNode = getModelNode(relationship.dstId);
          if (modelNode == null) {
            subject.remove(relationship);
          }
        }
      }
    }
    return project;
  }

  void reset() {
    currentSubjectName.value = null;
    selectedSrcModelNode.value = null;
    selectedDstModelNode.value = null;
    selectedRelationship.value = null;
    canAddModelNode.value = null;
  }
}

final ModelProjectController modelProjectController = ModelProjectController();
