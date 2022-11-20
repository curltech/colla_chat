import 'package:flutter_filereader/flutter_filereader.dart';

class DocumentUtil {
  /// IOS docx,doc,xlsx,xls,pptx,ppt,pdf,txt,jpg,jpeg,png
  /// Android docx,doc,xlsx,xls,pptx,ppt,pdf,txt
  static buildFileReaderView({required String filePath}) async {
    return FileReaderView(
      filePath: filePath,
    );
  }
}
