import 'package:colla_chat/pages/chat/linkman/linkman_list.dart';
import 'package:flutter/material.dart';

import '../../../entity/chat/contact.dart';

class Linkman extends StatefulWidget {
  const Linkman({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _LinkmanState();
  }
}

class _LinkmanState extends State<Linkman> {
  late final Linkman linkman;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LinkmanList(),
    );
  }
}
