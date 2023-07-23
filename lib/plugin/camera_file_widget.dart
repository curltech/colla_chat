import 'dart:io';

import 'package:camera_macos/camera_macos_controller.dart';
import 'package:camera_macos/camera_macos_device.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_macos/camera_macos_view.dart';
import 'package:camera_macos/exceptions.dart';
import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/dialog_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/loading_util.dart';
import 'package:colla_chat/tool/video_util.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class CameraFileWidget extends StatefulWidget {
  final DataListController<XFile> mediaFileController;

  const CameraFileWidget({super.key, required this.mediaFileController});

  @override
  CameraFileWidgetState createState() => CameraFileWidgetState();
}

class CameraFileWidgetState extends State<CameraFileWidget> {
  @override
  void initState() {
    super.initState();
    widget.mediaFileController.addListener(_update);
  }

  _update() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildMediaImageWidget(XFile mediaFile) {
    String? mimeType = mediaFile.mimeType;
    if (mimeType == ChatMessageMimeType.jpeg.name) {
      return FutureBuilder(
        future: mediaFile.readAsBytes(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ImageUtil.buildMemoryImageWidget(
              snapshot.data,
              height: 50,
              width: 90,
            );
          }
          return LoadingUtil.buildLoadingIndicator();
        },
      );
    }
    if (mimeType == ChatMessageMimeType.mp4.name) {
      return FutureBuilder(
        future: VideoUtil.getByteThumbnail(videoFile: mediaFile.path),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ImageUtil.buildMemoryImageWidget(
              snapshot.data,
              height: 50,
              width: 90,
            );
          }
          return LoadingUtil.buildLoadingIndicator();
        },
      );
    }

    return Container();
  }

  /// 图片显示区
  Widget _buildMediaPreviewData(BuildContext context) {
    List<Widget> chips = [];
    int i = 0;
    for (XFile mediaFile in widget.mediaFileController.data) {
      int index = i;
      String? mimeType = mediaFile.mimeType;
      var chip = GestureDetector(
          onTap: () async {
            widget.mediaFileController.currentIndex = index;
          },
          child: Card(
            elevation: 0.0,
            margin: const EdgeInsets.all(0.0),
            shape: ContinuousRectangleBorder(
                side: widget.mediaFileController.currentIndex == index
                    ? BorderSide(width: 4.0, color: myself.primary)
                    : BorderSide.none),
            child: SizedBox(
                width: 90.0,
                child: Center(child: _buildMediaImageWidget(mediaFile))),
          ));
      chips.add(const SizedBox(
        width: 5.0,
      ));
      chips.add(chip);
      i++;
    }
    if (chips.isNotEmpty) {
      return Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            runSpacing: 5.0,
            children: chips,
          ));
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildMediaPreviewData(context);
  }

  @override
  void dispose() {
    widget.mediaFileController.removeListener(_update);
    super.dispose();
  }
}
