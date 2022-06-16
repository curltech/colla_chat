import 'package:colla_chat/entity/dht/myself.dart';
import 'package:flutter/material.dart';

class QuitMessage extends StatelessWidget {
  final dynamic data;

  QuitMessage(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(vertical: 5.0),
      child: Text(
        '${data['opGroupMemberInfo']['user'] == myself.peerId ? '你' : data['opGroupMemberInfo']['user']}' +
            ' 退出了群聊',
        style:
            TextStyle(color: Color.fromRGBO(108, 108, 108, 0.8), fontSize: 11),
      ),
    );
  }
}
