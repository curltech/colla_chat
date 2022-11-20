import 'package:colla_chat/plugin/logger.dart';
import 'package:flutter/material.dart';
import 'package:open_document/my_files/my_files_screen.dart';
import 'package:open_document/open_document.dart';
import 'package:open_document/open_document_exception.dart';

class DocumentUtil {
  static openDocument({required String filePath}) async {
    final isCheck = await OpenDocument.checkDocument(filePath: filePath);

    try {
      if (isCheck) {
        await OpenDocument.openDocument(filePath: filePath);
      }
    } on OpenDocumentException catch (e) {
      logger.e("ERROR: ${e.errorMessage}");
    }
  }

  static Future<Widget> buildDocumentView({required String filePath}) async {
    return MyFilesScreen(filePath: filePath);
  }
}
