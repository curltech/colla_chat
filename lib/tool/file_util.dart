import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:full_picker/full_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileUtil {
  static Future<String> writeFile(List<int> bytes, String filename) async {
    if (!filename.contains(p.separator)) {
      final dir = await getApplicationDocumentsDirectory();
      filename = p.join(dir.path, filename);
    }
    var file = File(filename);
    bool exist = await file.exists();
    if (!exist) {
      file = await file.create(recursive: true);
    }
    await file.writeAsBytes(bytes, flush: true);

    return filename;
  }

  static Future<String?> writeTempFile(List<int> bytes,
      {String? filename, String? extension}) async {
    if (StringUtil.isEmpty(filename)) {
      final dir = await getTemporaryDirectory();
      var uuid = const Uuid();
      var name = uuid.v4();
      if (extension != null) {
        filename = p.join(dir.path, '$name.$extension');
      } else {
        filename = p.join(dir.path, name);
      }
    } else if (!filename!.contains(p.separator)) {
      final dir = await getTemporaryDirectory();
      if (extension != null) {
        filename = p.join(dir.path, '$filename.$extension');
      } else {
        filename = p.join(dir.path, filename);
      }
    }
    final file = File(filename);
    await file.writeAsBytes(bytes);
    bool exist = await file.exists();
    if (!exist) {
      return null;
    }

    return filename;
  }

  static Future<List<int>> readFile(String filename) async {
    if (filename.startsWith('assets')) {
      return await _readAssetData(filename);
    } else {
      return await _readFileBytes(filename);
    }
  }

  static Future<List<int>> _readFileBytes(String filename) async {
    // Uri uri = Uri.parse(filename);
    File file = File(filename);
    Uint8List bytes;
    bytes = await file.readAsBytes();

    return bytes;
  }

  static Future<List<int>> _readAssetData(String filename) async {
    var asset = await rootBundle.load(filename);
    return asset.buffer.asUint8List();
  }

  static Future<List<String>> pickFiles({
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
    List<String> filenames = [];
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
      for (var path in result.paths) {
        filenames.add(path!);
      }
    }

    return filenames;
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

  static Future<String?> open({
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
      title: AppLocalizations.t('Open file'),
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

  static FilesystemPickerTheme buildFilesystemPickerTheme({
    bool inherit = true,
    Color? backgroundColor,
    FilesystemPickerTopBarThemeData? topBar,
    TextStyle? messageTextStyle,
    FilesystemPickerFileListThemeData? fileList,
    FilesystemPickerActionThemeData? pickerAction,
    FilesystemPickerContextActionsThemeData? contextActions,
  }) {
    //FilesystemPickerAutoSystemTheme();
    //FilesystemPickerNewFolderContextAction();
    FilesystemPickerTheme theme = FilesystemPickerTheme(
      inherit: inherit,
      backgroundColor: backgroundColor,
      topBar: topBar,
      messageTextStyle: messageTextStyle,
      fileList: fileList,
      pickerAction: pickerAction,
      contextActions: contextActions,
    );

    return theme;
  }

  static FilesystemPickerTopBarThemeData buildFilesystemPickerTopBarThemeData({
    Color? foregroundColor,
    Color? backgroundColor,
    double? elevation,
    Color? shadowColor,
    ShapeBorder? shape,
    IconThemeData? iconTheme,
    TextStyle? titleTextStyle,
    SystemUiOverlayStyle? systemOverlayStyle,
    BreadcrumbsThemeData? breadcrumbsTheme,
  }) {
    FilesystemPickerTopBarThemeData theme = FilesystemPickerTopBarThemeData(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      shape: shape,
      iconTheme: iconTheme,
      titleTextStyle: titleTextStyle,
      systemOverlayStyle: systemOverlayStyle,
      breadcrumbsTheme: breadcrumbsTheme,
    );

    return theme;
  }

  static String? mimeType(String filename) {
    return lookupMimeType(filename);
  }

  static String extensionFromMime(String mime) {
    return extensionFromMime(mime);
  }

  static String extension(String filename) {
    int pos = filename.lastIndexOf('.');
    return filename.substring(pos + 1);
  }

  static String filename(String filename) {
    int pos = filename.lastIndexOf(p.separator);
    return filename.substring(pos + 1);
  }

  static void fullPicker({
    required BuildContext context,
    bool image = true,
    bool video = false,
    bool file = false,
    bool voiceRecorder = false,
    bool imageCamera = false,
    bool videoCamera = false,
    String prefixName = "File",
    bool videoCompressor = false,
    bool imageCropper = false,
    bool multiFile = false,
    void Function(List<String?>)? onSelectedFilenames,
    void Function(List<Uint8List?>)? onSelectedBytes,
    void Function(int)? onError,
  }) {
    Language language = Language.copy(
      camera: AppLocalizations.t('camera'),
      selectFile: AppLocalizations.t('selectFile'),
      file: AppLocalizations.t('file'),
      voiceRecorder: AppLocalizations.t('voiceRecorder'),
      gallery: AppLocalizations.t('gallery'),
      cropper: AppLocalizations.t('cropper'),
      onCompressing: AppLocalizations.t('onCompressing'),
      tapForPhotoHoldForVideo: AppLocalizations.t('tapForPhotoHoldForVideo'),
      cameraNotFound: AppLocalizations.t('cameraNotFound'),
      noVoiceRecorded: AppLocalizations.t('noVoiceRecorded'),
      denyAccessPermission: AppLocalizations.t('denyAccessPermission'),
    );
    FullPicker(
      context: context,
      language: language,
      prefixName: prefixName,
      file: file,
      image: image,
      video: video,
      videoCamera: videoCamera,
      imageCamera: imageCamera,
      voiceRecorder: voiceRecorder,
      videoCompressor: videoCompressor,
      imageCropper: imageCropper,
      multiFile: multiFile,
      onError: (int error) {
        if (onError != null) {
          onError(error);
        }
      },
      onSelected: (OutputFile file) {
        if (onSelectedFilenames != null) {
          onSelectedFilenames(file.name);
        }
        if (onSelectedBytes != null) {
          onSelectedBytes(file.bytes);
        }
      },
    );
  }
}
