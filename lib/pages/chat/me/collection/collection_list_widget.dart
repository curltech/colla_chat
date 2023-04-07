import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_chat_message_controller.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

//收藏的页面
class CollectionListWidget extends StatefulWidget with TileDataMixin {
  final Future<void> Function()? onRefresh;
  final Function()? onScrollMax;
  final Function()? onScrollMin;
  final ScrollController scrollController = ScrollController();

  CollectionListWidget(
      {Key? key, this.onRefresh, this.onScrollMax, this.onScrollMin})
      : super(key: key);

  @override
  State createState() => _CollectionListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'collection';

  @override
  IconData get iconData => Icons.collections;

  @override
  String get title => 'Collection';
}

class _CollectionListWidgetState extends State<CollectionListWidget>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  late final AnimationController animateController;

  @override
  void initState() {
    super.initState();
    collectionChatMessageController.addListener(_update);
    var scrollController = widget.scrollController;
    scrollController.addListener(_onScroll);
    animateController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
  }

  _update() {
    setState(() {
      collectionChatMessageController.latest();
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
    collectionChatMessageController.previous(limit: defaultLimit);
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  ///创建每一条消息
  Widget _buildMessageItem(BuildContext context, int index) {
    List<ChatMessage> messages = collectionChatMessageController.data;
    ChatMessage chatMessage = messages[index];
    Widget chatMessageItem = ListTile(title: CommonAutoSizeText(chatMessage.title!));

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
            child: ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              //消息组件渲染
              itemBuilder: _buildMessageItem,
              //消息条目数
              itemCount: collectionChatMessageController.data.length,
            )),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    var chatMessageWidget = _buildChatMessageWidget(context);

    return chatMessageWidget;
  }

  @override
  void dispose() {
    collectionChatMessageController.removeListener(_update);
    widget.scrollController.removeListener(_onScroll);
    animateController.dispose();
    super.dispose();
  }
}
