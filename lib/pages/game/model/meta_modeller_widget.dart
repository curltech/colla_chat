import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/game/model/flame/model_canvas_controller.dart';
import 'package:colla_chat/pages/game/model/meta_canvas_widget.dart';
import 'package:colla_chat/pages/game/model/model_project_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      return OverflowBar(
        alignment: MainAxisAlignment.end,
        children: [
          CommonAutoSizeText(
              modelProjectController.currentPackageName.value ?? 'unknown'),
          IconButton(
            onPressed: () async {
              String? packageName = await DialogUtil.showTextFormField(
                  title: 'Add package',
                  content: 'Please input new package name',
                  tip: 'PackageName');
              if (packageName != null) {
                modelProjectController.currentPackageName.value = packageName;
                modelProjectController
                        .packageModelCanvasController[packageName] =
                    ModelCanvasController();
              }
            },
            icon: Icon(
              Icons.electric_meter,
              color: myself.primary,
            ),
            tooltip: AppLocalizations.t('New package'),
          ),
          IconButton(
            onPressed: () async {
              List<Option<String>> options = [];
              for (var key
                  in modelProjectController.packageModelCanvasController.keys) {
                options.add(Option(key, key));
              }
              String? packageName = await DialogUtil.showSelectDialog<String>(
                  title: const CommonAutoSizeText('Select package'),
                  items: options);
              if (packageName != null) {
                modelProjectController.currentPackageName.value = packageName;
              }
            },
            icon: Icon(
              Icons.list_alt_outlined,
              color: myself.primary,
            ),
            tooltip: AppLocalizations.t('Select package'),
          ),
          IconButton(
            onPressed: () {
              modelProjectController.addElementStatus.value =
                  !modelProjectController.addElementStatus.value;
              modelProjectController.addRelationshipStatus.value = false;
            },
            icon: Icon(
              Icons.newspaper_outlined,
              color: modelProjectController.addElementStatus.value
                  ? Colors.amber
                  : myself.primary,
            ),
            tooltip: AppLocalizations.t('New element'),
          ),
          IconButton(
            onPressed: () {
              modelProjectController.addRelationshipStatus.value =
                  !modelProjectController.addRelationshipStatus.value;
              modelProjectController.addElementStatus.value = false;
            },
            icon: Icon(
              Icons.link,
              color: modelProjectController.addRelationshipStatus.value
                  ? Colors.amber
                  : myself.primary,
            ),
            tooltip: AppLocalizations.t('New relationship'),
          ),
        ],
      );
    });
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

      return AppBarView(
          title: modelProjectController.title.value ?? title,
          withLeading: true,
          rightWidgets: rightWidgets,
          child: Column(
            children: [_buildToolPanelWidget(context), MetaCanvasWidget()],
          ));
    });
  }
}
