import 'package:flutter/material.dart';
import '../../../widgets/special_text/emoji_text.dart';
import 'extended_text_message_input.dart';

///Emoji文本消息的输入面板
class EmojiMessageInputWidget extends StatefulWidget {
  final Function(String text)? onTap;
  final double height;

  EmojiMessageInputWidget({
    Key? key,
    required this.onTap,
    this.height = 0,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _EmojiMessageInputWidgetState();
  }
}

class _EmojiMessageInputWidgetState extends State<EmojiMessageInputWidget> {
  @override
  void initState() {
    super.initState();
  }

  _update() {
    setState(() {});
  }

  Widget _buildEmojiWidget(BuildContext context) {
    return GestureDetector(
      child: SizedBox(
        height: widget.height,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            // return Ink(
            //     child: InkWell(
            //   onTap: () {
            //     if (widget.onTap != null) {
            //       widget.onTap!("[${index + 1}]");
            //     }
            //   },
            //   child:
            //       Image.asset(emojiTextCollection.emojiMap["[${index + 1}]"]!),
            // ));
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (widget.onTap != null) {
                  widget.onTap!("[${index + 1}]");
                }
              },
              child:
                  Image.asset(emojiTextCollection.emojiMap["[${index + 1}]"]!),
            );
          },
          itemCount: emojiTextCollection.emojiMap.length,
          padding: const EdgeInsets.all(15.0),
        ),
      ),
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildEmojiWidget(context);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
