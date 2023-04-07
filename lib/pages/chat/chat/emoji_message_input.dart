import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/special_text/emoji_text.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

///Emoji文本消息的输入面板
class EmojiMessageInputWidget extends StatefulWidget {
  final Function(String text)? onTap;

  const EmojiMessageInputWidget({
    Key? key,
    required this.onTap,
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

  ///构造自定义的emoji的选择组件
  Widget _buildEmojiWidget(BuildContext context) {
    return GestureDetector(
      child: SizedBox(
        height: chatMessageViewController.emojiMessageInputHeight,
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

  Widget _buildEmojiPicker(BuildContext context) {
    Color primary = myself.primary;
    return SizedBox(
        height: chatMessageViewController.emojiMessageInputHeight,
        child: EmojiPicker(
            //textEditingController: TextEditingController(),
            onEmojiSelected: (Category? category, Emoji emoji) {
              if (widget.onTap != null) {
                widget.onTap!(emoji.emoji);
              }
            },
            config: Config(
                columns: 10,
                emojiSizeMax: 24 * (platformParams.ios ? 1.30 : 1.0),
                verticalSpacing: 0,
                horizontalSpacing: 0,
                gridPadding: EdgeInsets.zero,
                initCategory: Category.RECENT,
                bgColor: Colors.white.withOpacity(0.0),
                indicatorColor: primary,
                iconColor: Colors.grey,
                iconColorSelected: primary,
                backspaceColor: primary,
                skinToneDialogBgColor: Colors.white.withOpacity(0.0),
                skinToneIndicatorColor: Colors.grey,
                enableSkinTones: true,
                showRecentsTab: true,
                recentsLimit: 28,
                replaceEmojiOnLimitExceed: false,
                noRecents: CommonAutoSizeText(
                  AppLocalizations.t('No Recents'),
                  style: const TextStyle(fontSize: 20, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                tabIndicatorAnimDuration: kTabScrollDuration,
                categoryIcons: const CategoryIcons(),
                buttonMode: ButtonMode.MATERIAL)));
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
