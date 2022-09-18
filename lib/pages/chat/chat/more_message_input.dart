import 'dart:io';

import 'package:camera/camera.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/camera_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../widgets/data_bind/data_action_card.dart';

final List<ActionData> actionData = [
  ActionData(
      label: 'album',
      tooltip: 'photo album',
      icon: const Icon(Icons.photo_album)),
  ActionData(
      label: 'video', tooltip: 'shoot a video', icon: const Icon(Icons.camera)),
  ActionData(
      label: 'video chat',
      tooltip: 'invite video chat',
      icon: const Icon(Icons.video_call)),
  ActionData(
      label: 'location',
      tooltip: 'geographical position',
      icon: const Icon(Icons.location_city)),
  ActionData(
      label: 'name card',
      tooltip: 'share name card',
      icon: const Icon(Icons.card_membership)),
  ActionData(
      label: 'file',
      tooltip: 'pick and send file',
      icon: const Icon(Icons.file_open)),
  ActionData(
      label: 'voice',
      tooltip: 'record voice',
      icon: const Icon(Icons.voice_chat)),
  ActionData(
      label: 'collection',
      tooltip: 'collection',
      icon: const Icon(Icons.favorite)),
];

///非文本的其他多种格式输入面板，包括照片等
class MoreMessageInput extends StatefulWidget {
  final double height;
  final Future<void> Function(int index, String name, {String? value}) onAction;

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
      final List<AssetEntity>? result = await AssetUtil.pickAssets(
        context,
      );
      if (result != null && result.isNotEmpty) {
        List<Map<String, dynamic>> maps = await AssetUtil.toJsons(result);
        String json = JsonUtil.toJsonString(maps);
      }
    }
  }

  _actionPhoto(int index, String name) async {
    if (name == '拍摄') {
      AssetEntity? entry = await CameraUtil.pickFromCamera(context);
      if (entry != null) {
        Map<String, dynamic> map = await AssetUtil.toJson(entry);
        String json = JsonUtil.toJsonString(map);
      }
    }
  }

  Widget _buildActionCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: DataActionCard(
        actions: actionData,
        height: widget.height,
        onPressed: widget.onAction,
        crossAxisCount: 4,
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
