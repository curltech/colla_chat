import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/image_util.dart';
import 'package:colla_chat/widgets/common/app_bar_view.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:colla_chat/widgets/common/platform_future_builder.dart';
import 'package:colla_chat/widgets/common/widget_mixin.dart';
import 'package:flutter/material.dart';

import 'package:enough_mail_flutter/enough_mail_flutter.dart';

class MimeMessageAttachmentController with ChangeNotifier {
  MediaProvider? _mediaProvider;

  MediaProvider? get mediaProvider {
    return _mediaProvider;
  }

  set mediaProvider(MediaProvider? mediaProvider) {
    if (mediaProvider != _mediaProvider) {
      _mediaProvider = mediaProvider;
      notifyListeners();
    }
  }
}

final MimeMessageAttachmentController mimeMessageAttachmentController =
    MimeMessageAttachmentController();

class FullScreenAttachmentWidget extends StatefulWidget with TileDataMixin {
  const FullScreenAttachmentWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FullScreenAttachmentWidgetState();
  }

  @override
  bool get withLeading => true;

  @override
  String get routeName => 'full_screen_attachment';

  @override
  IconData get iconData => Icons.fullscreen;

  @override
  String get title => 'FullScreenAttachment';
}

class _FullScreenAttachmentWidgetState
    extends State<FullScreenAttachmentWidget> {
  @override
  void initState() {
    super.initState();
    mimeMessageAttachmentController.addListener(_update);
  }

  _update() {
    setState(() {});
  }

  Future<Widget> _buildFullScreenWidget(BuildContext context) async {
    MediaProvider? mediaProvider =
        mimeMessageAttachmentController.mediaProvider;
    if (mediaProvider != null) {
      if (mediaProvider.isImage) {
        MemoryMediaProvider memoryMediaProvider =
            await mediaProvider.toMemoryProvider();
        Widget image =
            ImageUtil.buildMemoryImageWidget(memoryMediaProvider.data);

        return Center(child: image);
      }
    }

    return nil;
  }

  @override
  Widget build(BuildContext context) {
    MediaProvider? mediaProvider =
        mimeMessageAttachmentController.mediaProvider;
    String? fileName = mediaProvider?.name;
    if (fileName != null) {
      fileName = FileUtil.filename(fileName);
    }
    return AppBarView(
      title: fileName,
      withLeading: true,
      child: PlatformFutureBuilder(
        future: _buildFullScreenWidget(context),
        builder: (BuildContext context, Widget child) {
          return child;
        },
      ),
    );
  }

  @override
  void dispose() {
    mimeMessageAttachmentController.removeListener(_update);
    super.dispose();
  }
}
