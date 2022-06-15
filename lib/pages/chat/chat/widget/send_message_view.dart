import 'dart:io';

import 'package:colla_chat/pages/chat/chat/widget/quit_message.dart';
import 'package:colla_chat/pages/chat/chat/widget/red_package.dart';
import 'package:colla_chat/pages/chat/chat/widget/sound_msg.dart';
import 'package:colla_chat/pages/chat/chat/widget/text_msg.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../entity/chat/chat.dart';
import 'Img_msg.dart';
import 'join_message.dart';
import 'modify_groupInfo_message.dart';
import 'modify_notification_message.dart';

class SendMessageView extends StatefulWidget {
  final ChatMessage model;

  SendMessageView(this.model);

  @override
  _SendMessageViewState createState() => _SendMessageViewState();
}

class _SendMessageViewState extends State<SendMessageView> {
  @override
  Widget build(BuildContext context) {
    String msgType = widget.model.messageType;
    String msgStr = widget.model.content;

    bool isI = Platform.isIOS;
    bool iosText = isI && msgStr.contains('text:');
    bool iosImg = isI && msgStr.contains('imageList:');
    var iosS = msgStr.contains('downloadFlag:') && msgStr.contains('second:');
    bool iosSound = isI && iosS;
    if ((msgType == "Text" || iosText) && msgStr.contains("测试发送红包消息")) {
      return RedPackage(widget.model);
    } else if (msgType == "Text" || iosText) {
      return TextMsg(msgStr, widget.model);
    } else if (msgType == "Image" || iosImg) {
      return ImgMsg({}, widget.model);
    } else if (msgType == 'Sound' || iosSound) {
      return SoundMsg(widget.model);
//    } else if (msg.toString().contains('snapshotPath') &&
//        msg.toString().contains('videoPath')) {
//      return VideoMessage(msg, msgType, widget.data);
    } else if (msgType == 'Join') {
      return JoinMessage(widget.model);
    } else if (msgType == 'Quit') {
      return QuitMessage(widget.model);
    } else if (msgType == 'ModifyIntroduction') {
      return ModifyNotificationMessage(widget.model);
    } else if (msgType == 'ModifyName') {
      return ModifyGroupInfoMessage(widget.model);
    } else {
      return new Text('未知消息');
    }
  }
}
