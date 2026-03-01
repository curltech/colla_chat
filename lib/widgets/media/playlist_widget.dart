import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/provider/app_data_provider.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/service/chat/chat_message.dart';
import 'package:colla_chat/service/chat/message_attachment.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/menu_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:colla_chat/tool/video_util.dart';
import 'package:colla_chat/widgets/data_bind/data_action_card.dart';
import 'package:colla_chat/widgets/data_bind/data_list_grid_view.dart';
import 'package:colla_chat/widgets/data_bind/data_listtile.dart';
import 'package:colla_chat/widgets/media/abstract_media_player_controller.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlaylistController {
  final ValueNotifier<String> currentControllerName =
      ValueNotifier<String>('/');
  late final MediaSourceController rootMediaSourceController =
      MediaSourceController(currentControllerName.value);
  late final Map<String, MediaSourceController> mediaSourceControllers = {
    rootMediaSourceController.path: rootMediaSourceController
  };

  PlaylistController();

  MediaSourceController? get currentController {
    return mediaSourceControllers[currentControllerName.value];
  }

  PlatformMediaSource? get current {
    return currentController?.current;
  }

  Rx<int?>? get currentIndex {
    return currentController?.currentIndex;
  }

  int? get length {
    return currentController?.length;
  }

  Future<void> previous() async {
    if (currentIndex?.value == null || currentIndex?.value == 0) {
      return;
    }
    currentController?.setCurrentIndex = currentIndex!.value! - 1;
  }

  Future<void> next() async {
    if (currentIndex?.value == null ||
        currentIndex!.value! >= currentController!.length - 1) {
      return;
    }
    currentController?.setCurrentIndex = currentIndex!.value! + 1;
  }

  set setCurrentIndex(int? index) {
    currentController?.setCurrentIndex = index;
  }

  void enter(PlatformMediaSource mediaSource) async {
    if (mediaSource.mediaSourceType == MediaSourceType.directory) {
      // down the directory
      MediaSourceController? controller;
      if (mediaSourceControllers.containsKey(mediaSource.filename)) {
        controller = mediaSourceControllers[mediaSource.filename]!;
      } else {
        Directory dir = Directory(mediaSource.filename);
        if (dir.existsSync()) {
          List<FileSystemEntity> entries = dir.listSync();
          if (entries.isNotEmpty) {
            List<String> filenames = [];
            for (FileSystemEntity entry in entries) {
              String path = entry.path;
              filenames.add(path);
            }
            controller = MediaSourceController(mediaSource.filename);
            controller.addMediaFile(
                filename: currentController!.path, title: '..');
            controller.addMediaFiles(filenames: filenames);
            mediaSourceControllers[mediaSource.filename] = controller;
          }
        }
      }
      if (controller != null) {
        currentControllerName.value = mediaSource.filename;
      }
    }
  }

  ///选择文件加入播放列表
  Future<void> addRootMediaSource(BuildContext context,
      {bool directory = false}) async {
    try {
      await rootMediaSourceController.sourceFilePicker(directory: directory);
    } catch (e) {
      DialogUtil.error(content: 'add media file failure:$e');
    }
  }

  Future<void> removeFromCollect(int index) async {
    PlatformMediaSource? mediaSource =
        rootMediaSourceController.delete(index: index);
    var messageId = mediaSource?.messageId;
    if (messageId != null) {
      chatMessageService.delete(where: 'messageId=?', whereArgs: [messageId]);
    }
  }

  ///将播放列表的文件加入收藏
  Future<void> collectMediaSource(int index) async {
    PlatformMediaSource? mediaSource = rootMediaSourceController.get(index);
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
    String fileType = rootMediaSourceController.fileType.name;
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

  ///从收藏的文件中加入播放列表
  Future<void> collect() async {
    String fileType = rootMediaSourceController.fileType.name;
    ChatMessageContentType? contentType =
        StringUtil.enumFromString(ChatMessageContentType.values, fileType);
    contentType = contentType ?? ChatMessageContentType.media;
    List<ChatMessage> chatMessages = await chatMessageService.findByMessageType(
      ChatMessageType.collection.name,
      contentType: contentType.name,
    );
    rootMediaSourceController.clear();
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
    rootMediaSourceController.addMediaFiles(filenames: filenames);
  }
}

