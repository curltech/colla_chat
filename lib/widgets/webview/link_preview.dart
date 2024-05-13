import 'package:any_link_preview/any_link_preview.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';

///连接link的预览
class LinkPreview extends StatefulWidget {
  final String url;

  const LinkPreview({super.key, required this.url});

  @override
  State createState() => _LinkPreviewState();
}

class _LinkPreviewState extends State<LinkPreview> {
  @override
  void initState() {
    super.initState();
    _getMetadata(widget.url);
  }

  void _getMetadata(String url) async {
    bool isValid = _getUrlValid(url);
    if (isValid) {
      Metadata? metadata = await AnyLinkPreview.getMetadata(
        link: url,
        cache: const Duration(days: 7), // Needed for web app
      );
      logger.i(metadata!.title!);
      logger.i(metadata.desc!);
    } else {
      logger.e("URL is not valid");
    }
  }

  bool _getUrlValid(String url) {
    bool isUrlValid = AnyLinkPreview.isValidLink(
      url,
      protocols: ['http', 'https'],
    );
    return isUrlValid;
  }

  @override
  Widget build(BuildContext context) {
    return AnyLinkPreview(
      link: widget.url,
      displayDirection: UIDirection.uiDirectionHorizontal,
      cache: const Duration(hours: 1),
      backgroundColor: Colors.grey[300],
      errorWidget: Container(
        color: Colors.grey,
        child: CommonAutoSizeText(AppLocalizations.t('Url loading failure')),
      ),
    );
  }
}
