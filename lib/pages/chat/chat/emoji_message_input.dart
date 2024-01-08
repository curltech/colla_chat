import 'package:colla_chat/pages/chat/chat/controller/chat_message_view_controller.dart';
import 'package:colla_chat/widgets/special_text/emoji_text.dart';
import 'package:flutter/material.dart';

///Emoji文本消息的输入面板
class EmojiMessageInputWidget extends StatefulWidget {
  final Function(String text)? onTap;

  const EmojiMessageInputWidget({
    super.key,
    required this.onTap,
  });

  @override
  State<StatefulWidget> createState() {
    return _EmojiMessageInputWidgetState();
  }
}

class _EmojiMessageInputWidgetState extends State<EmojiMessageInputWidget> {
  final textEditingController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  _onBackspacePressed() {
    textEditingController
      ..text = textEditingController.text.characters.toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: textEditingController.text.length));
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

  // Widget _buildEmojiPicker(BuildContext context) {
  //   Color primary = myself.primary;
  //   return SizedBox(
  //       height: chatMessageViewController.emojiMessageInputHeight,
  //       child: EmojiPicker(
  //         textEditingController: textEditingController,
  //         onEmojiSelected: (Category? category, Emoji emoji) {
  //           if (widget.onTap != null) {
  //             widget.onTap!(emoji.emoji);
  //           }
  //         },
  //         scrollController: scrollController,
  //         onBackspacePressed: _onBackspacePressed,
  //         config: Config(
  //           height: 256,
  //           checkPlatformCompatibility: true,
  //           emojiViewConfig: EmojiViewConfig(
  //             columns: 10,
  //             emojiSizeMax: 24 * (platformParams.ios ? 1.30 : 1.0),
  //             verticalSpacing: 0,
  //             horizontalSpacing: 0,
  //             backgroundColor: Colors.white.withOpacity(0.0),
  //             gridPadding: EdgeInsets.zero,
  //             recentsLimit: 28,
  //             replaceEmojiOnLimitExceed: false,
  //             loadingIndicator: const SizedBox.shrink(),
  //             noRecents: CommonAutoSizeText(
  //               AppLocalizations.t('No Recents'),
  //               style: const TextStyle(fontSize: 20, color: Colors.black),
  //               textAlign: TextAlign.center,
  //             ),
  //             buttonMode: ButtonMode.MATERIAL,
  //           ),
  //           swapCategoryAndBottomBar: false,
  //           skinToneConfig: SkinToneConfig(indicatorColor: primary),
  //           categoryViewConfig: const CategoryViewConfig(),
  //           bottomActionBarConfig: const BottomActionBarConfig(),
  //           searchViewConfig: const SearchViewConfig(),
  //         ),
  //       ));
  // }

  @override
  Widget build(BuildContext context) {
    return _buildEmojiWidget(context);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