/// 播放列表，data存放正在播放的媒体清单
class MediaSourceController extends DataListController<PlatformMediaSource> {
  final String path;
  late FileType _fileType;
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

  MediaSourceController(this.path, {FileType fileType = FileType.custom}) {
    this.fileType = fileType;
  }

  FileType get fileType {
    return _fileType;
  }

  set fileType(FileType fileType) {
    _fileType = fileType;
    if (fileType == FileType.custom || fileType == FileType.video) {
      allowedExtensions.addAll(videoExtensions);
    }
    if (fileType == FileType.custom || fileType == FileType.audio) {
      allowedExtensions.addAll(audioExtensions);
    }
    if (fileType == FileType.custom || fileType == FileType.image) {
      allowedExtensions.addAll(imageExtensions);
    }
  }

  bool exist(PlatformMediaSource mediaSource) {
    for (var source in data.value) {
      if (source.filename == mediaSource.filename) {
        return true;
      }
    }
    return false;
  }

  Future<void> previous() async {
    if (currentIndex.value == null || currentIndex.value == 0) {
      return;
    }
    setCurrentIndex = currentIndex.value! - 1;
  }

  Future<void> next() async {
    if (currentIndex.value == null || currentIndex.value! >= data.length - 1) {
      return;
    }
    setCurrentIndex = currentIndex.value! + 1;
  }

