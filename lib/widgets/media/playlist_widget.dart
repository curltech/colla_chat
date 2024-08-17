import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/tool/video_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/data_bind/data_listview.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlaylistController extends DataListController<PlatformMediaSource> {
  FileType fileType = FileType.custom;
  final Set<String> videoExtensions = {
    'mp4',
    '3gp',
    'm4a',
    'mov',
    'mpeg',
    'aac',
    'rmvb',
    'avi',
    'wmv',
    'mkv',
    'mpg',
  };
  final Set<String> audioExtensions = {
    'mp3',
    'wav',
    'mp4',
    'm4a',
  };
  final Set<String> imageExtensions = {
    'jpg',
    'png',
    'bmp',
    'webp',
  };
  final Set<String> allowedExtensions = {};

  PlaylistController() {
    allowedExtensions.addAll(videoExtensions);
    allowedExtensions.addAll(audioExtensions);
    allowedExtensions.addAll(imageExtensions);
  }

  previous() async {
    if (currentIndex == null || currentIndex == 0) {
      return;
    }
    currentIndex = currentIndex! - 1;
  }

  next() async {
    if (currentIndex == null || currentIndex! >= data.length - 1) {
      return;
    }
    currentIndex = currentIndex! + 1;
  }

  Future<PlatformMediaSource?> addMediaFile(
      {required String filename, String? messageId, Widget? thumbnail}) async {
    for (var mediaSource in data) {
      var name = mediaSource.filename;
      if (name == filename) {
        return null;
      }
    }
    PlatformMediaSource? mediaSource =
        await PlatformMediaSource.media(filename: filename);
    if (mediaSource != null) {
      mediaSource.messageId = messageId;
      add(mediaSource);
    }

    return mediaSource;
  }

  Future<List<PlatformMediaSource>> addMediaFiles(
      {required List<String> filenames,
      List<String?>? messageIds,
      List<Widget?>? thumbnails}) async {
    List<PlatformMediaSource> mediaSources =
        await PlatformMediaSource.playlist(filenames);
    if (messageIds != null && messageIds.isNotEmpty) {
      for (var i = 0; i < mediaSources.length; i++) {
        var mediaSource = mediaSources[i];
        if (messageIds.length > i) {
          mediaSource.messageId = messageIds[i];
        }
      }
    }
    addAll(mediaSources);
    if (data.isNotEmpty) {
      currentIndex = data.length - 1;
    }

    return mediaSources;
  }

  Future<PlatformMediaSource?> insertMediaFile(int index,
      {required String filename}) async {
    for (var mediaSource in data) {
      var name = mediaSource.filename;
      if (name == filename) {
        return null;
      }
    }
    PlatformMediaSource? mediaSource =
        await PlatformMediaSource.media(filename: filename);
    if (mediaSource != null) {
      insert(index, mediaSource);
    }

    return mediaSource;
  }

  Future<List<PlatformMediaSource>> sourceFilePicker({
    String? dialogTitle,
    bool directory = false,
    String? initialDirectory,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = true,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) async {
    Set<String> allowedExtensions = {};
    allowedExtensions.addAll(this.allowedExtensions);
    for (var allowedExtension in this.allowedExtensions) {
      allowedExtensions.add(allowedExtension.toUpperCase());
    }
    List<PlatformMediaSource> mediaSources = [];
    if (directory) {
      String? path = await FileUtil.directoryPathPicker(
          dialogTitle: dialogTitle, initialDirectory: initialDirectory);
      if (path != null) {
        Directory dir = Directory(path);
        List<FileSystemEntity> entries = dir.listSync();
        if (entries.isNotEmpty) {
          for (FileSystemEntity entry in entries) {
            String? extension = FileUtil.extension(entry.path);
            if (extension == null) {
              continue;
            }
            bool? contain = allowedExtensions.contains(extension);
            if (contain) {
              PlatformMediaSource? mediaSource =
                  await addMediaFile(filename: entry.path);
              if (mediaSource != null) {
                mediaSources.add(mediaSource);
              }
            }
          }
          currentIndex = data.length - 1;
        }
      }
    } else {
      final xfiles = await FileUtil.pickFiles(
          allowMultiple: allowMultiple,
          type: fileType,
          allowedExtensions: allowedExtensions.toList());
      if (xfiles.isNotEmpty) {
        for (var xfile in xfiles) {
          PlatformMediaSource? mediaSource =
              await addMediaFile(filename: xfile.path);
          if (mediaSource != null) {
            mediaSources.add(mediaSource);
          }
        }
        currentIndex = data.length - 1;
      }
    }

    return mediaSources;
  }
}

///媒体文件播放列表
class PlaylistWidget extends StatelessWidget {
  final Function(int index, String filename)? onSelected;
  final PlaylistController playlistController;

  PlaylistWidget(
      {super.key, this.onSelected, required this.playlistController});

  RxList<TileData> tileData = <TileData>[].obs;
  RxBool gridMode = false.obs;

  ///从收藏的文件中加入播放列表
  _collect() async {
    String fileType = playlistController.fileType.name;
    ChatMessageContentType? contentType =
        StringUtil.enumFromString(ChatMessageContentType.values, fileType);
    contentType = contentType ?? ChatMessageContentType.media;
    List<ChatMessage> chatMessages = await chatMessageService.findByMessageType(
      ChatMessageType.collection.name,
      contentType: contentType.name,
    );
    playlistController.clear();
    List<String> filenames = [];
    for (var chatMessage in chatMessages) {
      var title = chatMessage.title!;
      var messageId = chatMessage.messageId!;
      String? filename =
          await messageAttachmentService.getDecryptFilename(messageId, title);
      if (filename != null) {
        File file = File(filename);
        bool exist = file.existsSync();
        if (!exist) {
          continue;
        }
        filenames.add(filename);
      }
    }
    playlistController.addMediaFiles(filenames: filenames);
  }

  Future<void> _buildTileData(BuildContext context) async {
    List<PlatformMediaSource> mediaSources = playlistController.data;
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
      PlatformMediaSource? current = playlistController.current;
      if (current != null) {
        if (current.filename == filename) {
          selected = true;
        }
      }
      Widget? thumbnailWidget = mediaSource.thumbnailWidget;
      TileData tile = TileData(
        prefix: thumbnailWidget,
        title: FileUtil.filename(filename),
        subtitle: '$length',
        selected: selected,
        onTap: (int index, String title, {String? subtitle}) {
          playlistController.currentIndex = index;
          _buildTileData(context);
        },
      );
      tileData.add(tile);
    }

    this.tileData(tileData);
  }

  Future<Widget> _buildThumbnailView(BuildContext context) async {
    return Obx(() {
      if (tileData.isEmpty) {
        return Container(
            alignment: Alignment.center,
            child: CommonAutoSizeText(AppLocalizations.t('Playlist is empty')));
      }
      int crossAxisCount = 3;
      List<Widget> thumbnails = [];
      for (var tile in tileData) {
        List<Widget> children = [];
        children.add(const Spacer());
        children.add(CommonAutoSizeText(
          tile.title,
          style: const TextStyle(fontSize: AppFontSize.minFontSize),
        ));
        if (tile.subtitle != null) {
          children.add(const SizedBox(
            height: 2.0,
          ));
          children.add(CommonAutoSizeText(
            tile.subtitle!,
            style: const TextStyle(fontSize: AppFontSize.minFontSize),
          ));
        }
        var thumbnail = Container(
            decoration: tile.selected ?? false
                ? BoxDecoration(
                    border: Border.all(width: 2, color: myself.primary))
                : null,
            padding: EdgeInsets.zero,
            child: Card(
                elevation: 0.0,
                margin: EdgeInsets.zero,
                shape: const ContinuousRectangleBorder(),
                child: Stack(
                  children: [
                    tile.prefix ?? nil,
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children)
                  ],
                )));
        thumbnails.add(thumbnail);
      }

      if (gridMode.isTrue) {
        return GridView.builder(
            itemCount: tileData.length,
            //SliverGridDelegateWithFixedCrossAxisCount 构建一个横轴固定数量Widget
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                //横轴元素个数
                crossAxisCount: crossAxisCount,
                //纵轴间距
                mainAxisSpacing: 4.0,
                //横轴间距
                crossAxisSpacing: 4.0,
                //子组件宽高长度比例
                childAspectRatio: 1),
            itemBuilder: (BuildContext context, int index) {
              //Widget Function(BuildContext context, int index)
              return InkWell(
                  child: thumbnails[index],
                  onTap: () {
                    playlistController.currentIndex = index;
                    if (onSelected != null) {
                      onSelected!(index, tileData[index].title);
                    }
                  });
            });
      } else {
        return DataListView(
          onTap: (int index, String title,
              {TileData? group, String? subtitle}) {
            playlistController.currentIndex = index;
            if (onSelected != null) {
              onSelected!(index, title);
            }
          },
          itemCount: tileData.length,
          itemBuilder: (BuildContext context, int index) {
            return tileData[index];
          },
        );
      }
    });
  }

  ///选择文件加入播放列表
  _addMediaSource(BuildContext context, {bool directory = false}) async {
    try {
      List<PlatformMediaSource> mediaSources =
          await playlistController.sourceFilePicker(directory: directory);
    } catch (e) {
      DialogUtil.error(content: 'add media file failure:$e');
    }
  }

  _removeFromCollect(int index) async {
    PlatformMediaSource? mediaSource = playlistController.delete(index: index);
    var messageId = mediaSource?.messageId;
    if (messageId != null) {
      chatMessageService.delete(where: 'messageId=?', whereArgs: [messageId]);
    }
  }

  ///将播放列表的文件加入收藏
  _collectMediaSource(int index) async {
    PlatformMediaSource? mediaSource = playlistController.get(index);
    if (mediaSource == null) {
      return;
    }
    var filename = mediaSource.filename;
    String mediaFormat = mediaSource.mediaFormat!;
    File file = File(filename);
    bool exist = file.existsSync();
    if (!exist) {
      return;
    }
    Uint8List? thumbnail =
        await VideoUtil.getByteThumbnail(videoFile: filename);
    // ChatMessageMimeType? chatMessageMimeType =
    //     StringUtil.enumFromString<ChatMessageMimeType>(
    //         ChatMessageMimeType.values, mediaFormat);
    String fileType = playlistController.fileType.name;
    ChatMessageContentType? contentType =
        StringUtil.enumFromString(ChatMessageContentType.values, fileType);
    contentType = contentType ?? ChatMessageContentType.media;
    var chatMessage = await chatMessageService.buildChatMessage(
      receiverPeerId: myself.peerId!,
      messageType: ChatMessageType.collection,
      contentType: contentType,
      mimeType: mediaFormat,
      title: filename,
      thumbnail: CryptoUtil.encodeBase64(thumbnail!),
    );
    await chatMessageService.store(chatMessage);
  }

  ///播放列表按钮
  Widget _buildPlaylistButton(BuildContext context) {
    return Column(
      children: [
        ButtonBar(
          alignment: MainAxisAlignment.start,
          children: [
            IconButton(
              color: myself.primary,
              icon: Obx(() {
                return Icon(
                  gridMode.isTrue ? Icons.list : Icons.grid_on,
                  color: Colors.white,
                );
              }),
              onPressed: () {
                gridMode(!gridMode.value);
              },
              tooltip: AppLocalizations.t('Toggle grid mode'),
            ),
            IconButton(
              color: myself.primary,
              icon: const Icon(
                Icons.featured_play_list_outlined,
                color: Colors.white,
              ),
              onPressed: () async {
                await _addMediaSource(context, directory: true);
                _buildTileData(context);
              },
              tooltip: AppLocalizations.t('Add video directory'),
            ),
            IconButton(
              color: myself.primary,
              icon: const Icon(
                Icons.playlist_add,
                color: Colors.white,
              ),
              onPressed: () async {
                await _addMediaSource(context);
                _buildTileData(context);
              },
              tooltip: AppLocalizations.t('Add video file'),
            ),
            IconButton(
              color: myself.primary,
              icon: const Icon(
                Icons.bookmark_remove,
                color: Colors.white,
              ),
              onPressed: () async {
                await playlistController.clear();
                _buildTileData(context);
              },
              tooltip: AppLocalizations.t('Remove all video file'),
            ),
            IconButton(
              color: myself.primary,
              icon: const Icon(
                Icons.playlist_remove,
                color: Colors.white, //myself.primary,
              ),
              onPressed: () async {
                var currentIndex = playlistController.currentIndex;
                playlistController.delete(index: currentIndex);
                _buildTileData(context);
              },
              tooltip: AppLocalizations.t('Remove video file'),
            ),
          ],
        ),
        ButtonBar(
          alignment: MainAxisAlignment.end,
          children: [
            IconButton(
              color: myself.primary,
              icon: const Icon(
                Icons.video_collection,
                color: Colors.white, //myself.primary,
              ),
              onPressed: () async {
                await _collect();
              },
              tooltip: AppLocalizations.t('Select collect file'),
            ),
            IconButton(
              color: myself.primary,
              icon: const Icon(
                Icons.collections,
                color: Colors.white, //myself.primary,
              ),
              onPressed: () async {
                int? currentIndex = playlistController.currentIndex;
                if (currentIndex != null) {
                  await _collectMediaSource(currentIndex);
                }
              },
              tooltip: AppLocalizations.t('Collect video file'),
            ),
            IconButton(
              color: myself.primary,
              icon: const Icon(
                Icons.bookmark_remove,
                color: Colors.white, //myself.primary,
              ),
              onPressed: () async {
                var currentIndex = playlistController.currentIndex;
                if (currentIndex != null) {
                  await _removeFromCollect(currentIndex);
                }
              },
              tooltip: AppLocalizations.t('Remove collect file'),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _buildTileData(context);
    return Column(children: [
      _buildPlaylistButton(context),
      Expanded(
          child: PlatformFutureBuilder(
              future: _buildThumbnailView(context),
              builder: (BuildContext context, Widget playlist) {
                return playlist;
              })),
    ]);
  }
}
