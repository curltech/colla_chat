import 'dart:io';

import 'package:camera/camera.dart';
import 'package:colla_chat/plugin/logger.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../widgets/common/action_card.dart';

final List<TileData> actionTileData = [
  TileData(title: '相册', icon: const Icon(Icons.photo_album)),
  TileData(title: '拍摄', icon: const Icon(Icons.camera)),
  TileData(title: '视频通话', icon: const Icon(Icons.video_call)),
  TileData(title: '位置', icon: const Icon(Icons.location_city)),
  TileData(title: '名片', icon: const Icon(Icons.card_membership)),
  TileData(title: '文件', icon: const Icon(Icons.file_open)),
  TileData(title: '语音', icon: const Icon(Icons.voice_chat)),
  TileData(title: '收藏', icon: const Icon(Icons.favorite)),
];

///非文本的其他多种格式输入面板，包括照片等
class MoreMessageInput extends StatefulWidget {
  final double height;
  final Future<void> Function(int index, String name) onAction;

  const MoreMessageInput({Key? key, this.height = 0.0, required this.onAction})
      : super(key: key);

  @override
  State createState() => _MoreMessageInputState();
}

class _MoreMessageInputState extends State<MoreMessageInput> {
  List<AssetEntity> assets = <AssetEntity>[];

  _action(int index, String name) async {
    switch (name) {
      case '视频通话':
        break;
      default:
        break;
    }
  }



  _actionAlbum(int index, String name) async {
    if (name == '相册') {
      var pickerConfig = AssetPickerConfig(
        maxAssets: 9,
        pageSize: 320,
        pathThumbnailSize: const ThumbnailSize(80, 80),
        gridCount: 4,
        selectedAssets: assets,
        themeColor: Colors.green,
      );
      final List<AssetEntity>? result =
          await AssetPicker.pickAssets(context, pickerConfig: pickerConfig);

      result?.forEach((AssetEntity element) async {
        //   sendImageMsg(widget.id, widget.type, file: await element.file
        //     //   callback: (v) {
        //     // if (v == null) return;
        //     //Notice.send(WeChatActions.msg(), v ?? '');
        //   // });
        //   // element.file;
        // );
      });
    }
  }

  _actionPhoto(int index, String name) async {
    if (name == '拍摄') {
      try {
        List<CameraDescription> cameras;

        WidgetsFlutterBinding.ensureInitialized();
        cameras = await availableCameras();

        //routePush(ShootPage(cameras));
      } on CameraException catch (e) {
        logger.e(e.code, e.description);
      }
    }
  }

  _buildActionCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: ActionCard(
        actions: actionTileData,
        height: widget.height,
        onPressed: widget.onAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildActionCard(context);
  }
}

Future<void> sendImageMsg(String userName, int type,
    {required ImageSource source, required File file}) async {
  XFile? image;
  if (file.existsSync()) {
    image = XFile(file.path);
  } else {
    image = await ImagePicker().pickImage(source: source);
  }
  if (image == null) return;
  File compressImg = await File(image.path);

  try {
    //await im.sendImageMessages(userName, compressImg.path, type: type);
    //callback(compressImg.path);
  } on PlatformException {
    debugPrint("发送图片消息失败");
  }
}

Future<dynamic> sendSoundMessages(
    String id, String soundPath, int duration, int type) async {
  try {
    //var result = await im.sendSoundMessages(id, soundPath, type, duration);
  } on PlatformException {
    debugPrint('发送语音  失败');
  }
}
