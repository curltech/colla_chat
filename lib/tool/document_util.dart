import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/platform_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_filereader/flutter_filereader.dart';

class DocumentUtil {
  /// IOS docx,doc,xlsx,xls,pptx,ppt,pdf,txt,jpg,jpeg,png
  /// Android docx,doc,xlsx,xls,pptx,ppt,pdf,txt
  static Widget buildFileReaderView({Key? key, required String filePath}) {
    if (platformParams.mobile) {
      FileReaderView view = FileReaderView(
        key: key,
        filePath: filePath,
      );

      return view;
    } else {
      return PlatformWebView(initialUrl: filePath);
    }
  }
}
