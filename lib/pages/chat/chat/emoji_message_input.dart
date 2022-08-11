import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import '../../../widgets/special_text/emoji_text.dart';

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

  Widget _buildEmojiPicker(BuildContext context) {
    Color primary = appDataProvider.themeData!.colorScheme.primary;
    return SizedBox(
        height: widget.height,
        child: EmojiPicker(
            textEditingController: TextEditingController(),
            onEmojiSelected: (Category category, Emoji emoji) {
              if (widget.onTap != null) {
                widget.onTap!(emoji.emoji);
              }
            },
            config: Config(
                columns: 10,
                emojiSizeMax: 24 * (PlatformParams.instance.ios ? 1.30 : 1.0),
                verticalSpacing: 0,
                horizontalSpacing: 0,
                gridPadding: EdgeInsets.zero,
                initCategory: Category.RECENT,
                bgColor: Colors.white.withOpacity(0.0),
                indicatorColor: primary,
                iconColor: Colors.grey,
                iconColorSelected: primary,
                progressIndicatorColor: primary,
                backspaceColor: primary,
                skinToneDialogBgColor: Colors.white.withOpacity(0.0),
                skinToneIndicatorColor: Colors.grey,
                enableSkinTones: true,
                showRecentsTab: true,
                recentsLimit: 28,
                replaceEmojiOnLimitExceed: false,
                noRecents: Text(
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
