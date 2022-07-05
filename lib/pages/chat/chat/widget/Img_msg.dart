import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:flutter/material.dart';

import '../../../../entity/chat/chat.dart';
import '../../../../tool/util.dart';
import 'msg_avatar.dart';

///图片消息显示组件，与text消息组件类似
class ImgMsg extends StatelessWidget {
  final msg;

  final ChatMessage model;

  ImgMsg(this.msg, this.model);

  @override
  Widget build(BuildContext context) {
    if (!CollectUtil.listNoEmpty(msg['imageList'])) return Text('发送中');
    var msgInfo = msg['imageList'][1];
    var _height = msgInfo['height'].toDouble();
    var resultH = _height > 200.0 ? 200.0 : _height;
    var url = msgInfo['url'];
    var isFile = File(url).existsSync();
    var body = [
      MsgAvatar(model: model),
      Spacer(),
      Expanded(
        child: GestureDetector(
          child: Container(
            padding: EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              child: isFile
                  ? Image.file(File(url))
                  : CachedNetworkImage(
                      imageUrl: url, height: resultH, fit: BoxFit.cover),
            ),
          ),
          onTap: () {
            // routePush(
            //   PhotoView(
            //     imageProvider:
            //         isFile ? FileImage(File(url)) : NetworkImage(url),
            //     onTapUp: (c, f, s) => Navigator.of(context).pop(),
            //     maxScale: 3.0,
            //     minScale: 1.0,
            //   ),
            // );
          },
        ),
      ),
      Spacer(),
    ];
    if (model.receiverPeerId != myself.peerId) {
      body = body.reversed.toList();
    } else {
      body = body;
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: Row(children: body),
    );
  }
}
