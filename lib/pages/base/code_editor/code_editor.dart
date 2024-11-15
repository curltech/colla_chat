import 'package:colla_chat/pages/base/code_editor/code_context_menu.dart';
import 'package:colla_chat/pages/base/code_editor/code_find_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

final RxString codeContent = ''.obs;

/// 代码编辑器，可用于json
class CodeEditorWidget extends StatelessWidget with TileDataMixin {
  CodeEditorWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'code_editor';

  @override
  IconData get iconData => Icons.code_outlined;

  @override
  String get title => 'Code editor';

  @override
  Widget build(BuildContext context) {
    return AppBarView(
      title: title,
      withLeading: withLeading,
      child: Obx(() {
        return CodeEditor(
          style: CodeEditorStyle(
            codeTheme: CodeHighlightTheme(
                languages: {'json': CodeHighlightThemeMode(mode: langJson)},
                theme: atomOneLightTheme),
          ),
          indicatorBuilder:
              (context, editingController, chunkController, notifier) {
            return Row(
              children: [
                DefaultCodeLineNumber(
                  controller: editingController,
                  notifier: notifier,
                ),
                DefaultCodeChunkIndicator(
                    width: 20, controller: chunkController, notifier: notifier)
              ],
            );
          },
          chunkAnalyzer: const DefaultCodeChunkAnalyzer(),
          scrollController: CodeScrollController(
            verticalScroller: ScrollController(),
            horizontalScroller: ScrollController(),
          ),
          findBuilder: (context, controller, readOnly) =>
              CodeFindWidget(controller: controller, readOnly: readOnly),
          controller: CodeLineEditingController.fromText(codeContent.value),
          toolbarController: const CodeContextMenuController(),
          sperator: Container(width: 1, color: Colors.blue),
        );
      }),
    );
  }
}
