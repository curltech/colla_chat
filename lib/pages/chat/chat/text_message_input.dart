import 'package:flutter/material.dart';
import 'extended_text_message_input.dart';

///发送文本消息的输入框和按钮，三个按钮，一个输入框
class TextMessageInputWidget extends StatefulWidget {
  const TextMessageInputWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _TextMessageInputWidgetState();
  }
}

class _TextMessageInputWidgetState extends State<TextMessageInputWidget> {
  final TextEditingController textEditingController = TextEditingController();
  FocusNode textFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  _update() {
    setState(() {});
  }

  Widget _buildExtendedTextField(context) {
    return const ExtendedTextMessageInputWidget();
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
              onPressed: () {},
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
                  onPressed: () {},
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
                  onPressed: () {},
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
