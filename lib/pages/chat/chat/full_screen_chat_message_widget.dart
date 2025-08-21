import 'package:auto_size_text/auto_size_text.dart';
import 'package:carousel_slider_plus/carousel_options.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/platform_carousel.dart';
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

  final PlatformCarouselController controller = PlatformCarouselController();

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
      return AutoSizeText(
        title,
        style: TextStyle(fontSize: title.length > 12 ? 20 : 24),
      );
    });
  }

  Widget _buildFullScreenWidget(BuildContext context) {
    return PlatformCarouselWidget(
      controller: controller,
      itemBuilder: (BuildContext context, int index, {int? realIndex}) {
        return Center(
            child: PlatformFutureBuilder(
          future: _buildMessageWidget(context, index),
          builder: (BuildContext context, Widget child) {
            return child;
          },
        ));
      },
      itemCount: chatMessageController.length,
      initialPage: chatMessageController.currentIndex.value ?? 0,
      onPageChanged: (index,
          {PlatformSwiperDirection? direction,
          int? oldIndex,
          CarouselPageChangedReason? reason}) {
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
                controller.next();
              },
              icon: const Icon(Icons.more_horiz_outlined))
        ],
        child: _buildFullScreenWidget(context));
  }
}
