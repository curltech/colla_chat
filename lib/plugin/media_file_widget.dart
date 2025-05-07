import 'dart:typed_data';

import 'package:colla_chat/entity/chat/chat_message.dart';
import 'package:colla_chat/provider/data_list_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/tool/video_util.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

/// 媒体文件，比如图片或者视频文件的展示
class MediaFileWidget extends StatefulWidget {
  final DataListController<XFile> mediaFileController;

  const MediaFileWidget({super.key, required this.mediaFileController});

  @override
  MediaFileWidgetState createState() => MediaFileWidgetState();
}

class MediaFileWidgetState extends State<MediaFileWidget> {
  @override
  void initState() {
    super.initState();
  }

  _update() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildMediaImageWidget(XFile mediaFile) {
    String? mimeType = mediaFile.mimeType;
    if (mimeType == ChatMessageMimeType.jpeg.name) {
      return PlatformFutureBuilder(
        future: mediaFile.readAsBytes(),
        builder: (BuildContext context, Uint8List? data) {
          return ImageUtil.buildMemoryImageWidget(
            data!,
            height: 50,
            width: 90,
          );
        },
      );
    }
    if (mimeType == ChatMessageMimeType.mp4.name) {
      return PlatformFutureBuilder(
        future: VideoUtil.getByteThumbnail(videoFile: mediaFile.path),
        builder: (BuildContext context, Uint8List? data) {
          return ImageUtil.buildMemoryImageWidget(
            data!,
            height: 50,
            width: 90,
          );
        },
      );
    }

    return nilBox;
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
            widget.mediaFileController.setCurrentIndex = index;
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Flex(
            direction: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.ltr,
            verticalDirection: VerticalDirection.down,
            clipBehavior: Clip.none,
            children: chips,
          ),
        ),
      );
    } else {
      return nilBox;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildMediaPreviewData(context);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
