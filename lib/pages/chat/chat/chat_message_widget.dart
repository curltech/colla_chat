import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/pages/chat/chat/text_message_input.dart';
import 'package:colla_chat/service/chat/chat.dart';
import 'package:flutter/material.dart';

import '../../../entity/chat/chat.dart';
import '../../../l10n/localization.dart';
import '../../../provider/app_data_provider.dart';
import '../../../provider/data_list_controller.dart';
import '../../../tool/util.dart';
import '../../../transport/webrtc/peer_connection_pool.dart';
import '../../../widgets/common/app_bar_view.dart';
import '../../../widgets/common/widget_mixin.dart';
import '../me/webrtc/peer_connection_controller.dart';
import 'chat_message_input.dart';
import 'chat_message_item.dart';

///好友或者群的消息控制器
class ChatMessageController extends DataMoreController<ChatMessage> {
  ChatSummary? _chatSummary;

  ChatSummary? get chatSummary {
    return _chatSummary;
  }

  set chatSummary(ChatSummary? chatSummary) {
    _chatSummary = chatSummary;
    clear();
    previous(limit: defaultLimit);
  }

  ///访问数据库获取更老的消息
  @override
  Future<void> previous({int? limit}) async {
    var chatSummary = _chatSummary;
    if (chatSummary == null) {
      clear();
      return;
    }
    if (chatSummary.peerId == null) {
      clear();
      return;
    }
    List<ChatMessage> chatMessages = await chatMessageService
        .findByPeerId(_chatSummary!.peerId!, offset: data.length, limit: limit);
    if (chatMessages.isNotEmpty) {
      addAll(chatMessages);
    }
  }

  ///访问数据库获取最新的消息
  @override
  Future<void> latest({int? limit}) async {
    var chatSummary = _chatSummary;
    if (chatSummary == null) {
      clear();
      return;
    }
    if (chatSummary.peerId == null) {
      clear();
      return;
    }
    int? id;
    if (data.isNotEmpty) {
      id = data[0].id;
    }
    List<ChatMessage> chatMessages = await chatMessageService
        .findByGreaterId(_chatSummary!.peerId!, id: id, limit: limit);
    if (chatMessages.isNotEmpty) {
      data.insertAll(0, chatMessages);
      notifyListeners();
    }
  }
}

/// 消息发送和接受展示的界面组件
/// 此界面展示特定的目标对象的收到的消息，并且可以发送消息
class ChatMessageWidget extends StatefulWidget with TileDataMixin {
  final ChatMessageController chatMessageController = ChatMessageController();
  final ScrollController scrollController = ScrollController();
  final Function()? onScrollMax;
  final Function()? onScrollMin;
  final Future<void> Function()? onRefresh;
  final bool Function(ScrollNotification scrollNotification)?
      notificationPredicate;

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

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'chat_message';

  @override
  Icon get icon => const Icon(Icons.chat);

  @override
  String get title => 'ChatMessage';
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with TickerProviderStateMixin {
  ///扩展文本输入框的控制器
  final TextEditingController textEditingController = TextEditingController();
  FocusNode textFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.chatMessageController.addListener(_update);
    peerConnectionPoolController.addListener(_update);
    var scrollController = widget.scrollController;
    scrollController.addListener(_onScroll);
    var peerId = widget.chatMessageController.chatSummary!.peerId!;
    var peerConnection = peerConnectionPool.getOne(peerId);
    if (peerConnection == null) {
      peerConnectionPool.create(peerId);
    }

    ///滚到指定的位置
    // widget.scrollController.animateTo(offset,
    //     duration: const Duration(milliseconds: 1000), curve: Curves.ease);
  }

  _update() {
    setState(() {});
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
    widget.chatMessageController.previous(limit: defaultLimit);
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

  ///发送命令
  Future<void> send(String message) async {
    if (message.isEmpty || message == '') {
      return;
    }
    var peerId = widget.chatMessageController.chatSummary!.peerId!;
    List<int> data = CryptoUtil.stringToUtf8(message);
    ChatMessage chatMessage =
        await chatMessageService.buildChatMessage(peerId, data);
    widget.chatMessageController.insert(0, chatMessage);
    String json = JsonUtil.toJsonString(chatMessage);
    data = CryptoUtil.stringToUtf8(json);
    await peerConnectionPool.send(peerId, Uint8List.fromList(data));
  }

  bool _hasValue() {
    var value = textEditingController.value.text;
    return StringUtil.isNotEmpty(value);
  }

  ///发送消息的输入框和按钮，三个按钮，一个输入框，单独一个类
  ///另外还有各种消息的选择菜单，emoji各一个类
  Widget _buildTextMessageInputWidget(BuildContext context) {
    return ChatMessageInputWidget(
      textEditingController: textEditingController,
      onSend: send,
    );
  }

  ///创建每一条消息
  Widget messageItem(BuildContext context, int index) {
    List<ChatMessage> messages = widget.chatMessageController.data;
    ChatMessage item = messages[index];
    // 创建消息动画控制器
    var animate = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    Widget chatMessageItem = ChatMessageItem(chatMessage: item);

    // index=0执行动画，对最新的消息执行动画
    if (index == 0) {
      // 开始动画
      animate.forward();
      // 大小变化动画组件
      return SizeTransition(
        // 指定非线性动画类型
        sizeFactor: CurvedAnimation(parent: animate, curve: Curves.easeInOut),
        axisAlignment: 0.0,
        // 指定为当前消息组件
        child: chatMessageItem,
      );
    }
    // 不添加动画消息组件
    return chatMessageItem;
  }

  ///创建消息显示面板，包含消息的输入框
  Widget _buildListView(BuildContext context) {
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
              itemBuilder: messageItem,
              //消息条目数
              itemCount: widget.chatMessageController.data.length,
            )),
      ),
      const Divider(
        height: 1.0,
      ),
      _buildTextMessageInputWidget(context),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    ///获取最新的消息
    widget.chatMessageController.latest();
    String name = widget.chatMessageController.chatSummary!.name!;
    var appBarView = AppBarView(
        title: Text(AppLocalizations.t(name)),
        withLeading: widget.withLeading,
        child: _buildListView(context));
    return appBarView;
  }

  @override
  void dispose() {
    widget.chatMessageController.removeListener(_update);
    widget.scrollController.removeListener(_onScroll);
    peerConnectionPoolController.removeListener(_update);
    textEditingController.dispose();
    super.dispose();
  }
}
