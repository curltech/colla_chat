import 'package:flutter/material.dart';

class ModifyNotificationMessage extends StatefulWidget {
  final dynamic data;

  ModifyNotificationMessage(this.data);

  ModifyNotificationMessageState createState() =>
      ModifyNotificationMessageState();
}

class ModifyNotificationMessageState extends State<ModifyNotificationMessage> {
  late String name;
  late List membersData;

  @override
  void initState() {
    super.initState();
    String user = widget.data['opGroupMemberInfo']['user'];
    getCardName(user);
  }

  getCardName(String user) async {
    // await InfoModel.getGroupMembersInfoModel(widget.data['groupId'], [user],
    //     callback: (str) {
    //   String strToData = str.toString().replaceAll("'", '"');
    //   membersData = json.decode(strToData);
    // });
    // var userPhone = await getStoreValue('userPhone');
    // if (listNoEmpty(membersData)) if (user == userPhone)
    //   name = '你';
    // else if (StringUtil.isNotEmpty(membersData[0]['nameCard']))
    //   name = membersData[0]['nameCard'];
    // else
    //   name = user;
    // setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(vertical: 5.0),
      child: Text(
        '${name ?? ''}' + ' 修改了群公告',
        style:
            TextStyle(color: Color.fromRGBO(108, 108, 108, 0.8), fontSize: 11),
      ),
    );
  }
}
