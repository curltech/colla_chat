import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../provider/app_data_provider.dart';
import '../../chat/widget/ui.dart';

///通过选择相册或者拍照选择背景图
class BackgroundPicker extends StatelessWidget {
  const BackgroundPicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan,
      body: Column(
        children: <Widget>[
          ListTile(
            title: Text('选择背景图'),
            onTap: () {
              //routePush(SelectBgPage());
            },
          ),
          ListTile(
            title: Text('从手机相册选择'),
            onTap: () {
              _openGallery();
            },
          ),
          ListTile(
              title: Text('拍一张'),
              onTap: () {
                _openGallery(source: ImageSource.camera);
              }),
          Space(height: 15),
          SizedBox(),
        ],
      ),
    );
  }

  // 从相册选取图片
  _openGallery({
    ImageSource source = ImageSource.gallery,
  }) async {
    final ImagePicker picker = ImagePicker();
    XFile? data = await picker.pickImage(source: source);
    if (data != null) {
    } else {
      return;
    }
  }

  ///因为android杀进程，这里用于找回选择的照片
  Future<void> getLostData() async {
    final ImagePicker picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    var files = response.files;
    if (files != null) {
      for (final XFile file in files) {}
    } else {
      logger.e(response.exception);
    }
  }
}
