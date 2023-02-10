import 'dart:async';

import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_input.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_item.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/keep_alive_wrapper.dart';
import 'package:flutter/material.dart';

/// 消息发送和接受展示的界面组件
/// 此界面展示特定的目标对象的收到的消息，并且可以发送消息
/// 如果目标有多个clientId的时候，对应多个peerconnection
class ChatMessageWidget extends StatefulWidget {
  final ScrollController scrollController = ScrollController();
  final Function()? onScrollMax;
  final Function()? onScrollMin;
  final Future<void> Function()? onRefresh;
  final bool Function(ScrollNotification scrollNotification)?
      notificationPredicate;
  final chatMessageInputWidget = ChatMessageInputWidget();

  ChatMessageWidget(
      {Key? key,
      this.onScrollMax,
      this.onScrollMin,
      this.onRefresh,
      this.notificationPredicate})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ChatMessageWidgetState();
  }
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with TickerProviderStateMixin {
  FocusNode textFocusNode = FocusNode();
  late final AnimationController animateController;
  final ValueNotifier<List<ChatMessage>> _chatMessages =
      ValueNotifier<List<ChatMessage>>(chatMessageController.data);

  @override
  void initState() {
    super.initState();
    chatMessageController.addListener(_updateChatMessage);
    var scrollController = widget.scrollController;
    scrollController.addListener(_onScroll);
    animateController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    ///滚到指定的位置
    // widget.scrollController.animateTo(offset,
    //     duration: const Duration(milliseconds: 1000), curve: Curves.ease);
  }

  _updateChatMessage() {
    _chatMessages.value = chatMessageController.data;
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
    chatMessageController.previous(limit: defaultLimit);
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  bool _notificationPredicate(ScrollNotification scrollNotification) {
    ///下拉刷新数据的地方，比如从数据库取更多数据
    //logger.i('RefreshIndicator notificationPredicate');
    if (widget.notificationPredicate != null) {
      return widget.notificationPredicate!(scrollNotification);
    }
    return scrollNotification.depth == 0;
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
  Widget _buildMessageItem(BuildContext context, int index) {
    ChatMessage chatMessage = _chatMessages.value[index];
    Widget chatMessageItem = ChatMessageItem(
        key: UniqueKey(), chatMessage: chatMessage, index: index);

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
  Widget _buildChatMessageWidget(BuildContext context) {
    return Column(children: <Widget>[
      Flexible(
        //使用列表渲染消息
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          //notificationPredicate: _notificationPredicate,
          child: ValueListenableBuilder(
              valueListenable: _chatMessages,
              builder: (context, value, child) {
                return ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(8.0),
                  reverse: true,
                  //消息组件渲染
                  itemBuilder: _buildMessageItem,
                  //消息条目数
                  itemCount: _chatMessages.value.length,
                );
              }),
        ),
      ),
      const Divider(
        height: 1.0,
      ),
      widget.chatMessageInputWidget,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    var chatMessageWidget =
        KeepAliveWrapper(child: _buildChatMessageWidget(context));

    return chatMessageWidget;
  }

  @override
  void dispose() {
    chatMessageController.removeListener(_updateChatMessage);
    widget.scrollController.removeListener(_onScroll);
    animateController.dispose();
    super.dispose();
  }
}
