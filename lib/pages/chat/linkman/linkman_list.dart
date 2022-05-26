import 'package:flutter/material.dart';

import '../../../entity/chat/contact.dart';

class LinkmanList extends StatefulWidget {
  const LinkmanList({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LinkmanListState();
  }
}

class _LinkmanListState extends State<LinkmanList> {
  late final Linkman linkman;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Column(
                  children: <Widget>[],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
