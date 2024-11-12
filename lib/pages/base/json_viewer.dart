import 'package:colla_chat/pages/base/json_editor.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:get/get.dart';

class JsonEditorWidget extends StatelessWidget with TileDataMixin {
  JsonEditorWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'json_viewer';

  @override
  IconData get iconData => Icons.view_array_outlined;

  @override
  String get title => 'Json viewer';

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      withLeading: withLeading,
      child: Obx(() {
        return JsonView.string(
          jsonContent.value,
        );
      }),
    );
  }
}
