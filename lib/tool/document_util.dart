import 'package:flutter_filereader/flutter_filereader.dart';

class DocumentUtil {
  /// IOS docx,doc,xlsx,xls,pptx,ppt,pdf,txt,jpg,jpeg,png
  /// Android docx,doc,xlsx,xls,pptx,ppt,pdf,txt
  static FileReaderView buildFileReaderView({required String filePath}) {
    FileReaderView view = FileReaderView(
      filePath: filePath,
    );

    return view;
  }
}
