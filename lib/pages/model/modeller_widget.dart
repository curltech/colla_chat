import 'package:colla_chat/pages/model/convas_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

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
    return OverflowBar(
      children: [
        IconButton(
            onPressed: () {}, icon: const Icon(Icons.newspaper_outlined)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.electric_meter))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [_buildToolPanelWidget(context), CanvasWidget()],
    );
  }
}
