import 'dart:async';
import 'dart:math';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../widgets/special_text/at_text.dart';
import '../../../widgets/special_text/custom_extended_text_selection_controls.dart';
import '../../../widgets/special_text/custom_special_text_span_builder.dart';
import '../../../widgets/special_text/dollar_text.dart';
import '../../../widgets/special_text/emoji_text.dart';

///发送文本消息的输入框
class ExtendedTextMessageInputWidget extends StatefulWidget {
  const ExtendedTextMessageInputWidget({Key? key}) : super(key: key);

  @override
  State createState() => _ExtendedTextMessageInputWidgetState();
}

class _ExtendedTextMessageInputWidgetState
    extends State<ExtendedTextMessageInputWidget> {
  final TextEditingController textEditingController = TextEditingController();
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
  List<String> sessions = <String>[
    '[44] @Dota2 CN dota best dota',
    'yes, you are right [36].',
    '大家好，我是拉面，很萌很新 [12].',
    '\$Flutter\$. CN dev best dev',
    '\$Dota2 Ti9\$. Shanghai,I\'m coming.',
    'error 0 [45] warning 0',
  ];

  @override
  Widget build(BuildContext context) {
    //FocusScope.of(context).autofocus(_focusNode);
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

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
      maxLines: 2,
      strutStyle: const StrutStyle(),
      specialTextSpanBuilder: CustomSpecialTextSpanBuilder(
        showAtBackground: true,
      ),
      controller: textEditingController,
      selectionControls: extendedMaterialTextSelectionControls,
      focusNode: focusNode,
      autofocus: true,
      onTap: () => setState(() {
        if (focusNode.hasFocus) {}
        sessions.insert(0, textEditingController.text);
        textEditingController.value = textEditingController.value.copyWith(
            text: '',
            selection: const TextSelection.collapsed(offset: 0),
            composing: TextRange.empty);
      }),
      onChanged: (v) => setState(() {}),
      decoration: const InputDecoration.collapsed(
          hintText: 'Please input message',),
      //textDirection: TextDirection.rtl,
    );
  }

  void onToolbarButtonActiveChanged(
      double keyboardHeight, bool active, Function activeOne) {
    if (keyboardHeight > 0) {
      // make sure grid height = keyboardHeight
      _keyboardHeight = keyboardHeight;
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    }

    if (active) {
      activeDollarGrid = activeEmojiGird = activeAtGrid = false;
    }

    activeOne();
    //activeDollarGrid = active;

    gridBuilderController.add(null);
  }

  Widget buildCustomKeyBoard() {
    if (!showCustomKeyBoard) {
      return Container();
    }
    if (activeEmojiGird) {
      return buildEmojiGird();
    }
    if (activeAtGrid) {
      return buildAtGrid();
    }
    if (activeDollarGrid) {
      return buildDollarGrid();
    }
    return Container();
  }

  Widget buildEmojiGird() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0),
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            insertText('[${index + 1}]');
          },
          child: Image.asset(EmojiUitl.instance.emojiMap['[${index + 1}]']!),
        );
      },
      itemCount: EmojiUitl.instance.emojiMap.length,
      padding: const EdgeInsets.all(5.0),
    );
  }

  Widget buildAtGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0),
      itemBuilder: (BuildContext context, int index) {
        final String text = atList[index];
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            insertText(text);
          },
          child: Align(
            child: Text(text),
          ),
        );
      },
      itemCount: atList.length,
      padding: const EdgeInsets.all(5.0),
    );
  }

  Widget buildDollarGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0),
      itemBuilder: (BuildContext context, int index) {
        final String text = dollarList[index];
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            insertText(text);
          },
          child: Align(
            child: Text(text.replaceAll('\$', '')),
          ),
        );
      },
      itemCount: dollarList.length,
      padding: const EdgeInsets.all(5.0),
    );
  }

  void insertText(String text) {
    final TextEditingValue value = textEditingController.value;
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

      textEditingController.value = value.copyWith(
          text: newText,
          selection: value.selection.copyWith(
              baseOffset: end + text.length, extentOffset: end + text.length));
    } else {
      textEditingController.value = TextEditingValue(
          text: text,
          selection:
              TextSelection.fromPosition(TextPosition(offset: text.length)));
    }

    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      _key.currentState?.bringIntoView(textEditingController.selection.base);
    });
  }

  void manualDelete() {
    //delete by code
    final TextEditingValue _value = textEditingController.value;
    final TextSelection selection = _value.selection;
    if (!selection.isValid) {
      return;
    }

    TextEditingValue value;
    final String actualText = _value.text;
    if (selection.isCollapsed && selection.start == 0) {
      return;
    }
    final int start =
        selection.isCollapsed ? selection.start - 1 : selection.start;
    final int end = selection.end;

    value = TextEditingValue(
      text: actualText.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );

    final TextSpan oldTextSpan = specialTextSpanBuilder.build(_value.text);

    value = handleSpecialTextSpanDelete(value, _value, oldTextSpan, null);

    textEditingController.value = value;
  }
}
