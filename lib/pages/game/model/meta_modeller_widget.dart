import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/model/base/model_node.dart';
import 'package:colla_chat/pages/game/model/controller/model_project_controller.dart';
import 'package:colla_chat/pages/game/model/controller/model_world_controller.dart';
import 'package:colla_chat/pages/game/model/widget/model_game_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
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

  Widget _buildToolPanelWidget(BuildContext context) {
    return Obx(() {
      var children = [
        CommonAutoSizeText(
            modelProjectController.currentSubjectName.value ?? 'unknown'),
        IconButton(
          onPressed: () async {
            String? subjectName = await DialogUtil.showTextFormField(
                title: 'Add subject',
                content: 'Please input new subject name',
                tip: 'SubjectName');
            if (subjectName != null) {
              modelProjectController.currentSubjectName.value = subjectName;
              modelProjectController.subjectModelWorldController[subjectName] =
                  ModelWorldController();
            }
          },
          icon: Icon(
            Icons.electric_meter,
            color: myself.primary,
          ),
          tooltip: AppLocalizations.t('New subject'),
        ),
        IconButton(
          onPressed: () async {
            List<Option<String>> options = [];
            for (var key
                in modelProjectController.subjectModelWorldController.keys) {
              options.add(Option(key, key));
            }
            String? subjectName = await DialogUtil.showSelectDialog<String>(
                title: const CommonAutoSizeText('Select subject'),
                items: options);
            if (subjectName != null) {
              modelProjectController.currentSubjectName.value = subjectName;
            }
          },
          icon: Icon(
            Icons.list_alt_outlined,
            color: myself.primary,
          ),
          tooltip: AppLocalizations.t('Select subject'),
        ),
        IconButton(
          onPressed: () {
            modelProjectController.addNodeStatus.value =
                !modelProjectController.addNodeStatus.value;
            modelProjectController.addRelationshipStatus.value = false;
          },
          icon: Icon(
            Icons.newspaper_outlined,
            color: modelProjectController.addNodeStatus.value
                ? Colors.amber
                : myself.primary,
          ),
          tooltip: AppLocalizations.t('New node'),
        ),
        IconButton(
          onPressed: () {
            modelProjectController.addRelationshipStatus.value =
                !modelProjectController.addRelationshipStatus.value;
            modelProjectController.addNodeStatus.value = false;
          },
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

  Widget _buildModelGameWidget() {
    ModelWorldController? modelWorldController =
        modelProjectController.getModelWorldController();
    if (modelWorldController == null) {
      modelWorldController = ModelWorldController();
      String? packageName = modelProjectController.currentSubjectName.value;
      modelProjectController.subjectModelWorldController[packageName!] =
          modelWorldController;
    }
    return GestureDetector(
        onTapDown: (TapDownDetails details) {
          if (modelProjectController.addNodeStatus.value) {
            ModelNode metaModelNode = ModelNode(name: 'unknown');
            ModelWorldController? modelWorldController =
                modelProjectController.getModelWorldController();
            if (modelWorldController != null) {
              modelWorldController.nodes[metaModelNode.name] = metaModelNode;
            }

            modelProjectController.addNodeStatus.value = false;
          }
        },
        child: ModelGameWidget<ModelNode>(
          nodePadding: 50,
          nodeSize: 200,
          isDebug: false,
          backgroundColor: Colors.black,
          modelWorldController: modelWorldController,
          onDrawLine: (lineFrom, lineTo) {
            return Paint()
              ..color = Colors.blue
              ..strokeWidth = 1.5;
          },
          builder: (node) {
            return SizedBox(
              width: 100,
              height: 100,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (node).name,
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            );
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      List<Widget> rightWidgets = [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.newspaper_sharp),
          tooltip: AppLocalizations.t('New project'),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.file_open),
          tooltip: AppLocalizations.t('Open project'),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.save),
          tooltip: AppLocalizations.t('Save project'),
        ),
      ];
      var children = [_buildToolPanelWidget(context), _buildModelGameWidget()];

      return AppBarView(
          title: modelProjectController.name.value ?? title,
          withLeading: true,
          rightWidgets: rightWidgets,
          child: appDataProvider.landscape
              ? Row(
                  children: children,
                )
              : Column(
                  children: children,
                ));
    });
  }
}
