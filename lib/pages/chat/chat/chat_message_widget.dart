import 'dart:async';

import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/chat_message_item.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
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

  ChatMessageWidget({
    super.key,
    this.onScrollMax,
    this.onScrollMin,
    this.onRefresh,
    this.notificationPredicate,
  });

  @override
  State<StatefulWidget> createState() {
    return _ChatMessageWidgetState();
  }
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with TickerProviderStateMixin {
  FocusNode textFocusNode = FocusNode();
  late final AnimationController animateController;
  ValueNotifier<bool> securityTip = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    //不能同时监听chatMessageController和globalChatMessageController
    //因为globalChatMessageController会通知chatMessageController的新消息
    chatMessageController.addListener(_update);
    var scrollController = widget.scrollController;
    scrollController.addListener(_onScroll);
    animateController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    Future.delayed(const Duration(seconds: 30), () {
      securityTip.value = false;
    });
    chatMessageController.latest();

    ///滚到指定的位置
    // widget.scrollController.animateTo(offset,
    //     duration: const Duration(milliseconds: 1000), curve: Curves.ease);
  }

  _update() {
    setState(() {
      int start = DateTime.now().millisecondsSinceEpoch;
      chatMessageController.latest();
      int end = DateTime.now().millisecondsSinceEpoch;
      logger.w('find chat message latest time: ${end - start} microsecond');
    });
  }

  void _onScroll() {
    double offset = widget.scrollController.offset;
    logger.i('scrolled to $offset');

    ///判断是否滚动到最底，需要加载更多数据
    if (widget.scrollController.position.pixels ==
        widget.scrollController.position.maxScrollExtent) {
      logger.i('scrolled to max');
      chatMessageController.previous(limit: defaultLimit);
      if (widget.onScrollMax != null) {
        widget.onScrollMax!();
      }
    }
    if (widget.scrollController.position.pixels ==
        widget.scrollController.position.minScrollExtent) {
      logger.i('scrolled to min');
      chatMessageController.latest(limit: defaultLimit);
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
  Widget _buildChatMessageItem(BuildContext context, int index) {
    ChatMessage chatMessage = chatMessageController.data[index];
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

  ///创建消息显示面板
  Widget _buildChatMessageWidget(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _onRefresh,
        //notificationPredicate: _notificationPredicate,
        child: ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(8.0),
          reverse: true,
          //消息组件渲染
          itemBuilder: _buildChatMessageItem,
          //消息条目数
          itemCount: chatMessageController.data.length,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: securityTip,
        builder: (BuildContext context, bool securityTip, Widget? child) {
          var chatMessageWidget = _buildChatMessageWidget(context);
          if (securityTip) {
            return Column(children: [
              Row(children: [
                const SizedBox(
                  width: 10.0,
                ),
                const Icon(
                  Icons.security,
                  color: Colors.yellow,
                ),
                const SizedBox(
                  width: 10.0,
                ),
                Expanded(
                    child: CommonAutoSizeText(AppLocalizations.t(
                        'This is E2E encrypt communication, nobody can peek your chat content'))),
                IconButton(
                    onPressed: () {
                      this.securityTip.value = false;
                    },
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.yellow,
                    ))
              ]),
              Expanded(child: chatMessageWidget)
            ]);
          }
          return chatMessageWidget;
        });
  }

  @override
  void dispose() {
    chatMessageController.removeListener(_update);
    widget.scrollController.removeListener(_onScroll);
    animateController.dispose();
    super.dispose();
  }
}
