import 'dart:async';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/pages/chat/channel/channel_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/channel/channel_message_view.dart';
import 'package:colla_chat/pages/chat/channel/publish_channel_list_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

//频道的页面,展示自己订阅的频道消息列表
class SubscribeChannelListWidget extends StatefulWidget with TileDataMixin {
  final Future<void> Function()? onRefresh;
  final Function()? onScrollMax;
  final Function()? onScrollMin;
  final ScrollController scrollController = ScrollController();
  final PublishChannelListWidget publishChannelListWidget =
      PublishChannelListWidget();
  final ChannelMessageView channelMessageView = ChannelMessageView();

  SubscribeChannelListWidget({
    Key? key,
    this.onRefresh,
    this.onScrollMax,
    this.onScrollMin,
  }) : super(key: key) {
    indexWidgetProvider.define(publishChannelListWidget);
    indexWidgetProvider.define(channelMessageView);
  }

  @override
  State createState() => _SubscribeChannelListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'channel';

  @override
  IconData get iconData => Icons.wifi_channel;

  @override
  String get title => 'Channel';
}

class _SubscribeChannelListWidgetState extends State<SubscribeChannelListWidget>
    with TickerProviderStateMixin {
  late final AnimationController animateController;

  @override
  void initState() {
    super.initState();
    channelChatMessageController.addListener(_update);
    var scrollController = widget.scrollController;
    scrollController.addListener(_onScroll);
    animateController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
  }

  _update() {
    setState(() {
      channelChatMessageController.latest();
    });
  }

  void _onScroll() {
    double offset = widget.scrollController.offset;
    logger.i('scrolled to $offset');

    ///判断是否滚动到最底，需要加载更多数据
    if (widget.scrollController.position.pixels ==
        widget.scrollController.position.maxScrollExtent) {
      logger.i('scrolled to max');
      if (widget.onScrollMax != null) {
        widget.onScrollMax!();
      }
    }
    if (widget.scrollController.position.pixels ==
        widget.scrollController.position.minScrollExtent) {
      logger.i('scrolled to min');
      if (widget.onScrollMin != null) {
        widget.onScrollMin!();
      }
    }
  }

  Future<void> _onRefresh() async {
    ///下拉刷新数据的地方，比如从数据库取更多数据
    logger.i('RefreshIndicator onRefresh');
    channelChatMessageController.previous(limit: defaultLimit);
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  _scrollMin() {
    // scroll to the bottom of the list when keyboard appears
    Timer(
        const Duration(milliseconds: 200),
        () => widget.scrollController.animateTo(
            widget.scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeIn));
  }

  ///创建每一条消息
  Widget _buildChannelChatMessageItem(BuildContext context, int index) {
    List<ChatMessage> chatMessages = channelChatMessageController.data;
    ChatMessage chatMessage = chatMessages[index];
    Widget chatMessageItem =
        ChannelChatMessageItem(key: UniqueKey(), chatMessage: chatMessage);

    // index=0执行动画，对最新的消息执行动画
    if (index == 0) {
      // 开始动画
      animateController.forward();
      // 大小变化动画组件
      return SizeTransition(
        // 指定非线性动画类型
        sizeFactor:
            CurvedAnimation(parent: animateController, curve: Curves.easeInOut),
        axisAlignment: 0.0,
        // 指定为当前消息组件
        child: chatMessageItem,
      );
    }
    // 不添加动画消息组件
    return chatMessageItem;
  }

  ///创建消息显示面板，包含消息的输入框
  Widget _buildChannelChatMessageWidget(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _onRefresh,
        //notificationPredicate: _notificationPredicate,
        child: ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(8.0),
          reverse: true,
          //消息组件渲染
          itemBuilder: _buildChannelChatMessageItem,
          //消息条目数
          itemCount: channelChatMessageController.data.length,
        ));
  }

  @override
  Widget build(BuildContext context) {
    var channelChatMessageWidget = _buildChannelChatMessageWidget(context);
    List<Widget>? rightWidgets = [
      IconButton(
          onPressed: () async {
            myChannelChatMessageController.clear(notify: false);
            await myChannelChatMessageController.previous(limit: defaultLimit);
            indexWidgetProvider.push('publish_channel');
          },
          icon: const Icon(
            Icons.edit,
            color: Colors.white,
          )),
    ];
    return AppBarView(
        centerTitle: false,
        title: widget.title,
        rightWidgets: rightWidgets,
        child: channelChatMessageWidget);
  }

  @override
  void dispose() {
    channelChatMessageController.removeListener(_update);
    widget.scrollController.removeListener(_onScroll);
    animateController.dispose();
    super.dispose();
  }
}

class ChannelChatMessageItem extends StatelessWidget {
  final ChatMessage chatMessage;

  const ChannelChatMessageItem({super.key, required this.chatMessage});

  ///创建每一条消息
  Future<Widget> _buildChannelChatMessageItem(BuildContext context) async {
    String senderPeerId = chatMessage.senderPeerId!;
    String name = chatMessage.senderName!;
    Widget avatarImage = AppImage.mdAppImage;
    Linkman? linkman = await linkmanService.findCachedOneByPeerId(senderPeerId);
    if (linkman != null && linkman.avatarImage != null) {
      avatarImage = linkman.avatarImage!;
    }
    String title = chatMessage.title!;
    String thumbnail = chatMessage.thumbnail!;
    Widget thumbnailWidget = ImageUtil.buildImageWidget(image: thumbnail);
    Widget chatMessageItem = InkWell(
        onTap: () {
          channelChatMessageController.current = chatMessage;
          indexWidgetProvider.push('channel_message_view');
        },
        child: Column(children: [
          Row(
            children: [
              avatarImage,
              Text(name),
            ],
          ),
          Text(title),
          thumbnailWidget,
        ]));

    return chatMessageItem;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _buildChannelChatMessageItem(context),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          Widget? child = snapshot.data;
          if (child == null) {
            return Container();
          }
          return child;
        });
  }
}
