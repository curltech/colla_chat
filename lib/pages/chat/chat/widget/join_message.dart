import 'package:colla_chat/entity/dht/myself.dart';
import 'package:flutter/material.dart';

class JoinMessage extends StatelessWidget {
  final dynamic data;

  JoinMessage(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(vertical: 5.0),
      child: Text(
        data['changedGroupMemberInfo'].toString().substring(
                    data['changedGroupMemberInfo'].toString().indexOf('{') + 1,
                    data['changedGroupMemberInfo'].toString().indexOf(':')) ==
                myself.peerId
            ? '你 加入了群聊'
            : data['changedGroupMemberInfo'].toString().substring(
                    data['changedGroupMemberInfo'].toString().indexOf('{') + 1,
                    data['changedGroupMemberInfo'].toString().indexOf(':')) +
                ' 加入了群聊',
        style:
            TextStyle(color: Color.fromRGBO(108, 108, 108, 0.8), fontSize: 11),
      ),
    );
  }
}
