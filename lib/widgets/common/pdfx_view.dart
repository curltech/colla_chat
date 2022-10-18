import 'dart:io';

import 'package:colla_chat/platform.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfxView extends StatefulWidget {
  PdfControllerPinch? pdfPinchController;
  PdfController? pdfController;
  PdfViewerController? pdfViewerController;
  String filename;

  PdfxView({super.key, required this.filename}) {
    if (!platformParams.windows) {
      pdfPinchController = PdfControllerPinch(
        document: PdfDocument.openAsset(filename),
      );
    } else {
      pdfController = PdfController(
        document: PdfDocument.openAsset(filename),
      );
    }
    pdfViewerController = PdfViewerController();
  }

  @override
  State<PdfxView> createState() => _PdfxViewState();
}

class _PdfxViewState extends State<PdfxView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget view;
    if (widget.pdfPinchController != null) {
      view = PdfViewPinch(
        controller: widget.pdfPinchController!,
      );
    } else {
      view = PdfView(
        controller: widget.pdfController!,
      );
    }
    SfPdfViewer.file(
      File(widget.filename),
      controller: widget.pdfViewerController,
    );

    return view;
  }
}
