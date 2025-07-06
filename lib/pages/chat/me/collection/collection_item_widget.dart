import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_chat_message_controller.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CollectionItemWidget extends StatelessWidget with TileDataMixin {
  CollectionItemWidget({super.key});

  @override
  String get routeName => 'collection_item';

  @override
  bool get withLeading => true;

  @override
  IconData get iconData => Icons.collections;

  @override
  String get title => 'Collection Item';

  

  SwiperController swiperController = SwiperController();

  Future<Widget> _buildMessageWidget(BuildContext context, int index) async {
    ChatMessage chatMessage = collectionChatMessageController.data[index];
    Widget child;
    MessageWidget messageWidget =
        MessageWidget(chatMessage, index, fullScreen: true);
    child = await messageWidget.buildMessageBody(context);

    return child;
  }

  Widget _buildTitleWidget() {
    return Obx(() {
      ChatMessage? chatMessage = collectionChatMessageController.current;
      var title = AppLocalizations.t(this.title);
      if (chatMessage != null && chatMessage.title != null) {
        title = chatMessage.title!;
      }
      return AutoSizeText(
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
            child: PlatformFutureBuilder(
          future: _buildMessageWidget(context, index),
          builder: (BuildContext context, Widget child) {
            return child;
          },
        ));
      },
      itemCount: collectionChatMessageController.length,
      index: collectionChatMessageController.currentIndex.value,
      onIndexChanged: (index) {
        collectionChatMessageController.setCurrentIndex = index;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        titleWidget: _buildTitleWidget(),
        helpPath: routeName,
        withLeading: true,
        child: _buildCollectionWidget(context));
  }
}
