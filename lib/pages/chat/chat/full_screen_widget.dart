import 'package:card_swiper/card_swiper.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

class FullScreenWidget extends StatefulWidget with TileDataMixin {
  const FullScreenWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FullScreenWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'full_screen';

  @override
  IconData get iconData => Icons.fullscreen;

  @override
  String get title => 'FullScreen';
}

class _FullScreenWidgetState extends State<FullScreenWidget> {
  SwiperController swiperController = SwiperController();
  final index = ValueNotifier<int>(chatMessageController.currentIndex);

  @override
  void initState() {
    super.initState();
    chatMessageController.addListener(_update);
  }

  _update() {
    index.value = chatMessageController.currentIndex;
  }

  Future<Widget> _buildMessageWidget(BuildContext context, int index) async {
    ChatMessage chatMessage = chatMessageController.data[index];
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
          ChatMessage? chatMessage = chatMessageController.current;
          var title = AppLocalizations.t(widget.title);
          if (chatMessage != null) {
            title = '${chatMessage.senderName} => ${chatMessage.receiverName}';
          }
          return Text(title);
        });
  }

  Widget _buildFullScreenWidget(BuildContext context) {
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
      itemCount: chatMessageController.length,
      index: chatMessageController.currentIndex,
      onIndexChanged: (index) {
        chatMessageController.currentIndex = index;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBarView(
        titleWidget: _buildTitleWidget(),
        withLeading: true,
        child: _buildFullScreenWidget(context));
  }

  @override
  void dispose() {
    chatMessageController.removeListener(_update);
    super.dispose();
  }
}
