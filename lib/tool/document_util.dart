import 'package:flutter/material.dart';
import 'package:flutter_filereader/flutter_filereader.dart';

class DocumentUtil {
  /// IOS docx,doc,xlsx,xls,pptx,ppt,pdf,txt,jpg,jpeg,png
  /// Android docx,doc,xlsx,xls,pptx,ppt,pdf,txt
  static FileReaderView buildFileReaderView(
      {Key? key, required String filePath}) {
    FileReaderView view = FileReaderView(
      key: key,
      filePath: filePath,
    );

    return view;
  }
}