  Future<PlatformMediaSource?> addMediaFile(
      {required String filename,
      String? title,
      String? messageId,
      Widget? thumbnail}) async {
    for (var mediaSource in data) {
      var name = mediaSource.filename;
      if (name == filename) {
        return mediaSource;
      }
    }
    PlatformMediaSource? mediaSource =
        await PlatformMediaSource.media(filename: filename, title: title);
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

  Future<List<PlatformMediaSource>?> sourceFilePicker({
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
    if (directory) {
      String? path = await FileUtil.directoryPathPicker(
          dialogTitle: dialogTitle, initialDirectory: initialDirectory);
      if (path != null) {
        PlatformMediaSource? mediaSource = await addMediaFile(filename: path);
        if (mediaSource != null) {
          return [mediaSource];
        }
      }
    } else {
      final List<XFile>? xfiles = await FileUtil.pickFiles(
          allowMultiple: allowMultiple,
          type: _fileType,
          allowedExtensions: allowedExtensions.toList());
      if (xfiles != null && xfiles.isNotEmpty) {
        List<PlatformMediaSource>? mediaSources;
        for (var xfile in xfiles) {
          String? extension = FileUtil.extension(xfile.path);
          if (extension == null) {
            continue;
          }
          bool? contain = allowedExtensions.contains(extension);
          if (contain) {
            PlatformMediaSource? mediaSource =
                await addMediaFile(filename: xfile.path);
            if (mediaSource != null) {
              mediaSources ??= [];
              mediaSources.add(mediaSource);
            }
          }
        }

        return mediaSources;
      }
    }
    return null;
  }
}

/// 媒体文件播放列表
class PlaylistWidget extends StatelessWidget {
  final Function(int index, String filename)? onSelected;
  final PlaylistController playlistController;
  final DataListGridController dataListGridController =
      DataListGridController();

  PlaylistWidget(
      {super.key, this.onSelected, required this.playlistController}){
    playlistController.currentControllerName.addListener(_update);
    playlistController.currentIndex!.addListener(_update);
  }

  _update(){

  }

  void _buildDataTiles() {
    List<PlatformMediaSource> mediaSources =
        playlistController.currentController!.data;
    List<DataTile> dataTiles = [];
    for (var mediaSource in mediaSources) {
      var filename = mediaSource.filename;
      var title = mediaSource.title;
      var length = mediaSource.length;
      bool selected = false;
      PlatformMediaSource? current = playlistController.current;
      if (current != null) {
        if (current.filename == filename) {
          selected = true;
        }
      }
      Widget? thumbnailWidget = mediaSource.thumbnailWidget;
      DataTile tile = DataTile(
        prefix: thumbnailWidget,
        title: title,
        subtitle: length,
        selected: selected,
        onTap: (int index, String title, {String? subtitle}) async {
          PlatformMediaSource mediaSource =
              playlistController.currentController!.data[index];
          if (mediaSource.mediaSourceType == MediaSourceType.directory) {
            playlistController.currentController!.setCurrentIndex = index;
            playlistController.enter(mediaSource);
          }
          if (mediaSource.mediaSourceType == MediaSourceType.file) {
            playlistController.currentController!.setCurrentIndex = index;
          }

          return null;
        },
      );
      dataTiles.add(tile);
    }

    dataListGridController.data.assignAll(dataTiles);
  }

  Future<dynamic> showActionCard(BuildContext context) async {
    List<ActionData> actions = _buildActions(context);
    return MenuUtil.showPopActionMenu(context,
        actions: actions, width: appDataProvider.secondaryBodyWidth);
  }

  ///播放列表按钮
  List<ActionData> _buildActions(BuildContext context) {
    return [
      dataListGridController.toggleActionData,
      ActionData(
        label: 'Add directory',
        icon: Icon(
          Icons.featured_play_list_outlined,
          color: myself.primary,
        ),
        onTap: (int index, String label, {String? value}) async {
          await playlistController.addRootMediaSource(context, directory: true);
        },
        tooltip: AppLocalizations.t('Add video directory'),
      ),
      ActionData(
        label: 'Add file',
        icon: Icon(
          Icons.playlist_add,
          color: myself.primary,
        ),
        onTap: (int index, String label, {String? value}) async {
          await playlistController.addRootMediaSource(context);
        },
        tooltip: AppLocalizations.t('Add video file'),
      ),
      ActionData(
        label: 'Remove all',
        icon: Icon(
          Icons.bookmark_remove,
          color: myself.primary,
        ),
        onTap: (int index, String label, {String? value}) async {
          playlistController.rootMediaSourceController.clear();
        },
        tooltip: AppLocalizations.t('Remove all video file'),
      ),
      ActionData(
        label: 'Remove file',
        icon: Icon(
          Icons.playlist_remove,
          color: myself.primary, //myself.primary,
        ),
        onTap: (int index, String label, {String? value}) {
          var currentIndex =
              playlistController.rootMediaSourceController.currentIndex;
          playlistController.rootMediaSourceController
              .delete(index: currentIndex.value);
        },
        tooltip: AppLocalizations.t('Remove video file'),
      ),
      ActionData(
        label: 'Select',
        icon: Icon(
          Icons.video_collection,
          color: myself.primary, //myself.primary,
        ),
        onTap: (int index, String label, {String? value}) async {
          await playlistController.collect();
        },
        tooltip: AppLocalizations.t('Select collect file'),
      ),
      ActionData(
        label: 'Collect',
        icon: Icon(
          Icons.collections,
          color: myself.primary, //myself.primary,
        ),
        onTap: (int index, String label, {String? value}) async {
          int? currentIndex =
              playlistController.rootMediaSourceController.currentIndex.value;
          if (currentIndex != null) {
            await playlistController.collectMediaSource(currentIndex);
          }
        },
        tooltip: AppLocalizations.t('Collect video file'),
      ),
      ActionData(
        label: 'Remove collect',
        icon: Icon(
          Icons.bookmark_remove,
          color: myself.primary, //myself.primary,
        ),
        onTap: (int index, String label, {String? value}) async {
          var currentIndex =
              playlistController.rootMediaSourceController.currentIndex.value;
          if (currentIndex != null) {
            await playlistController.removeFromCollect(currentIndex);
          }
        },
        tooltip: AppLocalizations.t('Remove collect file'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: playlistController.currentControllerName,
        builder: (BuildContext context, Widget? child) {
          return ListenableBuilder(
              listenable: playlistController.currentIndex!,
              builder: (BuildContext context, Widget? child) {
                _buildDataTiles();
                return DataListGridView(
                    onSelected: onSelected,
                    dataListGridController: dataListGridController);
              });
        });
  }
}
