import 'package:colla_chat/entity/chat/chat.dart';
import 'package:colla_chat/entity/dht/myself.dart';
import 'package:colla_chat/entity/dht/peerclient.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/camera_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/geolocator_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

final List<ActionData> defaultActionData = [
  ActionData(
      label: 'Picture',
      tooltip: 'Take a picture',
      icon: const Icon(Icons.camera)),
  ActionData(
      label: 'Voice',
      tooltip: 'Record voice',
      icon: const Icon(Icons.voice_chat)),
  ActionData(
    label: 'Video chat',
    tooltip: 'Invite video chat',
    icon: const Icon(Icons.video_call),
  ),
  ActionData(
      label: 'Location',
      tooltip: 'Geographical position',
      icon: const Icon(Icons.location_city)),
  ActionData(
      label: 'Name card',
      tooltip: 'Share name card',
      icon: const Icon(Icons.card_membership)),
  ActionData(
      label: 'File',
      tooltip: 'Pick and send file',
      icon: const Icon(Icons.file_open)),
  ActionData(
      label: 'Collection',
      tooltip: 'Collection',
      icon: const Icon(Icons.collections)),
];

///非文本的其他多种格式输入面板，包括照片等
class MoreMessageInput extends StatefulWidget {
  final double height;
  final Future<void> Function(int index, String name, {String? value})?
      onAction;

  const MoreMessageInput({Key? key, this.height = 0.0, this.onAction})
      : super(key: key);

  @override
  State createState() => _MoreMessageInputState();
}

class _MoreMessageInputState extends State<MoreMessageInput> {
  List<ActionData> actionData = [];

  @override
  initState() {
    super.initState();
    var albumActionData = ActionData(
        label: 'Album',
        tooltip: 'Photo album',
        icon: const Icon(Icons.photo_album));
    if (platformParams.ios || platformParams.android || platformParams.macos) {
      actionData.add(albumActionData);
    }
    actionData.addAll(defaultActionData);
  }

  _onAction(int index, String name, {String? value}) async {
    if (widget.onAction != null) {
      widget.onAction!(index, name, value: value);
      return;
    }
    switch (name) {
      case 'Album':
        _onActionAlbum();
        break;
      case 'Picture':
        _onActionPicture();
        break;
      case 'Video chat':
        _onActionVideoChat();
        break;
      case 'Location':
        _onActionLocation();
        break;
      case 'Name card':
        _onActionNameCard();
        break;
      case 'File':
        _onActionFile();
        break;
      case 'Voice':
        _onActionVoice();
        break;
      case 'Collection':
        _onActionCollection();
        break;
      default:
        break;
    }
  }

  ///视频通话
  _onActionVideoChat() {
    chatMessageController.chatView = ChatView.dial;
  }

  ///相册
  _onActionAlbum() async {
    final List<AssetEntity>? result = await AssetUtil.pickAssets(
      context,
    );
    if (result != null && result.isNotEmpty) {
      List<Map<String, dynamic>> maps = await AssetUtil.toJsons(result);
      String content = JsonUtil.toJsonString(maps);
      await chatMessageController.sendText(
          message: content, contentType: ContentType.image);
    }
  }

  ///拍照
  _onActionPicture() async {
    AssetEntity? entry = await CameraUtil.pickFromCamera(context);
    if (entry != null) {
      Map<String, dynamic> map = await AssetUtil.toJson(entry);
      String content = JsonUtil.toJsonString(map);
      await chatMessageController.sendText(
          message: content, contentType: ContentType.image);
    }
  }

  ///位置
  void _onActionLocation() async {
    Position position = await GeolocatorUtil.currentPosition();
    String content = JsonUtil.toJsonString(position);
    await chatMessageController.sendText(
        message: content, contentType: ContentType.location);
  }

  ///名片
  Future<void> _onActionNameCard() async {
    String content = JsonUtil.toJsonString(myself.myselfPeer);
    PeerClient peerClient = PeerClient.fromJson(JsonUtil.toJson(content));
    content = JsonUtil.toJsonString(peerClient);
    await chatMessageController.sendText(
        message: content, contentType: ContentType.card);
  }

  ///文件
  Future<void> _onActionFile() async {
    List<String> filenames = await FileUtil.pickFiles();
    if (filenames.isNotEmpty) {
      List<int> data = await FileUtil.readFile(filenames[0]);
      String? mimeType = FileUtil.mimeType(filenames[0]);
      await chatMessageController.send(
          title: FileUtil.filename(filenames[0]),
          data: data,
          contentType: ContentType.file,
          mimeType: mimeType);
    }
  }

  void _onActionVoice() {}

  ///收藏
  void _onActionCollection() {}

  Widget _buildActionCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0.0),
      padding: const EdgeInsets.only(bottom: 0.0),
      child: DataActionCard(
        actions: actionData,
        height: widget.height,
        onPressed: _onAction,
        crossAxisCount: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildActionCard(context);
  }
}
