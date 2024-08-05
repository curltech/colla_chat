import 'dart:async';

import 'package:bubble/bubble.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/chat/message/message_widget.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_list_widget.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/date_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 每条消息展示组件，我接收的消息展示在左边，我发送的消息展示在右边
class ChatMessageItem extends StatelessWidget {
  final ChatMessage chatMessage;
  final int index;
  late final MessageWidget messageWidget;
  bool isMyself = false;
  bool isPredefine = false;

  ChatMessageItem({
    super.key,
    required this.chatMessage,
    required this.index,
  }) {
    messageWidget = MessageWidget(chatMessage, index);
    isMyself = chatMessage.isMyself;
    isPredefine = chatMessage.isPredefine;
    //logger.w('ChatMessageItem() chatMessage id: ${chatMessage.id}');
    _buildDeleteTimer();
  }

  RxInt leftDeleteTime = 0.obs;
  Timer? timer;

  _buildDeleteTimer() async {
    var deleteTime = chatMessage.deleteTime;
    if (deleteTime == 0) {
      return;
    }
    var readTimeStr = chatMessage.readTime;
    if (StringUtil.isNotEmpty(readTimeStr)) {
      var readTime = DateUtil.toDateTime(readTimeStr!);
      DateTime now = DateTime.now().toUtc();
      Duration duration = now.difference(readTime);
      leftDeleteTime.value = deleteTime - duration.inSeconds;
      logger.w(
          '_buildDeleteTimer chatMessage id: ${chatMessage.id},  leftDeleteTime:$leftDeleteTime');
      if (leftDeleteTime > 0) {
        //延时删除
        timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          leftDeleteTime--;
          if (leftDeleteTime <= 0) {
            if (this.timer != null) {
              this.timer!.cancel();
              this.timer = null;
              chatMessageService.delete(entity: chatMessage);
              chatMessageController.delete(index: index);
              logger.w(
                  'Timer.periodic delete chatMessage id: ${chatMessage.id}, leftDeleteTime:$leftDeleteTime');
            }
          }
        });
      } else {
        chatMessageService.delete(entity: chatMessage);
        chatMessageController.delete(index: index);
        logger.w(
            '_buildDeleteTimer delete chatMessage id: ${chatMessage.id}, leftDeleteTime:$leftDeleteTime');
      }
    }
  }

  ///气泡消息容器，内包消息体
  Widget _buildMessageBubble(BuildContext context) {
    Widget body = PlatformFutureBuilder(
      loadingWidget: Container(),
      future: messageWidget.buildMessageBody(context),
      builder: (BuildContext context, Widget child) {
        return child;
      },
    );
    var crossAxisAlignment = CrossAxisAlignment.start;
    if (isMyself) {
      crossAxisAlignment = CrossAxisAlignment.end;
    }
    double width = appDataProvider.secondaryBodyWidth * 0.8;
    logger.w('secondaryBodyWidth width:${appDataProvider.secondaryBodyWidth}');

    String transportType = chatMessage.transportType;
    Color borderColor = isMyself ? myself.primary : Colors.white;
    if (chatMessage.status == MessageStatus.unsent.name) {
      borderColor = Colors.redAccent;
    } else if (transportType == TransportType.websocket.name) {
      borderColor = Colors.cyanAccent;
    } else if (transportType == TransportType.sfu.name) {
      borderColor = Colors.greenAccent;
    } else if (transportType == TransportType.llm.name) {
      borderColor = Colors.blueAccent;
    }
    List<Widget> children = [
      Bubble(
          elevation: 0.0,
          stick: false,
          margin: const BubbleEdges.only(top: 1),
          nip: isMyself ? BubbleNip.rightTop : BubbleNip.leftTop,
          nipOffset: 0.0,
          color: isMyself ? myself.primary : Colors.white,
          borderColor: borderColor,
          borderWidth: 1.0,
          padding: const BubbleEdges.all(0),
          child: body)
    ];
    Widget? parentWidget = MessageWidget.buildParentChatMessageWidget(
        readOnly: true, parentMessageId: chatMessage.parentMessageId);
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
      PlatformFutureBuilder(
        future: messageWidget.buildMessageBody(context),
        builder: (BuildContext context, Widget child) {
          return child;
        },
      )
    ];
    Widget? parentWidget = MessageWidget.buildParentChatMessageWidget(
        readOnly: true, parentMessageId: chatMessage.parentMessageId);
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
          isMyself ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            width: width,
            decoration: BoxDecoration(
              color: isMyself ? myself.primary : Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: const Radius.circular(8.0),
                bottomRight: const Radius.circular(8.0),
                topLeft: isMyself ? const Radius.circular(8.0) : Radius.zero,
                topRight: isMyself ? Radius.zero : const Radius.circular(8.0),
              ),
              //border: Border.all(color: Colors.white, width: 0.0),
            ),
            margin: EdgeInsets.only(
                right: isMyself ? 5.0 : 0, left: isMyself ? 0 : 5.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end, children: children))
      ], // aligns the chatitem to right end
    );
  }

  ///系统消息，显示在中间的消息容器
  Widget _buildPredefine(BuildContext context) {
    var sendTime = chatMessage.sendTime;
    sendTime = sendTime = DateUtil.formatEasyRead(sendTime!);
    //${chatMessage.id}:${chatMessage.senderName}
    Widget title =
        CommonAutoSizeText(sendTime, style: const TextStyle(fontSize: 12));
    // CommonAutoSizeText('${chatMessage.id}:${chatMessage.senderName}');
    if (timer != null) {
      title = Row(
        children: [
          title,
          const Icon(Icons.timer_sharp),
          Obx(() => CommonAutoSizeText('$leftDeleteTime')),
        ],
      );
    }
    Widget body = PlatformFutureBuilder(
      future: messageWidget.buildMessageBody(context),
      builder: (BuildContext context, Widget child) {
        return child;
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
    String? sendTime = chatMessage.sendTime;
    sendTime = DateUtil.formatEasyRead(sendTime!);
    if (myself.peerProfile.developerSwitch) {
      int? id = chatMessage.id;
      sendTime = '$id:$sendTime';
    }
    Widget title =
        CommonAutoSizeText(sendTime, style: const TextStyle(fontSize: 12));
    if (timer != null) {
      title = Row(
        children: [
          title,
          const Icon(Icons.timer_sharp),
          Obx(() => CommonAutoSizeText('$leftDeleteTime')),
        ],
      );
    }
    List<Widget> children = [title, _buildMessageBubble(context)];
    Widget? parentWidget = MessageWidget.buildParentChatMessageWidget(
        readOnly: true, parentMessageId: chatMessage.parentMessageId);
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
                  child: PlatformFutureBuilder(
                    future: _getImageWidget(context),
                    builder: (BuildContext context, Widget? child) {
                      return child!;
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
    String? sendTime = chatMessage.sendTime;
    sendTime = DateUtil.formatEasyRead(sendTime!);
    if (myself.peerProfile.developerSwitch) {
      int? id = chatMessage.id;
      sendTime = '$id:$sendTime';
    }
    Widget title =
        CommonAutoSizeText(sendTime, style: const TextStyle(fontSize: 12));
    if (timer != null) {
      title = Row(
        children: [
          title,
          const Icon(Icons.timer_sharp),
          Obx(() => CommonAutoSizeText('$leftDeleteTime')),
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
                  child: PlatformFutureBuilder(
                    future: _getImageWidget(context),
                    builder: (BuildContext context, Widget? child) {
                      return child!;
                    },
                  ))
            ]));
  }

  Future<Widget?> _getImageWidget(BuildContext context) async {
    var direct = chatMessage.direct;
    var senderPeerId = chatMessage.senderPeerId;
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
    if (isPredefine) {
      return _buildPredefine(context);
    }
    if (isMyself) {
      return _buildMe(context);
    }
    return _buildOther(context);
  }

  void dispose() {
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }
  }
}
