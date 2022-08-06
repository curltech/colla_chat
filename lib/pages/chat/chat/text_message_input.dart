import 'package:flutter/material.dart';
import 'extended_text_message_input.dart';

///发送文本消息的输入框和按钮，
///包括声音按钮，扩展文本输入框，emoji按钮，其他多种格式输入按钮和发送按钮
class TextMessageInputWidget extends StatefulWidget {
  final TextEditingController textEditingController;
  final void Function()? onSendPressed;
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

  @override
  void initState() {
    super.initState();
  }

  _update() {
    setState(() {});
  }

  Widget _buildExtendedTextField(context) {
    return ExtendedTextMessageInputWidget(
      textEditingController: widget.textEditingController,
    );
  }

  Widget _buildTextMessageInput(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(children: <Widget>[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 0.0),
            child: IconButton(
              icon: const Icon(Icons.record_voice_over),
              onPressed: () {},
            ),
          ),
          Expanded(
              child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0.0),
                  child: _buildExtendedTextField(context))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 0.0),
            child: IconButton(
              iconSize: 24,
              padding: EdgeInsets.zero,
              alignment: Alignment.centerRight,
              icon: const Icon(Icons.emoji_emotions),
              onPressed: () {
                if (widget.onEmojiPressed != null) {
                  widget.onEmojiPressed!();
                }
              },
            ),
          ),
          Visibility(
              visible: true,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.0),
                child: IconButton(
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerRight,
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (widget.onMorePressed != null) {
                      widget.onMorePressed!();
                    }
                  },
                ),
              )),
          Visibility(
              visible: true,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.0),
                child: IconButton(
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerRight,
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (widget.onSendPressed != null) {
                      widget.onSendPressed!();
                      widget.textEditingController.clear();
                    }
                  },
                ),
              ))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return _buildTextMessageInput(context);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
