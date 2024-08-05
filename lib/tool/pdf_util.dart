import 'dart:async';
import 'dart:typed_data';

import 'package:colla_chat/platform.dart';
import 'package:colla_chat/widgets/common/nil.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

///显示pdf文件
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

  ///读取pdf文件，创建pdf控制器
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

  ///读取pdf文件，创建pdf控制器，创建pdf显示视图
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
    view = view ?? nil;

    return view;
  }

  ///根据控制器，创建pdf视图
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
    view = view ?? nil;

    return view;
  }

  ///转换html字符串为pdf数据
  // static Future<Uint8List> convertHtml(String html) async {
  //   return await Printing.convertHtml(
  //     format: pdf.PdfPageFormat.standard,
  //     html: html,
  //   );
  // }

  ///显示pdf数据
  // static PdfPreview buildPdfPreview({
  //   Key? key,
  //   FutureOr<Uint8List> Function(pdf.PdfPageFormat)? build,
  //   Uint8List? data,
  //   pdf.PdfPageFormat? initialPageFormat,
  //   bool allowPrinting = true,
  //   bool allowSharing = true,
  //   double? maxPageWidth,
  //   bool canChangePageFormat = true,
  //   bool canChangeOrientation = true,
  //   bool canDebug = true,
  //   List<Widget>? actions,
  //   Map<String, pdf.PdfPageFormat> pageFormats =
  //       const <String, pdf.PdfPageFormat>{
  //     'A4': pdf.PdfPageFormat.a4,
  //     'Letter': pdf.PdfPageFormat.letter,
  //   },
  //   Widget Function(BuildContext, Object)? onError,
  //   void Function(BuildContext)? onPrinted,
  //   void Function(BuildContext, dynamic)? onPrintError,
  //   void Function(BuildContext)? onShared,
  //   Decoration? scrollViewDecoration,
  //   Decoration? pdfPreviewPageDecoration,
  //   String? pdfFileName,
  //   bool useActions = true,
  //   List<int>? pages,
  //   bool dynamicLayout = true,
  //   String? shareActionExtraBody,
  //   String? shareActionExtraSubject,
  //   List<String>? shareActionExtraEmails,
  //   EdgeInsets? previewPageMargin,
  //   EdgeInsets? padding,
  //   bool shouldRepaint = false,
  //   Widget? loadingWidget,
  //   void Function(pdf.PdfPageFormat)? onPageFormatChanged,
  //   double? dpi,
  // }) {
  //   if (build == null && data != null) {
  //     build = (pdf.PdfPageFormat format) {
  //       return data;
  //     };
  //   }
  //   return PdfPreview(
  //     key: key,
  //     build: build!,
  //     initialPageFormat: initialPageFormat,
  //     allowPrinting: allowPrinting,
  //     allowSharing: allowSharing,
  //     maxPageWidth: maxPageWidth,
  //     canChangePageFormat: canChangePageFormat,
  //     canChangeOrientation: canChangeOrientation,
  //     canDebug: canDebug,
  //     actions: actions,
  //     pageFormats: pageFormats,
  //     onError: onError,
  //     onPrinted: onPrinted,
  //     onPrintError: onPrintError,
  //     onShared: onShared,
  //     scrollViewDecoration: scrollViewDecoration,
  //     pdfPreviewPageDecoration: pdfPreviewPageDecoration,
  //     pdfFileName: pdfFileName,
  //     useActions: useActions,
  //     pages: pages,
  //     dynamicLayout: dynamicLayout,
  //     shareActionExtraBody: shareActionExtraBody,
  //     shareActionExtraSubject: shareActionExtraSubject,
  //     shareActionExtraEmails: shareActionExtraEmails,
  //     previewPageMargin: previewPageMargin,
  //     padding: padding,
  //     shouldRepaint: shouldRepaint,
  //     loadingWidget: loadingWidget,
  //     onPageFormatChanged: onPageFormatChanged,
  //     dpi: dpi,
  //   );
  // }
}
