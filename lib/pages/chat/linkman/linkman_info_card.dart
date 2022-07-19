import 'package:flutter/material.dart';

import '../../../widgets/data_bind/data_listshow.dart';

class LinkmanInfoCard extends StatelessWidget {
  final Map<String, dynamic> values;

  const LinkmanInfoCard({Key? key, required this.values}) : super(key: key);

  Widget _build(BuildContext context) {
    var avatar = values['avatar'];
    values.remove('avatar');
    Widget dataListShow = DataListShow(
      values: values,
      avatar: avatar,
    );
    return dataListShow;
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }
}
