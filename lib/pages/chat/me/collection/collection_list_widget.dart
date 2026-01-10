import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/me/collection/collection_item_widget.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

//收藏的清单组件
class CollectionListWidget extends StatefulWidget {
  final Future<void> Function()? onRefresh;
  final Function()? onScrollMax;
  final Function()? onScrollMin;
  final ScrollController scrollController = ScrollController();
  final CollectionItemWidget collectionItemWidget = CollectionItemWidget();

  CollectionListWidget(
      {super.key, this.onRefresh, this.onScrollMax, this.onScrollMin}) {
    indexWidgetProvider.define(collectionItemWidget);
  }

  @override
  State createState() => _CollectionListWidgetState();
}

class _CollectionListWidgetState extends State<CollectionListWidget>
    with TickerProviderStateMixin {
  late final AnimationController animateController;

  @override
  void initState() {
    super.initState();
    var scrollController = widget.scrollController;
    scrollController.addListener(_onScroll);
    animateController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    collectionChatMessageController.latest();
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

  String _buildSubtitle(
      {required String subMessageType, String? contentType, String? content}) {
    String subtitle = '';
    if (subMessageType == ChatMessageSubType.chat.name) {
      content = content ?? '';
      if (contentType == null ||
          contentType == ChatMessageContentType.text.name) {
        subtitle = chatMessageService.recoverContent(content);
      }
      if (contentType == ChatMessageContentType.location.name) {
        subtitle = chatMessageService.recoverContent(content);
        Map<String, dynamic> map = JsonUtil.toJson(subtitle);
        String? address = map['address'];
        address = address ?? '';
        subtitle = address;
      }
    } else {
      subtitle = AppLocalizations.t(subMessageType);
    }
    return subtitle;
  }

  TileData _buildCollectionTileData(ChatMessage chatMessage) {
    var id = chatMessage.id;
    var senderPeerId = chatMessage.senderPeerId ?? '';
    var senderName = chatMessage.senderName ?? '';
    var title = chatMessage.title ?? senderName;
    var subMessageType = chatMessage.subMessageType;
    var sendTime = chatMessage.sendTime;
    if (sendTime != null) {
      sendTime = DateUtil.formatEasyRead(sendTime);
    } else {
      sendTime = '';
    }
    var subtitle = _buildSubtitle(
        subMessageType: subMessageType ?? '',
        contentType: chatMessage.contentType,
        content: chatMessage.content);

    TileData tile = TileData(
        title: title,
        titleTail: sendTime,
        subtitle: subtitle,
        dense: true,
        selected: false,
        isThreeLine: false,
        routeName: 'collection_item');
    List<TileData> slideActions = [];
    TileData deleteSlideAction = TileData(
        title: 'Delete',
        prefix: Icons.bookmark_remove,
        onTap: (int index, String label, {String? subtitle}) async {
          await chatMessageService.remove(chatMessage);
          collectionChatMessageController.delete();
        });
    slideActions.add(deleteSlideAction);
    tile.slideActions = slideActions;
    return tile;
  }

  void _onTapCollection(int index, String title,
      {String? subtitle, TileData? group}) {
    collectionChatMessageController.setCurrentIndex = index;
  }

  ///创建每一条收藏消息
  Widget _buildCollectionItem(BuildContext context, int index) {
    List<ChatMessage> messages = collectionChatMessageController.data;
    ChatMessage chatMessage = messages[index];
    Widget chatMessageItem = DataListTile(
      index: index,
      tileData: _buildCollectionTileData(chatMessage),
      onTap: _onTapCollection,
    );

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

  ///创建收藏信息的列表
  Widget _buildCollectionWidget(BuildContext context) {
    return Obx(() {
      return Column(children: <Widget>[
        Flexible(
          //使用列表渲染消息
          child: RefreshIndicator(
              onRefresh: _onRefresh,
              //notificationPredicate: _notificationPredicate,
              child: ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(8.0),
                reverse: false,
                //消息组件渲染
                itemBuilder: _buildCollectionItem,
                //消息条目数
                itemCount: collectionChatMessageController.length,
              )),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    collectionChatMessageController.latest();
    var collectionWidget = _buildCollectionWidget(context);

    return collectionWidget;
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    animateController.dispose();
    super.dispose();
  }
}
