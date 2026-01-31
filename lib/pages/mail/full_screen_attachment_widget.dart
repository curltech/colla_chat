import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:enough_mail_flutter/enough_mail_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final Rx<MediaProvider?> attachmentMediaProvider = Rx<MediaProvider?>(null);

class FullScreenAttachmentWidget extends StatelessWidget with DataTileMixin {
  const FullScreenAttachmentWidget({super.key});

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'full_screen_attachment';

  @override
  IconData get iconData => Icons.fullscreen;

  @override
  String get title => 'FullScreenAttachment';

  

  Future<Widget> _buildFullScreenWidget(BuildContext context) async {
    MediaProvider? mediaProvider = attachmentMediaProvider.value;
    if (mediaProvider != null) {
      if (mediaProvider.isImage) {
        MemoryMediaProvider memoryMediaProvider =
            await mediaProvider.toMemoryProvider();
        Widget image =
            ImageUtil.buildMemoryImageWidget(memoryMediaProvider.data);

        return Center(child: image);
      }
    }

    return nilBox;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      MediaProvider? mediaProvider = attachmentMediaProvider.value;
      String? fileName = mediaProvider?.name;
      if (fileName != null) {
        fileName = FileUtil.filename(fileName);
      }
      return AppBarView(
        title: fileName,
        helpPath: routeName,
        withLeading: true,
        child: PlatformFutureBuilder(
          future: _buildFullScreenWidget(context),
          builder: (BuildContext context, Widget child) {
            return child;
          },
        ),
      );
    });
  }
}
