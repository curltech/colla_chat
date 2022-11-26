import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/platform.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfUtil {
  ///读取pdf文件
  static Future<PdfDocument>? buildPdfDocument(
      {String? filename, FutureOr<Uint8List>? data}) {
    Future<PdfDocument>? pdfDocument;
    if (filename != null) {
      if (filename.startsWith('assets')) {
        pdfDocument = PdfDocument.openAsset(filename);
      } else {
        pdfDocument = PdfDocument.openFile(filename);
      }
    } else if (data != null) {
      pdfDocument = PdfDocument.openData(data);
    }

    return pdfDocument;
  }

  static BasePdfController? buildPdfController(
      {String? filename, FutureOr<Uint8List>? data}) {
    BasePdfController? pdfController;
    Future<PdfDocument>? pdfDocument =
        buildPdfDocument(filename: filename, data: data);
    if (pdfDocument != null) {
      if (!platformParams.windows) {
        pdfController = PdfControllerPinch(
          document: pdfDocument,
        );
      } else {
        pdfController = PdfController(
          document: pdfDocument,
        );
      }
    }

    return pdfController;
  }

  static Widget buildPdfView(
      {Key? key, String? filename, FutureOr<Uint8List>? data}) {
    BasePdfController? pdfController =
        buildPdfController(filename: filename, data: data);
    Widget? view;
    if (pdfController != null) {
      if (pdfController is PdfControllerPinch) {
        view = PdfViewPinch(
          key: key,
          controller: pdfController,
        );
      } else if (pdfController is PdfController) {
        view = PdfView(
          key: key,
          controller: pdfController,
        );
      }
    }
    view = view ?? Container();

    return view;
  }

  static Widget buildPdfWidget(
      {Key? key, required BasePdfController pdfController}) {
    Widget? view;
    if (pdfController is PdfControllerPinch) {
      view = PdfViewPinch(
        key: key,
        controller: pdfController,
      );
    } else if (pdfController is PdfController) {
      view = PdfView(
        key: key,
        controller: pdfController,
      );
    }
    view = view ?? Container();

    return view;
  }
}
