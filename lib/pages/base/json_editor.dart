import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

import 'package:json_editor_flutter/json_editor_flutter.dart';

final ValueNotifier<String> jsonContent = ValueNotifier<String>('');

class JsonEditorWidget extends StatelessWidget with DataTileMixin {
  JsonEditorWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'json_editor';

  @override
  IconData get iconData => Icons.edit_calendar_outlined;

  @override
  String get title => 'Json editor';

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      helpPath: routeName,
      withLeading: withLeading,
      child: ValueListenableBuilder(
          valueListenable: jsonContent,
          builder: (context, value, _) {
            return JsonEditor(
              onChanged: (value) {
                jsonContent.value = value.toString();
              },
              json: jsonContent.value,
            );
          }),
    );
  }
}
