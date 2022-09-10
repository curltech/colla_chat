import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:flutter/material.dart';

import '../../login/loading.dart';

///从assets目录下背景图片选择器
class BackgroudSelector extends StatelessWidget {
  const BackgroudSelector({Key? key}) : super(key: key);

  Widget buildBackgroud(String item) {
    double size = (appDataProvider.size.width - 30) / 3;
    return InkWell(
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        child: Image.asset(
          item,
          width: size - 0.01,
          height: size,
          fit: BoxFit.fill,
        ),
      ),
      onTap: () => DialogUtil.showToast('敬请期待'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan,
      body: Container(
        padding: const EdgeInsets.only(top: 5.0, left: 5.0, right: 5.0),
        child: Wrap(
          runSpacing: 10.0,
          spacing: 10.0,
          children: darkBackgroudImages.map(buildBackgroud).toList(),
        ),
      ),
    );
  }
}
