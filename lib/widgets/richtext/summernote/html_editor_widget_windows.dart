import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html_editor_enhanced/html_editor.dart'
    hide NavigationActionPolicy, UserScript, ContextMenu;
import 'package:html_editor_enhanced/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The HTML Editor widget itself, for mobile (uses InAppWebView)
class HtmlEditorWidget extends StatefulWidget {
  HtmlEditorWidget({
    Key? key,
    required this.controller,
    this.callbacks,
    required this.plugins,
    required this.htmlEditorOptions,
    required this.htmlToolbarOptions,
    required this.otherOptions,
  }) : super(key: key);

  final HtmlEditorController controller;
  final Callbacks? callbacks;
  final List<Plugins> plugins;
  final HtmlEditorOptions htmlEditorOptions;
  final HtmlToolbarOptions htmlToolbarOptions;
  final OtherOptions otherOptions;

  @override
  _HtmlEditorWidgetMobileState createState() => _HtmlEditorWidgetMobileState();
}

/// State for the mobile Html editor widget
///
/// A stateful widget is necessary here to allow the height to dynamically adjust.
class _HtmlEditorWidgetMobileState extends State<HtmlEditorWidget> {
  /// Tracks whether the callbacks were initialized or not to prevent re-initializing them
  bool callbacksInitialized = false;

  /// The height of the document loaded in the editor
  late double docHeight;

  /// The file path to the html code
  late String filePath;

  /// String to use when creating the key for the widget
  late String key;

  /// Stream to transfer the [VisibilityInfo.visibleFraction] to the [onWindowFocus]
  /// function of the webview
  StreamController<double> visibleStream = StreamController<double>.broadcast();

  /// Helps get the height of the toolbar to accurately adjust the height of
  /// the editor when the keyboard is visible.
  GlobalKey toolbarKey = GlobalKey();

  /// Variable to cache the viewable size of the editor to update it in case
  /// the editor is focused much after its visibility changes
  double? cachedVisibleDecimal;

  @override
  void initState() {
    docHeight = widget.otherOptions.height;
    key = getRandString(10);
    if (widget.htmlEditorOptions.filePath != null) {
      filePath = widget.htmlEditorOptions.filePath!;
    } else if (widget.plugins.isEmpty) {
      filePath =
          'packages/html_editor_enhanced/assets/summernote-no-plugins.html';
    } else {
      filePath = 'packages/html_editor_enhanced/assets/summernote.html';
    }
    super.initState();
  }

  @override
  void dispose() {
    visibleStream.close();
    super.dispose();
  }

