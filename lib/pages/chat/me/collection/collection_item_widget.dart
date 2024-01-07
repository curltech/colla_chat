import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_chat_message_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

class CollectionItemWidget extends StatefulWidget with TileDataMixin {
  CollectionItemWidget({super.key});

  @override
  State createState() => _CollectionItemWidgetState();

  @override
  String get routeName => 'collection_item';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.collections;

  @override
  String get title => 'Collection Item';
}

class _CollectionItemWidgetState extends State<CollectionItemWidget> {
  SwiperController swiperController = SwiperController();
  final index =
      ValueNotifier<int>(collectionChatMessageController.currentIndex);

  @override
  void initState() {
    super.initState();
    collectionChatMessageController.addListener(_update);
  }

  _update() {
    index.value = collectionChatMessageController.currentIndex;
  }

  Future<Widget> _buildMessageWidget(BuildContext context, int index) async {
    ChatMessage chatMessage = collectionChatMessageController.data[index];
    Widget child;
    MessageWidget messageWidget =
        MessageWidget(chatMessage, index, fullScreen: true);
    child = await messageWidget.buildMessageBody(context);

    return child;
  }

  Widget _buildTitleWidget() {
    return ValueListenableBuilder<int>(
        valueListenable: index,
        builder: (context, value, child) {
          ChatMessage? chatMessage = collectionChatMessageController.current;
          var title = AppLocalizations.t(widget.title);
          if (chatMessage != null && chatMessage.title != null) {
            title = chatMessage.title!;
          }
          return CommonAutoSizeText(
            title,
            style: TextStyle(fontSize: title.length > 12 ? 20 : 24),
          );
        });
  }

  Widget _buildCollectionWidget(BuildContext context) {
    return Swiper(
      controller: swiperController,
      itemBuilder: (BuildContext context, int index) {
        return Center(
            child: FutureBuilder(
          future: _buildMessageWidget(context, index),
          builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
            Widget widget = snapshot.data ?? Container();
            return widget;
          },
        ));
      },
      itemCount: collectionChatMessageController.length,
      index: collectionChatMessageController.currentIndex,
      onIndexChanged: (index) {
        collectionChatMessageController.currentIndex = index;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        titleWidget: _buildTitleWidget(),
        withLeading: true,
        child: _buildCollectionWidget(context));
  }

  @override
  void dispose() {
    collectionChatMessageController.removeListener(_update);
    super.dispose();
  }
}
