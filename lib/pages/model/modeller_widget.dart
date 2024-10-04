import 'package:colla_chat/pages/model/convas_widget.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ModellerWidget extends StatelessWidget with TileDataMixin {
  ModellerWidget({super.key});

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
        children: [
          CommonAutoSizeText(
              elementDefinitionControllers.packageName.value ?? 'unknown'),
          IconButton(
              onPressed: () {
                elementDefinitionControllers.addElementStatus.value =
                    !elementDefinitionControllers.addElementStatus.value;
              },
              icon: Icon(
                Icons.newspaper_outlined,
                color: elementDefinitionControllers.addElementStatus.value
                    ? Colors.amber
                    : myself.primary,
              )),
          IconButton(
              onPressed: () async {
                String? packageName = await DialogUtil.showTextFormField(
                    title: 'Add package',
                    content: 'Please input new package name',
                    tip: 'PackageName');
                if (packageName != null) {
                  elementDefinitionControllers.packageName.value = packageName;
                  elementDefinitionControllers
                          .packageDefinitionController[packageName] =
                      ElementDefinitionController();
                }
              },
              icon: Icon(
                Icons.electric_meter,
                color: myself.primary,
              ))
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        title: title,
        withLeading: true,
        child: Column(
          children: [_buildToolPanelWidget(context), CanvasWidget()],
        ));
  }
}