  /// resets the height of the editor to the original height
  void resetHeight() async {
    if (mounted) {
      this.setState(() {
        docHeight = widget.otherOptions.height;
      });
      await widget.controller.editorController!.evaluateJavascript(
          source:
              "\$('div.note-editable').outerHeight(${widget.otherOptions.height - (toolbarKey.currentContext?.size?.height ?? 0)});");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      },
      child: VisibilityDetector(
        key: Key(key),
        onVisibilityChanged: (VisibilityInfo info) async {
          if (!visibleStream.isClosed) {
            cachedVisibleDecimal = info.visibleFraction == 1
                ? (info.size.height / widget.otherOptions.height).clamp(0, 1)
                : info.visibleFraction;
            visibleStream.add(info.visibleFraction == 1
                ? (info.size.height / widget.otherOptions.height).clamp(0, 1)
                : info.visibleFraction);
          }
        },
        child: Container(
          height: docHeight + 10,
          decoration: widget.otherOptions.decoration,
          child: Column(
            children: [
              widget.htmlToolbarOptions.toolbarPosition ==
                      ToolbarPosition.aboveEditor
                  ? ToolbarWidget(
                      key: toolbarKey,
                      controller: widget.controller,
                      htmlToolbarOptions: widget.htmlToolbarOptions,
                      callbacks: widget.callbacks)
                  : Container(height: 0, width: 0),
              Expanded(
                child: WebViewWidget(
                  controller: widget.controller.editorController,
                  //initialFile: filePath,
                ),
              ),
              widget.htmlToolbarOptions.toolbarPosition ==
                      ToolbarPosition.belowEditor
                  ? ToolbarWidget(
                      key: toolbarKey,
                      controller: widget.controller,
                      htmlToolbarOptions: widget.htmlToolbarOptions,
                      callbacks: widget.callbacks)
                  : Container(height: 0, width: 0),
            ],
          ),
        ),
      ),
    );
  }

  /// adds the callbacks set by the user into the scripts
  void addJSCallbacks(Callbacks c) {
    if (c.onBeforeCommand != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.before.command', function(_, contents) {
            window.flutter_inappwebview.callHandler('onBeforeCommand', contents);
          });
        """);
    }
    if (c.onChangeCodeview != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.change.codeview', function(_, contents, \$editable) {
            window.flutter_inappwebview.callHandler('onChangeCodeview', contents);
          });
        """);
    }
    if (c.onDialogShown != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.dialog.shown', function() {
            window.flutter_inappwebview.callHandler('onDialogShown', 'fired');
          });
        """);
    }
    if (c.onEnter != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.enter', function() {
            window.flutter_inappwebview.callHandler('onEnter', 'fired');
          });
        """);
    }
    if (c.onFocus != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.focus', function() {
            window.flutter_inappwebview.callHandler('onFocus', 'fired');
          });
        """);
    }
    if (c.onBlur != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.blur', function() {
            window.flutter_inappwebview.callHandler('onBlur', 'fired');
          });
        """);
    }
    if (c.onBlurCodeview != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.blur.codeview', function() {
            window.flutter_inappwebview.callHandler('onBlurCodeview', 'fired');
          });
        """);
    }
    if (c.onKeyDown != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.keydown', function(_, e) {
            window.flutter_inappwebview.callHandler('onKeyDown', e.keyCode);
          });
        """);
    }
    if (c.onKeyUp != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.keyup', function(_, e) {
            window.flutter_inappwebview.callHandler('onKeyUp', e.keyCode);
          });
        """);
    }
    if (c.onMouseDown != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.mousedown', function(_) {
            window.flutter_inappwebview.callHandler('onMouseDown', 'fired');
          });
        """);
    }
    if (c.onMouseUp != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.mouseup', function(_) {
            window.flutter_inappwebview.callHandler('onMouseUp', 'fired');
          });
        """);
    }
    if (c.onPaste != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.paste', function(_) {
            window.flutter_inappwebview.callHandler('onPaste', 'fired');
          });
        """);
    }
    if (c.onScroll != null) {
      widget.controller.editorController!.evaluateJavascript(source: """
          \$('#summernote-2').on('summernote.scroll', function(_) {
            window.flutter_inappwebview.callHandler('onScroll', 'fired');
          });
        """);
    }
  }

  /// creates flutter_inappwebview JavaScript Handlers to handle any callbacks the
  /// user has defined
  void addJSHandlers(Callbacks c) {
    if (c.onBeforeCommand != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onBeforeCommand',
          callback: (contents) {
            c.onBeforeCommand!.call(contents.first.toString());
          });
    }
    if (c.onChangeCodeview != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onChangeCodeview',
          callback: (contents) {
            c.onChangeCodeview!.call(contents.first.toString());
          });
    }
    if (c.onDialogShown != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onDialogShown',
          callback: (_) {
            c.onDialogShown!.call();
          });
    }
    if (c.onEnter != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onEnter',
          callback: (_) {
            c.onEnter!.call();
          });
    }
    if (c.onFocus != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onFocus',
          callback: (_) {
            c.onFocus!.call();
          });
    }
    if (c.onBlur != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onBlur',
          callback: (_) {
            c.onBlur!.call();
          });
    }
    if (c.onBlurCodeview != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onBlurCodeview',
          callback: (_) {
            c.onBlurCodeview!.call();
          });
    }
    if (c.onImageLinkInsert != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onImageLinkInsert',
          callback: (url) {
            c.onImageLinkInsert!.call(url.first.toString());
          });
    }
    if (c.onImageUpload != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onImageUpload',
          callback: (files) {
            var file = fileUploadFromJson(files.first);
            c.onImageUpload!.call(file);
          });
    }
    if (c.onImageUploadError != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onImageUploadError',
          callback: (args) {
            if (!args.first.toString().startsWith('{')) {
              c.onImageUploadError!.call(
                  null,
                  args.first,
                  args.last.contains('base64')
                      ? UploadError.jsException
                      : args.last.contains('unsupported')
                          ? UploadError.unsupportedFile
                          : UploadError.exceededMaxSize);
            } else {
              var file = fileUploadFromJson(args.first.toString());
              c.onImageUploadError!.call(
                  file,
                  null,
                  args.last.contains('base64')
                      ? UploadError.jsException
                      : args.last.contains('unsupported')
                          ? UploadError.unsupportedFile
                          : UploadError.exceededMaxSize);
            }
          });
    }
    if (c.onKeyDown != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onKeyDown',
          callback: (keyCode) {
            c.onKeyDown!.call(keyCode.first);
          });
    }
    if (c.onKeyUp != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onKeyUp',
          callback: (keyCode) {
            c.onKeyUp!.call(keyCode.first);
          });
    }
    if (c.onMouseDown != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onMouseDown',
          callback: (_) {
            c.onMouseDown!.call();
          });
    }
    if (c.onMouseUp != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onMouseUp',
          callback: (_) {
            c.onMouseUp!.call();
          });
    }
    if (c.onPaste != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onPaste',
          callback: (_) {
            c.onPaste!.call();
          });
    }
    if (c.onScroll != null) {
      widget.controller.editorController!.addJavaScriptHandler(
          handlerName: 'onScroll',
          callback: (_) {
            c.onScroll!.call();
          });
    }
  }
}
