import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

///通过选择相册或者拍照选择背景图
class BackgroundPicker extends StatelessWidget {
  const BackgroundPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan,
      body: Column(
        children: <Widget>[
          ListTile(
            title: AutoSizeText(
                AppLocalizations.t('Select backgroud image')),
            onTap: () {
              //routePush(SelectBgPage());
            },
          ),
          ListTile(
            title: AutoSizeText(AppLocalizations.t('Select from album')),
            onTap: () {
              _openGallery();
            },
          ),
          ListTile(
              title: AutoSizeText(AppLocalizations.t('Take a photo')),
              onTap: () {
                _openGallery(source: ImageSource.camera);
              }),
          const Spacer(),
          const SizedBox(),
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
      logger.e(response.exception.toString());
    }
  }
}
