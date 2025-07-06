import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/emoji_util.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:unicode_emojis/unicode_emojis.dart';

class UnicodeEmojiPicker extends StatefulWidget {
  final double height;
  final Function(String) onTap;

  const UnicodeEmojiPicker(
      {super.key, required this.height, required this.onTap});

  @override
  State<UnicodeEmojiPicker> createState() {
    return _UnicodeEmojiPickerState();
  }
}

class _UnicodeEmojiPickerState extends State<UnicodeEmojiPicker>
    with SingleTickerProviderStateMixin {
  late final Widget unicodeEmojiWidget = _buildUnicodeEmojiWidget(context);

  Widget _buildUnicodeEmojiWidget(BuildContext context) {
    Map<Category, List<Emoji>> allEmojis = EmojiUtil.emojis;
    List<Tab> tabs = [];

    List<Widget> tabViews = [];
    for (var entry in allEmojis.entries) {
      var category = entry.key;
      tabs.add(Tab(
        icon: AutoSizeText(AppLocalizations.t(category.description)),
      ));
      List<Emoji> emojis = entry.value;
      List<Widget> eles = [];
      for (var emoji in emojis) {
        Widget ele = InkWell(
          onTap: () {
            widget.onTap(emoji.emoji);
          },
          child: ExtendedText(
            emoji.emoji,
            style: const TextStyle(fontSize: 28),
          ),
        );
        eles.add(ele);
      }
      Widget tabView = SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Wrap(spacing: 10.0, runSpacing: 5.0, children: eles)));
      tabViews.add(tabView);
    }

    final TabController tabController =
        TabController(length: tabs.length, vsync: this);
    final tabBar = TabBar(
      tabs: tabs,
      controller: tabController,
      isScrollable: false,
      indicatorColor: myself.primary,
      labelColor: Colors.white,
      dividerColor: Colors.white.withOpacity(0),
      padding: const EdgeInsets.all(0.0),
      labelPadding: const EdgeInsets.all(0.0),
    );
    TabBarView tabBarView = TabBarView(
      controller: tabController,
      children: tabViews,
    );
    return SizedBox(
      height: widget.height,
      child: Column(
        children: [tabBar, Expanded(child: tabBarView)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return unicodeEmojiWidget;
  }
}
