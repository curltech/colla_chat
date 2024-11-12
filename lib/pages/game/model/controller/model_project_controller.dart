import 'dart:io';

import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

class ModelProjectController {
  /// 元模型
  final RxMap<String, Project> metaProjects = <String, Project>{}.obs;
  final RxString currentMetaId = RxString(Project.baseMetaId);

  /// 当前模型
  final Rx<Project?> project = Rx<Project?>(null);

  /// 当前模型的文件名
  final Rx<String?> filename = Rx<String?>(null);
  final Rx<String?> currentSubjectName = Rx<String?>(null);
  final Rx<ModelNode?> selectedSrcModelNode = Rx<ModelNode?>(null);
  final Rx<ModelNode?> selectedDstModelNode = Rx<ModelNode?>(null);
  final Rx<NodeRelationship?> selectedRelationship =
      Rx<NodeRelationship?>(null);

  final Rx<ModelNode?> canAddModelNode = Rx<ModelNode?>(null);
  final ModelNode typeModelNode =
      ModelNode(name: 'type', nodeType: NodeType.type.name);
  final ModelNode imageModelNode =
      ModelNode(name: 'image', nodeType: NodeType.image.name);
  final ModelNode shapeModelNode =
      ModelNode(name: 'shape', nodeType: NodeType.shape.name);
  final ModelNode remarkModelNode =
      ModelNode(name: 'remark', nodeType: NodeType.remark.name);

  ModelProjectController() {
    initMetaProject();
  }

  initMetaProject() {
    Project metaProject =
        Project('meta', Project.baseMetaId, id: Project.baseMetaId);
    Subject subject = Subject('meta');
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
        allowRelationshipTypes: {RelationshipType.association.name});
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

  removeModelNode(ModelNode modelNode) {
    if (project.value != null) {
      for (Subject subject in project.value!.subjects.values) {
        if (subject.modelNodes.containsKey(modelNode.id)) {
          subject.modelNodes.remove(modelNode.id);

          return;
        }
      }
    }
  }

  removeRelationship(NodeRelationship relationship) {
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
    if (project.value == null) {
      return null;
    }
    Project? metaProject = metaProjects[project.value!.metaId];
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

  Set<RelationshipType>? getAllAllowRelationshipTypes() {
    Set<RelationshipType>? relationshipTypes;
    if (project.value == null) {
      return null;
    }
    Project? metaProject = metaProjects[project.value!.metaId];
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
        if (allowRelationshipTypes == null) {
          continue;
        }
        for (String allowRelationshipType in allowRelationshipTypes.toList()) {
          RelationshipType? type = StringUtil.enumFromString(
              RelationshipType.values, allowRelationshipType);
          if (type != null) {
            relationshipTypes!.add(type);
          }
        }
      }
    }

    return relationshipTypes;
  }

  /// 注册元模型，覆盖原来加载的
  registerMetaProject(String content) async {
    Map<String, dynamic> json = JsonUtil.toJson(content);
    Project metaProject = Project.fromJson(json);
    String filename = p.join(platformParams.path, metaProject.id);
    File file = File(filename);
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.writeAsStringSync(content);

    metaProjects[metaProject.id] = metaProject;
  }

  /// 根据metaId打开应用目录下已经注册的元模型项目
  Future<Project?> openMetaProject(String metaId) async {
    String filename = p.join(platformParams.path, metaId);
    File file = File(filename);
    if (file.existsSync()) {
      String content = await file.readAsString();
      Map<String, dynamic> json = JsonUtil.toJson(content);
      Project project = Project.fromJson(json);

      return project;
    }

    return null;
  }

  /// 根据json内容打开，检查并加载模型项目
  Future<Project?> openProject(String content) async {
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
      currentMetaId.value = metaId;
      this.project.value = project;
    }

    if (project.subjects.isEmpty) {
      return project;
    }
    currentSubjectName.value = project.subjects.values.first.name;
    for (Subject subject in project.subjects.values) {
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
}

final ModelProjectController modelProjectController = ModelProjectController();
