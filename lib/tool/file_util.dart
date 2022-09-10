import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FileUtil {
  static Future<File> writeFile(Uint8List bytes, String name) async {
    final document = await getApplicationDocumentsDirectory();
    final dir = Directory(document.path + name);
    final imageFile = File(dir.path);
    await imageFile.writeAsBytes(bytes);

    return imageFile;
  }

  static Future<Uint8List> readFile(String filename) async {
    if (filename.startsWith('asset')) {
      return await _readAssetData(filename);
    } else {
      return await _readFileBytes(filename);
    }
  }

  static Future<Uint8List> _readFileBytes(String filename) async {
    Uri uri = Uri.parse(filename);
    File file = File.fromUri(uri);
    Uint8List bytes;
    bytes = await file.readAsBytes();

    return bytes;
  }

  static Future<Uint8List> _readAssetData(String filename) async {
    var asset = await rootBundle.load(filename);
    return asset.buffer.asUint8List();
  }

  static Future<List<File>?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) async {
    List<File> files = [];
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      allowCompression: allowCompression,
      allowMultiple: allowMultiple,
      withData: withData,
      withReadStream: withReadStream,
      lockParentWindow: lockParentWindow,
    );

    if (result != null) {
      if (allowMultiple) {
        List<PlatformFile> platformFiles = result.files;
        for (var path in result.paths) {
          File file = File(path!);
          files.add(file);
        }
      } else {
        File file = File(result.files.single.path!);
        files.add(file);
      }
    } else {
      // User canceled the picker
    }

    return files;
  }

  static Future<String?> directoryPathPicker({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle,
        lockParentWindow: lockParentWindow,
        initialDirectory: initialDirectory);

    if (selectedDirectory == null) {
      // User canceled the picker
    }

    return selectedDirectory;
  }

  ///不支持ios,android,web
  static Future<String?> saveFilePicker({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool lockParentWindow = false,
  }) async {
    String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        initialDirectory: initialDirectory,
        type: type,
        allowedExtensions: allowedExtensions,
        lockParentWindow: lockParentWindow);

    if (outputFile == null) {
      // User canceled the picker
    }

    return outputFile;
  }

  static Future<String> saveFile(
    String name,
    Uint8List bytes,
    String ext, {
    MimeType mimeType = MimeType.OTHER,
  }) async {
    return await FileSaver.instance
        .saveFile(name, bytes, ext, mimeType: mimeType);
  }

  ///仅支持ios,android
  static Future<String> saveAsFile(
    String name,
    Uint8List bytes,
    String ext, {
    MimeType mimeType = MimeType.OTHER,
  }) async {
    return await FileSaver.instance.saveAs(name, bytes, ext, mimeType);
  }

  Future<String?> open({
    required BuildContext context,
    required Directory rootDirectory,
    String? rootName,
    Directory? directory,
    FilesystemType? fsType,
    String? pickText,
    String? permissionText,
    String? title,
    Color? folderIconColor,
    bool? showGoUp,
    List<String>? allowedExtensions,
    bool? caseSensitiveFileExtensionComparison,
    FileTileSelectMode? fileTileSelectMode,
    Future<bool> Function()? requestPermission,
    bool Function(FileSystemEntity, String, String)? itemFilter,
    FilesystemPickerThemeBase? theme,
    List<FilesystemPickerContextAction> contextActions = const [],
  }) async {
    String? path = await FilesystemPicker.open(
      title: 'Open file',
      context: context,
      rootDirectory: rootDirectory,
      fsType: fsType,
      allowedExtensions: allowedExtensions,
      fileTileSelectMode: fileTileSelectMode,
      permissionText: permissionText,
      pickText: pickText,
      contextActions: contextActions,
      showGoUp: showGoUp,
      folderIconColor: folderIconColor,
      theme: theme,
      itemFilter: itemFilter,
      requestPermission: requestPermission,
    );

    return path;
  }
}
