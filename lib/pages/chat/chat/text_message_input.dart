import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:flutter/material.dart';

import 'extended_text_message_input.dart';

///发送文本消息的输入框和按钮，
///包括声音按钮，扩展文本输入框，emoji按钮，其他多种格式输入按钮和发送按钮
class TextMessageInputWidget extends StatefulWidget {
  final TextEditingController textEditingController;
  final Future<void> Function()? onSendPressed;
  final void Function()? onEmojiPressed;
  final void Function()? onMorePressed;

  const TextMessageInputWidget({
    Key? key,
    required this.textEditingController,
    this.onSendPressed,
    this.onEmojiPressed,
    this.onMorePressed,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TextMessageInputWidgetState();
  }
}

class _TextMessageInputWidgetState extends State<TextMessageInputWidget> {
  FocusNode textFocusNode = FocusNode();
  bool voiceVisible = true;
  bool sendVisible = false;
  bool moreVisible = false;
  bool keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    widget.textEditingController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Widget _buildExtendedTextField(context) {
    return ExtendedTextMessageInputWidget(
      textEditingController: widget.textEditingController,
    );
  }

  Widget _buildTextButton(context) {
    return TextButton(
      child: Text(AppLocalizations.t('Press recording')),
      onPressed: () {},
    );
  }

  bool _hasValue() {
    var value = widget.textEditingController.value.text;
    return StringUtil.isNotEmpty(value);
  }

  Widget _buildTextMessageInput(BuildContext context) {
    double iconInset = 2.0;
    return Container(
        margin:
            EdgeInsets.symmetric(horizontal: iconInset, vertical: iconInset),
        child: Row(children: <Widget>[
          Visibility(
              visible: voiceVisible,
              child: Container(
                margin: EdgeInsets.symmetric(
                    horizontal: iconInset, vertical: iconInset),
                child: InkWell(
                  child: const Icon(Icons.record_voice_over),
                  onTap: () {
                    setState(() {
                      voiceVisible = false;
                    });
                  },
                ),
                // child: IconButton(
                //   icon: const Icon(Icons.record_voice_over),
                //   onPressed: () {
                //     setState(() {
                //       voiceVisible = false;
                //     });
                //   },
                // ),
              )),
          Visibility(
              visible: !voiceVisible,
              child: Container(
                margin: EdgeInsets.symmetric(
                    horizontal: iconInset, vertical: iconInset),
                child: InkWell(
                  child: const Icon(Icons.keyboard),
                  onTap: () {
                    setState(() {
                      voiceVisible = true;
                    });
                  },
                ),
                // child: IconButton(
                //   icon: const Icon(Icons.keyboard),
                //   onPressed: () {
                //     setState(() {
                //       voiceVisible = true;
                //     });
                //   },
                // ),
              )),
          Expanded(
              child: Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: iconInset, vertical: iconInset),
                  child: voiceVisible
                      ? _buildExtendedTextField(context)
                      : _buildTextButton(context))),
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: iconInset, vertical: iconInset),
            child: InkWell(
              child: const Icon(Icons.emoji_emotions),
              onTap: () {
                if (widget.onEmojiPressed != null) {
                  widget.onEmojiPressed!();
                }
              },
            ),
            // child: IconButton(
            //   iconSize: 24,
            //   padding: EdgeInsets.zero,
            //   alignment: Alignment.centerRight,
            //   icon: const Icon(Icons.emoji_emotions),
            //   onPressed: () {
            //     if (widget.onEmojiPressed != null) {
            //       widget.onEmojiPressed!();
            //     }
            //   },
            // ),
          ),
          Visibility(
              visible: !_hasValue(),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                child: InkWell(
                  child: const Icon(Icons.add_circle),
                  onTap: () {
                    if (widget.onMorePressed != null) {
                      widget.onMorePressed!();
                    }
                  },
                ),
                // child: IconButton(
                //   icon: const Icon(Icons.add_circle),
                //   onPressed: () {
                //     if (widget.onMorePressed != null) {
                //       widget.onMorePressed!();
                //     }
                //   },
                // ),
              )),
          Visibility(
              visible: _hasValue(),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
                child: InkWell(
                  child: const Icon(Icons.send),
                  onTap: () {
                    if (widget.onSendPressed != null) {
                      widget.onSendPressed!();
                      widget.textEditingController.clear();
                    }
                  },
                ),
                // child: IconButton(
                //   icon: const Icon(Icons.send),
                //   onPressed: () {
                //     if (widget.onSendPressed != null) {
                //       widget.onSendPressed!();
                //       widget.textEditingController.clear();
                //     }
                //   },
                // ),
              ))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return _buildTextMessageInput(context);
  }

  @override
  void dispose() {
    widget.textEditingController.removeListener(_update);
    super.dispose();
  }
}
