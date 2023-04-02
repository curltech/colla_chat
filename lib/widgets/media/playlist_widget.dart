import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/tool/video_util.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:flutter/material.dart';

///媒体文件播放列表
class PlaylistWidget extends StatefulWidget {
  final AbstractMediaPlayerController controller;
  final Function(int index, String filename)? onSelected;

  const PlaylistWidget({super.key, required this.controller, this.onSelected});

  @override
  State createState() => _PlaylistWidgetState();
}

class _PlaylistWidgetState extends State<PlaylistWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  ///从收藏的文件中加入播放列表
  _collect() async {
    String fileType = widget.controller.fileType.name;
    ChatMessageContentType? contentType =
        StringUtil.enumFromString(ChatMessageContentType.values, fileType);
    contentType = contentType ?? ChatMessageContentType.media;
    List<ChatMessage> chatMessages = await chatMessageService.findByMessageType(
      ChatMessageType.collection.name,
      contentType: contentType.name,
    );
    widget.controller.playlist.clear();
    List<String> filenames = [];
    List<String?> messageIds = [];
    List<Widget?> thumbnails = [];
    for (var chatMessage in chatMessages) {
      var title = chatMessage.title!;
      File file = File(title);
      bool exist = file.existsSync();
      if (!exist) {
        continue;
      }
      filenames.add(title);
      messageIds.add(chatMessage.messageId);
      Widget? thumbnailWidget =
          await _buildThumbnail(title, chatMessage.thumbnail);
      thumbnails.add(thumbnailWidget);
    }
    widget.controller.addAll(filenames: filenames);
  }

  Future<Widget?> _buildThumbnail(String? filename, String? thumbnail) async {
    Widget? thumbnailWidget;
    if (thumbnail != null) {
      thumbnailWidget = ImageUtil.buildImageWidget(
          image: thumbnail,
          width: AppIconSize.maxSize,
          height: AppIconSize.maxSize);
    } else {
      Uint8List? data;
      if (platformParams.mobile && filename != null) {
        data = await VideoUtil.thumbnailData(
            videoFile: filename,
            maxHeight: AppIconSize.maxSize.toInt(),
            maxWidth: AppIconSize.maxSize.toInt());
      }
      if (data != null) {
        thumbnailWidget = ImageUtil.buildMemoryImageWidget(data,
            width: AppIconSize.maxSize, height: AppIconSize.maxSize);
      }
    }

    return thumbnailWidget;
  }

  Future<List<TileData>> _buildTileData(BuildContext context) async {
    List<PlatformMediaSource> mediaSources = widget.controller.playlist;
    List<TileData> tileData = [];
    for (var mediaSource in mediaSources) {
      var filename = mediaSource.filename;
      File file = File(filename);
      bool exist = file.existsSync();
      if (!exist) {
        continue;
      }
      var length = file.lengthSync();
      bool selected = false;
      PlatformMediaSource? current = widget.controller.currentMediaSource;
      if (current != null) {
        if (current.filename == filename) {
          selected = true;
        }
      }
      Widget? thumbnailWidget = await _buildThumbnail(filename, null);
      TileData tile = TileData(
          prefix: thumbnailWidget,
          title: filename,
          subtitle: '$length',
          selected: selected);
      tileData.add(tile);
    }

    return tileData;
  }

  Future<Widget> _buildThumbnailView(BuildContext context) async {
    List<TileData> tileData = await _buildTileData(context);
    if (tileData.isEmpty) {
      return Container(
          alignment: Alignment.center,
          child: Text(AppLocalizations.t('Playlist is empty')));
    }
    int crossAxisCount = 1;
    if (tileData.length > 1) {
      crossAxisCount = 2;
    }
    List<Widget> thumbnails = [];
    if (platformParams.mobile) {
      for (var tile in tileData) {
        List<Widget> children = [];
        if (tile.prefix != null) {
          children.add(tile.prefix);
        }
        children.add(const Spacer());
        children.add(Text(
          tile.title,
          style: const TextStyle(fontSize: AppFontSize.minFontSize),
        ));
        if (tile.subtitle != null) {
          children.add(Text(
            tile.subtitle!,
            style: const TextStyle(fontSize: AppFontSize.minFontSize),
          ));
        }
        var thumbnail = Column(children: children);
        thumbnails.add(thumbnail);
      }

      return GridView.builder(
          itemCount: tileData.length,
          //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              //横轴元素个数
              crossAxisCount: crossAxisCount,
              //纵轴间距
              mainAxisSpacing: 1.0,
              //横轴间距
              crossAxisSpacing: 1.0,
              //子组件宽高长度比例
              childAspectRatio: 1),
          itemBuilder: (BuildContext context, int index) {
            //Widget Function(BuildContext context, int index)
            return thumbnails[index];
          });
    } else {
      return DataListView(
        tileData: tileData,
        onTap: (int index, String title, {TileData? group, String? subtitle}) {
          widget.controller.setCurrentIndex(index);
          if (widget.onSelected != null) {
            widget.onSelected!(index, title);
          }
        },
      );
    }
  }

  ///选择文件加入播放列表
  _addMediaSource() async {
    List<PlatformMediaSource> mediaSources =
        await widget.controller.sourceFilePicker();
  }

  _removeFromCollect(int index) async {
    PlatformMediaSource mediaSource = widget.controller.playlist[index];
    var messageId = mediaSource.messageId;
    if (messageId != null) {
      await chatMessageService
          .delete(where: 'messageId=?', whereArgs: [messageId]);
    }
  }

  ///将播放列表的文件加入收藏
  _collectMediaSource(int index) async {
    PlatformMediaSource mediaSource = widget.controller.playlist[index];
    var filename = mediaSource.filename;
    var mediaFormat = mediaSource.mediaFormat!.name;
    File file = File(filename);
    bool exist = file.existsSync();
    if (!exist) {
      return;
    }
    Uint8List? thumbnail;
    if (platformParams.mobile) {
      thumbnail = await VideoUtil.thumbnailData(
          videoFile: filename,
          maxHeight: AppIconSize.maxSize.toInt(),
          maxWidth: AppIconSize.maxSize.toInt());
    }
    ChatMessageMimeType? chatMessageMimeType =
        StringUtil.enumFromString<ChatMessageMimeType>(
            ChatMessageMimeType.values, mediaFormat);
    String fileType = widget.controller.fileType.name;
    ChatMessageContentType? contentType =
        StringUtil.enumFromString(ChatMessageContentType.values, fileType);
    contentType = contentType ?? ChatMessageContentType.media;
    var chatMessage = await chatMessageService.buildChatMessage(
      receiverPeerId: myself.peerId!,
      messageType: ChatMessageType.collection,
      contentType: contentType,
      mimeType: chatMessageMimeType,
      title: filename,
      thumbnail: thumbnail,
    );
    await chatMessageService.store(chatMessage);
  }

  ///播放列表按钮
  Widget _buildPlaylistButton(BuildContext context) {
    return ButtonBar(
      children: [
        InkWell(
          child: const Icon(Icons.playlist_add),
          onTap: () async {
            _addMediaSource();
          },
        ),
        InkWell(
          child: const Icon(Icons.playlist_remove),
          onTap: () async {
            var currentIndex = widget.controller.currentIndex;
            await widget.controller.remove(currentIndex);
          },
        ),
        InkWell(
          child: const Icon(Icons.video_collection),
          onTap: () async {
            await _collect();
          },
        ),
        InkWell(
          child: const Icon(Icons.collections),
          onTap: () async {
            var currentIndex = widget.controller.currentIndex;
            await _collectMediaSource(currentIndex);
          },
        ),
        InkWell(
          child: const Icon(Icons.bookmark_remove),
          onTap: () async {
            var currentIndex = widget.controller.currentIndex;
            await _removeFromCollect(currentIndex);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildPlaylistButton(context),
      Expanded(
          child: FutureBuilder(
              future: _buildThumbnailView(context),
              builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (!snapshot.hasData) {
                  return Container();
                }
                Widget? playlist = snapshot.data;
                if (playlist == null) {
                  return Container();
                }
                return playlist;
              })),
    ]);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }
}
