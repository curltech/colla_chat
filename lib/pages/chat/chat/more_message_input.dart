import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/entity/chat/linkman.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/pages/chat/chat/controller/chat_message_controller.dart';
import 'package:colla_chat/pages/chat/linkman/linkman_group_search_widget.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/plugin/mobile_camera_widget.dart';
import 'package:colla_chat/provider/index_widget_provider.dart';
import 'package:colla_chat/service/chat/linkman.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/entity_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/geolocator_util.dart';
import 'package:colla_chat/tool/json_util.dart';
import 'package:colla_chat/tool/smart_dialog_util.dart';
import 'package:colla_chat/widgets/common/app_bar_widget.dart';
import 'package:colla_chat/widgets/data_bind/base.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_select.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

final List<ActionData> defaultActionData = [
  ActionData(
      label: 'DeleteTime',
      tooltip: 'Delete time',
      icon: const Icon(Icons.timer_sharp)),
  ActionData(
      label: 'Picture',
      tooltip: 'Take a picture',
      icon: const Icon(Icons.camera)),
  ActionData(
    label: 'Video chat',
    tooltip: 'Invite video chat',
    icon: const Icon(Icons.video_call),
  ),
  ActionData(
      label: 'Location',
      tooltip: 'Geographical position',
      icon: const Icon(Icons.location_on)),
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
      case 'DeleteTime':
        _onActionDeleteTime();
        break;
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

  ///阅后删除时间
  _onActionDeleteTime() async {
    int? deleteTime = await DialogUtil.showSelectDialog<int>(
        context: context,
        title:
            AppBarWidget.buildTitleBar(title: const Text('Select deleteTime')),
        items: [
          _buildOption(0),
          _buildOption(15),
          _buildOption(30),
          _buildOption(300),
          _buildOption(600),
          _buildOption(1800),
        ]);
    deleteTime = deleteTime ?? 0;
    chatMessageController.deleteTime = deleteTime;
  }

  Option _buildOption(int deleteTime) {
    return Option(
      '${deleteTime}s',
      deleteTime,
      checked: chatMessageController.deleteTime == deleteTime,
    );
  }

  ///视频通话
  _onActionVideoChat() {
    chatMessageController.current = null;
    indexWidgetProvider.push('video_chat');
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
    XFile? mediaFile;
    var f = await DialogUtil.show(
        context: context,
        builder: (BuildContext context) {
          return MobileCameraWidget(
            onFile: (XFile file) {
              mediaFile = file;
            },
          );
        });
    if (mediaFile != null) {
      List<int> data = await mediaFile!.readAsBytes();
      String name = mediaFile!.name;
      String mimeType = FileUtil.extension(name);
      if (mediaFile!.mimeType != null) {
        mimeType = mediaFile!.mimeType!;
      }
      ContentType contentType = ContentType.image;
      if (mimeType.endsWith('mp4')) {
        contentType = ContentType.video;
        mimeType = MimeType.mp4.name;
      }
      await chatMessageController.send(
          title: name,
          content: data,
          contentType: contentType,
          mimeType: mimeType);
    }
  }

  ///位置
  void _onActionLocation() async {
    Position position = await GeolocatorUtil.currentPosition();
    double latitude = position.latitude;
    double longitude = position.longitude;
    String? address;
    await SmartDialogUtil.show(
        context: context,
        title: AppBarWidget.buildTitleBar(
            title: Text(AppLocalizations.t('Location map'))),
        builder: (BuildContext? context) {
          return GeolocatorUtil.buildLocationPicker(
              latitude: latitude,
              longitude: longitude,
              onPicked: (PickedData data) {
                longitude = data.latLong.longitude;
                latitude = data.latLong.latitude;
                address = data.address;
              });
        });
    // await SmartDialogUtil.show(
    //     context: context,
    //     title: AppLocalizations.t('Location map'),
    //     builder: (BuildContext context) {
    //       return GeolocatorUtil.buildPlatformMap(
    //         latitude: latitude,
    //         longitude: longitude,
    //         onTap: (latLng) {
    //           longitude = latLng.longitude;
    //           latitude = latLng.latitude;
    //         },
    //       );
    //     });
    LocationPosition locationPosition;
    if (address != null) {
      locationPosition = LocationPosition(
          longitude: longitude, latitude: latitude, address: address);
    } else {
      var json = position.toJson();
      locationPosition = LocationPosition.fromJson(json);
    }
    Map<String, dynamic> map = locationPosition.toJson();
    EntityUtil.removeNull(map);
    JsonUtil.toJsonString(map);
    String content = JsonUtil.toJsonString(map);
    await chatMessageController.sendText(
        message: content, contentType: ContentType.location);
  }

  ///名片
  Future<void> _onActionNameCard() async {
    await DialogUtil.show(
        context: context,
        title:
            AppBarWidget.buildTitleBar(title: const Text('Select one linkman')),
        builder: (BuildContext context) {
          return LinkmanGroupSearchWidget(
              onSelected: (List<String>? selected) async {
                if (selected != null && selected.isNotEmpty) {
                  Linkman? linkman =
                      await linkmanService.findCachedOneByPeerId(selected[0]);
                  if (linkman != null) {
                    String content = JsonUtil.toJsonString(linkman);
                    await chatMessageController.sendText(
                        message: content, contentType: ContentType.card);
                  }
                }
              },
              selected: const <String>[],
              selectType: SelectType.chipMultiSelect);
        });
  }

  ///文件
  Future<void> _onActionFile() async {
    List<XFile> xfiles = await FileUtil.pickFiles();
    if (xfiles.isNotEmpty) {
      XFile xfile = xfiles[0];
      List<int> data = await xfile.readAsBytes();
      String? mimeType = FileUtil.mimeType(xfile.mimeType!);
      await chatMessageController.send(
          title: FileUtil.filename(xfile.path),
          content: data,
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
