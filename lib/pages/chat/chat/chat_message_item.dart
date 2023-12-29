import 'dart:async';

import 'package:bubble/bubble.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';

/// 每条消息展示组件，我接收的消息展示在左边，我发送的消息展示在右边
class ChatMessageItem extends StatefulWidget {
  final ChatMessage chatMessage;
  final int index;
  late final MessageWidget messageWidget;
  bool isMyself = false;
  bool isPredefine = false;

  ChatMessageItem({
    Key? key,
    required this.chatMessage,
    required this.index,
  }) : super(key: key) {
    messageWidget = MessageWidget(chatMessage, index);
    isMyself = chatMessage.isMyself;
    isPredefine = chatMessage.isPredefine;
    //logger.w('ChatMessageItem() chatMessage id: ${chatMessage.id}');
  }

  @override
  State<StatefulWidget> createState() {
    return _ChatMessageItemState();
  }
}

class _ChatMessageItemState extends State<ChatMessageItem> {
  int leftDeleteTime = 0;
  Timer? timer;

  @override
  initState() {
    super.initState();
    _buildDeleteTimer();
  }

  _buildDeleteTimer() async {
    var deleteTime = widget.chatMessage.deleteTime;
    if (deleteTime == 0) {
      return;
    }
    var readTimeStr = widget.chatMessage.readTime;
    if (StringUtil.isNotEmpty(readTimeStr)) {
      var readTime = DateUtil.toDateTime(readTimeStr!);
      DateTime now = DateTime.now().toUtc();
      Duration duration = now.difference(readTime);
      leftDeleteTime = deleteTime - duration.inSeconds;
      logger.w(
          '_buildDeleteTimer chatMessage id: ${widget.chatMessage.id},  leftDeleteTime:$leftDeleteTime');
      if (leftDeleteTime > 0) {
        //延时删除
        timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          leftDeleteTime--;
          if (leftDeleteTime <= 0) {
            if (this.timer != null) {
              this.timer!.cancel();
              this.timer = null;
              chatMessageService.delete(entity: widget.chatMessage);
              chatMessageController.delete(index: widget.index);
              logger.w(
                  'Timer.periodic delete chatMessage id: ${widget.chatMessage.id}, leftDeleteTime:$leftDeleteTime');
            }
          }
          setState(() {});
        });
      } else {
        chatMessageService.delete(entity: widget.chatMessage);
        chatMessageController.delete(index: widget.index);
        logger.w(
            '_buildDeleteTimer delete chatMessage id: ${widget.chatMessage.id}, leftDeleteTime:$leftDeleteTime');
      }
    }
  }

  ///气泡消息容器，内包消息体
  Widget _buildMessageBubble(BuildContext context) {
    Widget body = FutureBuilder(
      future: widget.messageWidget.buildMessageBody(context),
      builder: (BuildContext context, AsyncSnapshot<Widget?> snapshot) {
        if (snapshot.hasData) {
          Widget? widget = snapshot.data;
          if (widget != null) {
            return widget;
          }
        }
        return Container();
      },
    );
    var crossAxisAlignment = CrossAxisAlignment.start;
    if (widget.isMyself) {
      crossAxisAlignment = CrossAxisAlignment.end;
    }
    double width = appDataProvider.secondaryBodyWidth * 0.8;
    // logger.w('secondaryBodyWidth width:${appDataProvider.secondaryBodyWidth}');
    String transportType = widget.chatMessage.transportType;
    Color borderColor = myself.primary;
    if (transportType == TransportType.websocket.name) {
      borderColor = myself.primaryColor;
    } else if (transportType == TransportType.sfu.name) {
      borderColor = myself.secondary;
    } else if (transportType == TransportType.chatGPT.name) {
      borderColor = Colors.blueAccent;
    }
    List<Widget> children = [
      Bubble(
          elevation: 0.0,
          stick: false,
          margin: const BubbleEdges.only(top: 1),
          nip: widget.isMyself ? BubbleNip.rightTop : BubbleNip.leftTop,
          color: widget.isMyself ? myself.primary : Colors.white,
          borderColor: borderColor,
          borderWidth: 2.0,
          padding: const BubbleEdges.all(0),
          child: body)
    ];
    Widget? parentWidget = MessageWidget.buildParentChatMessageWidget(
        readOnly: true, parentMessageId: widget.chatMessage.parentMessageId);
    if (parentWidget != null) {
      children.add(const SizedBox(
        height: 2,
      ));
      children.add(parentWidget);
    }
    return SizedBox(
        width: width,
        child:
            Column(crossAxisAlignment: crossAxisAlignment, children: children));
  }

  ///矩形消息容器，内包消息体
  Widget _buildMessageContainer(BuildContext context) {
    List<Widget> children = [
      FutureBuilder(
        future: widget.messageWidget.buildMessageBody(context),
        builder: (BuildContext context, AsyncSnapshot<Widget?> snapshot) {
          if (snapshot.hasData) {
            Widget? widget = snapshot.data;
            if (widget != null) {
              return widget;
            }
          }
          return Container();
        },
      )
    ];
    Widget? parentWidget = MessageWidget.buildParentChatMessageWidget(
        readOnly: true, parentMessageId: widget.chatMessage.parentMessageId);
    if (parentWidget != null) {
      children.add(const SizedBox(
        height: 2,
      ));
      children.add(parentWidget);
    }
    double width = appDataProvider.secondaryBodyWidth * 0.8;
    logger.w('secondaryBodyWidth width:${appDataProvider.secondaryBodyWidth}');
    return Row(
      mainAxisAlignment:
          widget.isMyself ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            width: width,
            decoration: BoxDecoration(
              color: widget.isMyself ? myself.primary : Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(8.0),
                bottomRight: const Radius.circular(8.0),
                topLeft:
                    widget.isMyself ? const Radius.circular(8.0) : Radius.zero,
                topRight:
                    widget.isMyself ? Radius.zero : const Radius.circular(8.0),
              ),
              //border: Border.all(color: Colors.white, width: 0.0),
            ),
            margin: EdgeInsets.only(
                right: widget.isMyself ? 5.0 : 0,
                left: widget.isMyself ? 0 : 5.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end, children: children))
      ], // aligns the chatitem to right end
    );
  }

  ///系统消息，显示在中间的消息容器
  Widget _buildPredefine(BuildContext context) {
    var sendTime = widget.chatMessage.sendTime;
    sendTime = sendTime = DateUtil.formatEasyRead(sendTime!);
    //${widget.chatMessage.id}:${widget.chatMessage.senderName}
    Widget title =
        CommonAutoSizeText(sendTime, style: const TextStyle(fontSize: 12));
    // CommonAutoSizeText('${widget.chatMessage.id}:${widget.chatMessage.senderName}');
    if (timer != null) {
      title = Row(
        children: [
          title,
          const Icon(Icons.timer_sharp),
          CommonAutoSizeText('$leftDeleteTime'),
        ],
      );
    }
    Widget body = FutureBuilder(
      future: widget.messageWidget.buildMessageBody(context),
      builder: (BuildContext context, AsyncSnapshot<Widget?> snapshot) {
        if (snapshot.hasData) {
          Widget? widget = snapshot.data;
          if (widget != null) {
            return widget;
          }
        }
        return Container();
      },
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      child: Center(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
            title,
            const SizedBox(
              width: 10,
            ),
            body,
          ])),
    );
  }

  ///其他人的消息，从左到右，头像，时间，名称，消息容器
  Widget _buildOther(BuildContext context) {
    var sendTime = widget.chatMessage.sendTime;
    sendTime = sendTime = DateUtil.formatEasyRead(sendTime!);
    int? id = widget.chatMessage.id;
    Widget title =
        CommonAutoSizeText(sendTime, style: const TextStyle(fontSize: 12));
    // CommonAutoSizeText('${widget.chatMessage.id}:${widget.chatMessage.senderName}');
    if (timer != null) {
      title = Row(
        children: [
          title,
          const Icon(Icons.timer_sharp),
          CommonAutoSizeText('$leftDeleteTime'),
        ],
      );
    }
    List<Widget> children = [title, _buildMessageBubble(context)];
    Widget? parentWidget = MessageWidget.buildParentChatMessageWidget(
        readOnly: true, parentMessageId: widget.chatMessage.parentMessageId);
    if (parentWidget != null) {
      children.add(const SizedBox(
        height: 2,
      ));
      children.add(parentWidget);
    }
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  margin: const EdgeInsets.only(right: 0.0),
                  child: FutureBuilder(
                    future: _getImageWidget(context),
                    builder: (BuildContext context,
                        AsyncSnapshot<Widget?> snapshot) {
                      Widget widget = snapshot.data ?? Container();
                      return widget;
                    },
                  )),
              const SizedBox(
                width: 5,
              ),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children),
            ]));
  }

  ///我的消息，从右到左，头像，时间，名称，消息容器
  Widget _buildMe(BuildContext context) {
    var sendTime = widget.chatMessage.sendTime;
    sendTime = sendTime = DateUtil.formatEasyRead(sendTime!);
    int? id = widget.chatMessage.id;
    Widget title =
        CommonAutoSizeText(sendTime, style: const TextStyle(fontSize: 12));
    if (timer != null) {
      title = Row(
        children: [
          title,
          const Icon(Icons.timer_sharp),
          CommonAutoSizeText('$leftDeleteTime'),
        ],
      );
    }
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Container(),
              ),
              Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    title,
                    _buildMessageBubble(context),
                  ]),
              const SizedBox(
                width: 5,
              ),
              Container(
                  margin: const EdgeInsets.only(left: 0.0),
                  child: FutureBuilder(
                    future: _getImageWidget(context),
                    builder: (BuildContext context,
                        AsyncSnapshot<Widget?> snapshot) {
                      Widget widget = snapshot.data ?? Container();
                      return widget;
                    },
                  ))
            ]));
  }

  Future<Widget?> _getImageWidget(BuildContext context) async {
    var direct = widget.chatMessage.direct;
    var senderPeerId = widget.chatMessage.senderPeerId;
    var peerId = myself.peerId;
    if (direct == ChatDirect.send.name &&
        (senderPeerId == null || senderPeerId == peerId)) {
      Widget avatarImage = myself.avatarImage ?? AppImage.mdAppImage;
      return InkWell(
          onTap: () {
            indexWidgetProvider.push('personal_info');
          },
          child: avatarImage);
    }
    if (senderPeerId != null) {
      var linkman = await linkmanService.findCachedOneByPeerId(senderPeerId);
      if (linkman != null) {
        Widget avatarImage = linkman.avatarImage ?? AppImage.mdAppImage;
        return InkWell(
            onTap: () {
              linkmanController.replaceAll([linkman]);
              indexWidgetProvider.push('linkman_info');
            },
            child: avatarImage);
      }
    }

    return AppImage.mdAppImage;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPredefine) {
      return _buildPredefine(context);
    }
    if (widget.isMyself) {
      return _buildMe(context);
    }
    return _buildOther(context);
  }

  @override
  void dispose() {
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }
    super.dispose();
  }
}
