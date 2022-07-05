import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/pages/chat/chat/widget/red_receive_dialog.dart';
import 'package:colla_chat/pages/chat/chat/widget/ui.dart';
import 'package:flutter/material.dart';

import '../../../../entity/dht/myself.dart';
import 'msg_avatar.dart';

class RedPackage extends StatelessWidget {
  final ChatMessage model;

  RedPackage(this.model);

  @override
  Widget build(BuildContext context) {
    var body = [
      MsgAvatar(model: model),
      Spacer(),
      InkWell(
        child: Container(
          padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 3),
          decoration: BoxDecoration(
            color: Color(0xffe3a353),
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
          ),
          child: Column(
            crossAxisAlignment: model.receiverPeerId != myself.peerId
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: Colors.white.withOpacity(0.5), width: 0.2),
                  ),
                ),
                padding: EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Image.asset('assets/images/wechat/c2c_hongbao_icon_hk.png',
                        width: 30),
                    Spacer(),
                    Text(
                      '恭喜发财，大吉大利',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
              HorizontalLine(color: Colors.white, height: 1),
              Text(
                '微信红包',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 8),
              )
            ],
          ),
        ),
        onTap: () {
          redReceiveDialog(context);
        },
      ),
    ];
    if (model.receiverPeerId != myself.peerId) {
      body = body.reversed.toList();
    } else {
      body = body;
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: model.receiverPeerId != myself.peerId
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: body,
      ),
    );
  }
}
