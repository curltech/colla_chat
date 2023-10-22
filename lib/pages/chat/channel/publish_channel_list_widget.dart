import 'dart:async';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/datastore/datastore.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/channel/channel_chat_message_controller.dart';
import 'package:colla_chat/pages/chat/channel/publish_channel_edit_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/document_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

//频道的页面,展示自己发布的频道消息列表
class PublishChannelListWidget extends StatefulWidget with TileDataMixin {
  final Future<void> Function()? onRefresh;
  final Function()? onScrollMax;
  final Function()? onScrollMin;
  final ScrollController scrollController = ScrollController();
  final PublishChannelEditWidget publishChannelEditWidget =
      PublishChannelEditWidget();

  PublishChannelListWidget({
    Key? key,
    this.onRefresh,
    this.onScrollMax,
    this.onScrollMin,
  }) : super(key: key) {
    indexWidgetProvider.define(publishChannelEditWidget);
  }

  @override
  State createState() => _PublishChannelListWidgetState();

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'publish_channel';

  @override
  IconData get iconData => Icons.my_library_add;

  @override
  String get title => 'Publish channel';
}

class _PublishChannelListWidgetState extends State<PublishChannelListWidget>
    with TickerProviderStateMixin {
  late final AnimationController animateController;

  @override
  void initState() {
    super.initState();
    myChannelChatMessageController.addListener(_update);
    var scrollController = widget.scrollController;
    scrollController.addListener(_onScroll);
    animateController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    myChannelChatMessageController.latest();
  }

  _update() {
    setState(() {
      myChannelChatMessageController.latest();
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

  ///将编辑的内容正式发布，统一采用html格式保存和发送，原先保存的草案要转换格式，更新状态
  _publish(ChatMessage chatMessage) async {
    String? mimeType = chatMessage.mimeType;
    if (mimeType == ChatMessageMimeType.json.name) {
      var bytes = await messageAttachmentService.findContent(
          chatMessage.messageId!, chatMessage.title!);
      if (bytes != null) {
        String json = CryptoUtil.utf8ToString(bytes);
        var deltaJson = JsonUtil.toJson(json);
        var html = DocumentUtil.jsonToHtml(deltaJson);
        chatMessage.mimeType = ChatMessageMimeType.html.name;
        chatMessage.content = chatMessageService.processContent(html);
      }
      chatMessage.status = MessageStatus.published.name;
      chatMessage.sendTime = DateUtil.currentDate();
      await chatMessageService.store(chatMessage);
    } else if (mimeType == ChatMessageMimeType.html.name) {
      await myChannelChatMessageController.publish(chatMessage.messageId!);
    }

    if (mounted) {
      DialogUtil.info(context,
          content: AppLocalizations.t('Publish document successfully'));
    }
  }

  ///展示每一条消息
  Widget _buildChannelChatMessageItem(BuildContext context, int index) {
    List<ChatMessage> chatMessages = myChannelChatMessageController.data;
    ChatMessage chatMessage = chatMessages[index];
    String title = chatMessage.title!;
    String? thumbnail = chatMessage.thumbnail;
    Widget? thumbnailWidget;
    if (thumbnail != null) {
      thumbnailWidget = ImageUtil.buildImageWidget(
          image: thumbnail,
          height: AppImageSize.mdSize,
          width: AppImageSize.mdSize);
    }
    var sendTime = DateUtil.formatEasyRead(chatMessage.sendTime!);
    var status = chatMessage.status;
    Widget leading = const Icon(
      Icons.unpublished,
      // color: myself.primary,
    );
    if (MessageStatus.published.name == status) {
      leading = const Icon(
        Icons.check_circle,
        // color: myself.primary,
      );
    }
    Widget chatMessageItem = ListTile(
      onTap: () {
        myChannelChatMessageController.current = chatMessage;
        if (chatMessage.status == MessageStatus.draft.name) {
          indexWidgetProvider.push('publish_channel_edit');
        }
        if (chatMessage.status == MessageStatus.published.name) {
          indexWidgetProvider.push('published_channel_message_preview');
        }
      },
      title: CommonAutoSizeText(title),
      subtitle: CommonAutoSizeText(sendTime),
      leading: leading,
      trailing: thumbnailWidget,
    );

    ActionPane actionPane = ActionPane(
      extentRatio: 0.6,
      motion: const DrawerMotion(),
      children: <SlidableAction>[
        SlidableAction(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0),
          onPressed: (context) async {
            bool? confirm = await DialogUtil.confirm(context,
                content: 'Do you confirm publish?');
            if (confirm != null && confirm) {
              _publish(chatMessage);
              setState(() {});
            }
          },
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          icon: Icons.publish,
          label: AppLocalizations.t('Publish'),
          borderRadius: BorderRadius.circular(0),
        ),
        SlidableAction(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0),
          onPressed: (context) async {
            bool? confirm = await DialogUtil.confirm(context,
                content: 'Do you confirm delete?');
            if (confirm != null && confirm) {
              await chatMessageService
                  .remove(where: 'id=?', whereArgs: [chatMessage.id!]);
              myChannelChatMessageController.delete(index: index);
            }
          },
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          icon: Icons.delete_outline,
          label: AppLocalizations.t('Delete'),
          borderRadius: BorderRadius.circular(0),
        ),
      ],
    );

    chatMessageItem = Slidable(
      key: UniqueKey(),
      startActionPane: actionPane,
      child: chatMessageItem,
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

  ///创建消息显示面板，包含消息的输入框
  Widget _buildChannelChatMessageWidget(BuildContext context) {
    return RefreshIndicator(
        onRefresh: _onRefresh,
        //notificationPredicate: _notificationPredicate,
        child: ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(8.0),
          reverse: false,
          //消息组件渲染
          itemBuilder: _buildChannelChatMessageItem,
          //消息条目数
          itemCount: myChannelChatMessageController.data.length,
        ));
  }

  @override
  Widget build(BuildContext context) {
    var channelChatMessageWidget = _buildChannelChatMessageWidget(context);
    List<Widget>? rightWidgets = [
      IconButton(
        onPressed: () {
          myChannelChatMessageController.current = null;
          indexWidgetProvider.push('publish_channel_edit');
        },
        icon: const Icon(
          Icons.note_add,
          color: Colors.white,
        ),
        tooltip: AppLocalizations.t('Add document'),
        // labelColor: Colors.white,
      ),
      const SizedBox(
        width: 10,
      ),
    ];
    return AppBarView(
        centerTitle: false,
        withLeading: true,
        title: widget.title,
        rightWidgets: rightWidgets,
        child: channelChatMessageWidget);
  }

  @override
  void dispose() {
    myChannelChatMessageController.removeListener(_update);
    widget.scrollController.removeListener(_onScroll);
    animateController.dispose();
    super.dispose();
  }
}
