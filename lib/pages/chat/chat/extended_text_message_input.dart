import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/pages/chat/linkman/group_linkman_widget.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:colla_chat/widgets/special_text/custom_extended_text_selection_controls.dart';
import 'package:colla_chat/widgets/special_text/custom_special_text_span_builder.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  final CustomSpecialTextSpanBuilder specialTextSpanBuilder =
      CustomSpecialTextSpanBuilder();

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
      chatMessageViewController.extendedTextKey.currentState
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

  _onSelected(List<String> selected) {
    if (selected.isNotEmpty) {
      linkmanService
          .findCachedOneByPeerId(selected[0])
          .then((Linkman? linkman) {
        if (linkman != null) {
          widget.textEditingController.text =
              widget.textEditingController.text + linkman.name;
        }
      });
    }
    Navigator.pop(context, selected);
  }

  _selectGroupLinkman() async {
    var chatSummary = chatMessageController.chatSummary;
    if (chatSummary != null) {
      if (chatSummary.partyType == PartyType.group.name) {
        var groupPeerId = chatSummary.peerId;
        await DialogUtil.show(
            context: context,
            builder: (BuildContext context) {
              return GroupLinkmanWidget(
                selectType: SelectType.singleSelect,
                onSelected: _onSelected,
                selected: const <String>[],
                groupPeerId: groupPeerId!,
              );
            });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    chatMessageViewController.changeExtendedTextHeight();
    //不随系统的字体大小变化
    return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: ExtendedTextField(
          key: chatMessageViewController.extendedTextKey,
          minLines: 1,
          maxLines: 8,
          style: const TextStyle(fontSize: AppFontSize.mdFontSize),
          specialTextSpanBuilder: CustomSpecialTextSpanBuilder(
            showAtBackground: true,
          ),
          controller: widget.textEditingController,
          selectionControls: extendedMaterialTextSelectionControls,
          focusNode: chatMessageViewController.focusNode,
          onChanged: (String value) async {
            if (value == '@') {
              await _selectGroupLinkman();
            }
          },
          //onChanged: onChanged,
          decoration: InputDecoration(
            fillColor: Colors.grey.withOpacity(AppOpacity.lgOpacity),
            filled: true,
            border: textFormFieldBorder,
            focusedBorder: textFormFieldBorder,
            enabledBorder: textFormFieldBorder,
            errorBorder: textFormFieldBorder,
            disabledBorder: textFormFieldBorder,
            focusedErrorBorder: textFormFieldBorder,
            hintText: AppLocalizations.t('Please input message'),
            suffixIcon: widget.textEditingController.text.isNotEmpty
                ? InkWell(
                    onTap: () {
                      widget.textEditingController.clear();
                    },
                    child: Icon(
                      Icons.clear_rounded,
                      color: myself.primary,
                    ),
                  )
                : null,
            //isCollapsed: true,
          ),
          //textDirection: TextDirection.rtl,
        ));
  }
}
