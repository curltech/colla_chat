import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/sql.dart';

class QueryConsoleEditorWidget extends StatelessWidget with TileDataMixin {
  QueryConsoleEditorWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'query_console_editor';

  @override
  IconData get iconData => Icons.mode_edit_outline_rounded;

  @override
  String get title => 'QueryConsoleEditor';

  final controller = CodeController(
    language: sql,
  );

  @override
  Widget build(BuildContext context) {
    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: controller,
        ),
      ),
    );
  }
}
