import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';

///右边栏，用于展示当前用户信息，当前用户的配置信息
class EndDrawer extends StatelessWidget {
  const EndDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var endDrawer = Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Drawer(
          child: ListView(
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountEmail: CommonAutoSizeText('hujs@colla.cc'),
                accountName: CommonAutoSizeText('胡劲松'),
              ),
              ListTile(
                  leading: Icon(Icons.chat),
                  title: CommonAutoSizeText(''),
                  onTap: () {}),
              ListTile(
                  leading: Icon(Icons.contacts),
                  title: CommonAutoSizeText(''),
                  onTap: () {}),
              ListTile(
                  leading: Icon(Icons.wifi_channel),
                  title: CommonAutoSizeText(''),
                  onTap: () {}),
              ListTile(
                  leading: Icon(Icons.person),
                  title: CommonAutoSizeText(''),
                  onTap: () {}),
            ],
          ),
        ));
    return endDrawer;
  }
}
