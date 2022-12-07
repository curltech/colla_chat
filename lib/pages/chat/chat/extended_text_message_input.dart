import 'dart:async';
import 'dart:math';

import 'package:colla_chat/entity/chat/contact.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/service/chat/contact.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/special_text/custom_extended_text_selection_controls.dart';
import 'package:colla_chat/widgets/special_text/custom_special_text_span_builder.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

///发送文本消息的输入框
class ExtendedTextMessageInputWidget extends StatefulWidget {
  final TextEditingController textEditingController;

  const ExtendedTextMessageInputWidget(
      {Key? key, required this.textEditingController})
      : super(key: key);

  @override
  State createState() => _ExtendedTextMessageInputWidgetState();
}

class _ExtendedTextMessageInputWidgetState
    extends State<ExtendedTextMessageInputWidget> {
  final CustomTextSelectionControls extendedMaterialTextSelectionControls =
      CustomTextSelectionControls();
  final GlobalKey<ExtendedTextFieldState> _key =
      GlobalKey<ExtendedTextFieldState>();
  final CustomSpecialTextSpanBuilder specialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();
  final StreamController<void> gridBuilderController =
      StreamController<void>.broadcast();

  final FocusNode focusNode = FocusNode();
  double _keyboardHeight = 0;
  double _preKeyboardHeight = 0;

  bool get showCustomKeyBoard =>
      activeEmojiGird || activeAtGrid || activeDollarGrid;
  bool activeEmojiGird = false;
  bool activeAtGrid = false;
  bool activeDollarGrid = false;

  //获取焦点
  void getFocusFunction(BuildContext context) {
    FocusScope.of(context).requestFocus(focusNode);
  }

  //失去焦点
  void unFocusFunction() {
    focusNode.unfocus();
  }

  //隐藏键盘而不丢失文本字段焦点
  void hideKeyBoard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _insertText(String text) {
    final TextEditingValue value = widget.textEditingController.value;
    final int start = value.selection.baseOffset;
    int end = value.selection.extentOffset;
    if (value.selection.isValid) {
      String newText = '';
      if (value.selection.isCollapsed) {
        if (end > 0) {
          newText += value.text.substring(0, end);
        }
        newText += text;
        if (value.text.length > end) {
          newText += value.text.substring(end, value.text.length);
        }
      } else {
        newText = value.text.replaceRange(start, end, text);
        end = start;
      }

      widget.textEditingController.value = value.copyWith(
          text: newText,
          selection: value.selection.copyWith(
              baseOffset: end + text.length, extentOffset: end + text.length));
    } else {
      widget.textEditingController.value = TextEditingValue(
          text: text,
          selection:
              TextSelection.fromPosition(TextPosition(offset: text.length)));
    }

    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      _key.currentState
          ?.bringIntoView(widget.textEditingController.selection.base);
    });
  }

  void _deleteText() {
    //delete by code
    final TextEditingValue value = widget.textEditingController.value;
    final TextSelection selection = value.selection;
    if (!selection.isValid) {
      return;
    }

    TextEditingValue textEditingValue;
    final String actualText = value.text;
    if (selection.isCollapsed && selection.start == 0) {
      return;
    }
    final int start =
        selection.isCollapsed ? selection.start - 1 : selection.start;
    final int end = selection.end;

    textEditingValue = TextEditingValue(
      text: actualText.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );

    final TextSpan oldTextSpan = specialTextSpanBuilder.build(value.text);

    textEditingValue =
        handleSpecialTextSpanDelete(textEditingValue, value, oldTextSpan, null);

    widget.textEditingController.value = textEditingValue;
  }

  void _clearText() {
    widget.textEditingController.value = widget.textEditingController.value
        .copyWith(
            text: '',
            selection: const TextSelection.collapsed(offset: 0),
            composing: TextRange.empty);
  }

  _onSelected(List<String> selected) async {
    if (selected.isNotEmpty) {
      Linkman? linkman =
          await linkmanService.findCachedOneByPeerId(selected[0]);
      if (linkman != null) {
        widget.textEditingController.text =
            widget.textEditingController.text + linkman.name;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //FocusScope.of(context).autofocus(_focusNode);
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    final double keyboardHeight = mediaQueryData.viewInsets.bottom;
    appDataProvider.keyboardHeight = keyboardHeight;

    final bool showingKeyboard = keyboardHeight > _preKeyboardHeight;
    _preKeyboardHeight = keyboardHeight;
    if ((keyboardHeight > 0 && keyboardHeight >= _keyboardHeight) ||
        showingKeyboard) {
      activeEmojiGird = activeAtGrid = activeDollarGrid = false;
      gridBuilderController.add(null);
    }

    _keyboardHeight = max(_keyboardHeight, keyboardHeight);

    return ExtendedTextField(
      key: _key,
      minLines: 1,
      maxLines: 4,
      strutStyle: const StrutStyle(),
      specialTextSpanBuilder: CustomSpecialTextSpanBuilder(
        showAtBackground: true,
      ),
      controller: widget.textEditingController,
      selectionControls: extendedMaterialTextSelectionControls,
      focusNode: focusNode,
      autofocus: true,
      onTap: () => setState(() {
        if (focusNode.hasFocus) {}
      }),
      onChanged: (String value) {
        if (value == '@') {
          DialogUtil.show(
              context: context,
              title: 'Select one linkman',
              builder: (BuildContext context) {
                return LinkmanGroupSearchWidget(
                    onSelected: _onSelected,
                    selected: [],
                    selectType: SelectType.multidialog);
              });
        }
      },
      //onChanged: onChanged,
      decoration: InputDecoration(
        hintText: AppLocalizations.t('Please input message'),
        //isCollapsed: true,
        fillColor: Colors.grey.withOpacity(0.3),
        filled: true,
        border: InputBorder.none,
      ),
      //textDirection: TextDirection.rtl,
    );
  }
}
