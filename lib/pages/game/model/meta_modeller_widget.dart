import 'dart:convert';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/base/node.dart';
import 'package:colla_chat/pages/game/model/base/project.dart';
import 'package:colla_chat/pages/game/model/base/subject.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/widget/model_game_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 元模型建模器
class MetaModellerWidget extends StatelessWidget with TileDataMixin {
  MetaModellerWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'modeller';

  @override
  IconData get iconData => Icons.model_training_outlined;

  @override
  String get title => 'Modeller';

  _addSubject() async {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return;
    }
    modelProjectController.addSubjectStatus.value =
        !modelProjectController.addSubjectStatus.value;
    modelProjectController.addNodeStatus.value = false;
    modelProjectController.addRelationshipStatus.value = false;
    // String? subjectName = await DialogUtil.showTextFormField(
    //     title: 'Add subject',
    //     content: 'Please input new subject name',
    //     tip: 'SubjectName');
    // if (subjectName != null) {
    //   modelProjectController.currentSubjectName.value = subjectName;
    //   modelProjectController.project.value?.subjects.add(Subject(subjectName));
    // }
  }

  _selectSubject() async {
    Project? project = modelProjectController.project.value;
    if (project == null) {
      return;
    }
    List<Option<String>> options = [];
    for (var subject in modelProjectController.project.value!.subjects.values) {
      options.add(Option(subject.name, subject.name));
    }
    String? subjectName = await DialogUtil.showSelectDialog<String>(
        title: const CommonAutoSizeText('Select subject'), items: options);
    if (subjectName != null) {
      modelProjectController.currentSubjectName.value = subjectName;
    }
  }

  Widget _buildToolPanelWidget(BuildContext context) {
    return Obx(() {
      Project? project = modelProjectController.project.value;
      var children = [
        // CommonAutoSizeText(
        //     modelProjectController.currentSubjectName.value ?? 'unknown'),
        IconButton(
          onPressed: project != null
              ? () async {
                  await _addSubject();
                }
              : null,
          icon: Icon(
            Icons.electric_meter,
            color: modelProjectController.addSubjectStatus.value
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New subject'),
        ),
        IconButton(
          onPressed: project != null
              ? () async {
                  _selectSubject();
                }
              : null,
          icon: Icon(
            Icons.list_alt_outlined,
            color: myself.primary,
          ),
          tooltip: AppLocalizations.t('Select subject'),
        ),
        IconButton(
          onPressed: project != null
              ? () {
                  modelProjectController.addNodeStatus.value =
                      !modelProjectController.addNodeStatus.value;
                  modelProjectController.addRelationshipStatus.value = false;
                }
              : null,
          icon: Icon(
            Icons.newspaper_outlined,
            color: modelProjectController.addNodeStatus.value
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New node'),
        ),
        IconButton(
          onPressed: project != null
              ? () {
                  modelProjectController.addRelationshipStatus.value =
                      !modelProjectController.addRelationshipStatus.value;
                  modelProjectController.addNodeStatus.value = false;
                }
              : null,
          icon: Icon(
            Icons.link,
            color: modelProjectController.addRelationshipStatus.value
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New relationship'),
        ),
      ];
      return appDataProvider.landscape
          ? Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: children,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: children,
            );
    });
  }

  _newProject() async {
    String? projectName = await DialogUtil.showTextFormField(
        title: 'New project',
        content: 'Please input new project name',
        tip: 'unknown');
    if (projectName != null) {
      modelProjectController.project.value = Project(projectName);
    }
  }

  _openProject() async {
    XFile? xfile = await FileUtil.selectFile(allowedExtensions: ['json']);
    if (xfile != null) {
      String content = await xfile.readAsString();
      Map<String, dynamic> json = JsonUtil.toJson(content);
      Project project = Project.fromJson(json);
      modelProjectController.project.value = project;
      if (project.subjects.isNotEmpty) {
        modelProjectController.currentSubjectName.value =
            project.subjects.values.first.name;
        for (Subject subject in project.subjects.values) {
          for (NodeRelationship relationship
              in subject.relationships.values.toList()) {
            String key = '${relationship.srcName}-${relationship.dstName}';
            ModelNode? modelNode =
                modelProjectController.getModelNode(relationship.srcName!);
            if (modelNode == null) {
              subject.relationships.remove(key);
            } else {
              modelNode =
                  modelProjectController.getModelNode(relationship.dstName!);
              if (modelNode == null) {
                subject.relationships.remove(key);
              }
            }
          }
        }
      }
    }
  }

  _saveProject() async {
    String content =
        JsonUtil.toJsonString(modelProjectController.project.value);
    String? filename = await FileUtil.saveAsFile(
        modelProjectController.project.value!.name,
        utf8.encode(content),
        'json');
    modelProjectController.filename.value = filename;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Project? project = modelProjectController.project.value;
      List<Widget> rightWidgets = [
        IconButton(
          onPressed: () {
            _newProject();
          },
          icon: const Icon(Icons.newspaper_sharp),
          tooltip: AppLocalizations.t('New project'),
        ),
        IconButton(
          onPressed: () {
            _openProject();
          },
          icon: const Icon(Icons.file_open),
          tooltip: AppLocalizations.t('Open project'),
        ),
        IconButton(
          onPressed: project != null
              ? () async {
                  await _saveProject();
                }
              : null,
          icon: const Icon(Icons.save),
          tooltip: AppLocalizations.t('Save project'),
        ),
      ];
      var children = [
        _buildToolPanelWidget(context),
        Expanded(
            child: ModelGameWidget<ModelNode>(
          key: UniqueKey(),
        ))
      ];
      String title = this.title;
      if (project != null) {
        title = '${AppLocalizations.t(title)}-${project.name}';
      }
      Subject? subject = modelProjectController.getCurrentSubject();
      if (subject != null) {
        title = '$title-${subject.name}';
      }
      return AppBarView(
          title: title,
          withLeading: true,
          rightWidgets: rightWidgets,
          child: appDataProvider.landscape
              ? Column(
                  children: children,
                )
              : Row(
                  children: children,
                ));
    });
  }
}
