import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FullScreenChatMessageWidget extends StatelessWidget with TileDataMixin {
  FullScreenChatMessageWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'full_screen_chat_message';

  @override
  IconData get iconData => Icons.fullscreen;

  @override
  String get title => 'FullScreenChatMessage';

  

  SwiperController swiperController = SwiperController();

  Future<Widget> _buildMessageWidget(BuildContext context, int index) async {
    ChatMessage chatMessage = chatMessageController.data[index];
    Widget child;
    MessageWidget messageWidget =
        MessageWidget(chatMessage, index, fullScreen: true);
    child = await messageWidget.buildMessageBody(context);

    return child;
  }

  Widget _buildTitleWidget() {
    return Obx(() {
      ChatMessage? chatMessage = chatMessageController.current;
      var title = AppLocalizations.t(this.title);
      if (chatMessage != null) {
        title = '${chatMessage.receiverName} - ${chatMessage.senderName}';
      }
      return CommonAutoSizeText(
        title,
        style: TextStyle(fontSize: title.length > 12 ? 20 : 24),
      );
    });
  }

  Widget _buildFullScreenWidget(BuildContext context) {
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
      itemCount: chatMessageController.length,
      index: chatMessageController.currentIndex.value,
      onIndexChanged: (index) {
        chatMessageController.setCurrentIndex = index;
      },
    );
  }

  _shareChatMessage() {}

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        titleWidget: _buildTitleWidget(),
        helpPath: routeName,
        withLeading: true,
        rightWidgets: [
          IconButton(
              onPressed: () {
                swiperController.next();
              },
              icon: const Icon(Icons.more_horiz_outlined))
        ],
        child: _buildFullScreenWidget(context));
  }
}
