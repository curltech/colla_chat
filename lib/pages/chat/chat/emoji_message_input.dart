import 'package:colla_chat/platform.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
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

  Widget _buildEmojiPicker() {
    return EmojiPicker(
        textEditingController: TextEditingController(),
        onEmojiSelected: (Category category, Emoji emoji) {
          if (widget.onTap != null) {
            widget.onTap!(emoji.emoji);
          }
        },
        config: Config(
            columns: 7,
            emojiSizeMax: 32 * (PlatformParams.instance.ios ? 1.30 : 1.0),
            verticalSpacing: 0,
            horizontalSpacing: 0,
            gridPadding: EdgeInsets.zero,
            initCategory: Category.RECENT,
            bgColor: const Color(0xFFF2F2F2),
            indicatorColor: Colors.blue,
            iconColor: Colors.grey,
            iconColorSelected: Colors.blue,
            progressIndicatorColor: Colors.blue,
            backspaceColor: Colors.blue,
            skinToneDialogBgColor: Colors.white,
            skinToneIndicatorColor: Colors.grey,
            enableSkinTones: true,
            showRecentsTab: true,
            recentsLimit: 28,
            replaceEmojiOnLimitExceed: false,
            noRecents: const Text(
              'No Recents',
              style: TextStyle(fontSize: 20, color: Colors.black26),
              textAlign: TextAlign.center,
            ),
            tabIndicatorAnimDuration: kTabScrollDuration,
            categoryIcons: const CategoryIcons(),
            buttonMode: ButtonMode.MATERIAL));
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
