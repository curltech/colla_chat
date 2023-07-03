import 'dart:io';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/platform.dart';
import 'package:colla_chat/tool/asset_util.dart';
import 'package:colla_chat/tool/path_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_selector/file_selector.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:full_picker/full_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class FileUtil {
  ///写内容到文件
  static Future<String> writeFile(List<int> bytes, String filename) async {
    if (!filename.contains(p.separator)) {
      final dir = await PathUtil.getApplicationDirectory();
      filename = p.join(dir!.path, filename);
    }
    var file = File(filename);
    bool exist = await file.exists();
    if (!exist) {
      file = await file.create(recursive: true);
    }
    await file.writeAsBytes(bytes, flush: true);

    return filename;
  }

  ///获取一个临时文件名
  static Future<String> getTempFilename(
      {String? filename, String? extension}) async {
    String tempFilename;
    if (StringUtil.isEmpty(filename)) {
      final dir = await getTemporaryDirectory();
      var uuid = const Uuid();
      var name = uuid.v4();
      if (extension != null) {
        tempFilename = p.join(dir.path, '$name.$extension');
      } else {
        tempFilename = p.join(dir.path, name);
      }
    } else {
      final dir = await getTemporaryDirectory();
      if (extension != null) {
        tempFilename = p.join(dir.path, '$filename.$extension');
      } else {
        tempFilename = p.join(dir.path, filename);
      }
    }

    return tempFilename;
  }

  ///写内容到临时文件
  static Future<String?> writeTempFile(List<int> bytes,
      {String? filename, String? extension}) async {
    String tempFilename =
        await getTempFilename(filename: filename, extension: extension);
    final file = File(tempFilename);
    bool exist = await file.exists();
    if (exist) {
      file.deleteSync();
    }
    await file.writeAsBytes(bytes, flush: true);
    exist = await file.exists();
    if (!exist) {
      return null;
    }

    return tempFilename;
  }

  ///读文件内容
  static Future<Uint8List?> readFile(String filename) async {
    if (filename.startsWith('assets')) {
      return await _readAssetData(filename);
    } else {
      return await _readFileBytes(filename);
    }
  }

  static Future<Uint8List?> _readFileBytes(String filename) async {
    // Uri uri = Uri.parse(filename);
    File file = File(filename);
    bool exists = await file.exists();
    if (exists) {
      Uint8List bytes;
      bytes = await file.readAsBytes();

      return bytes;
    }
    return null;
  }

  static Future<Uint8List> _readAssetData(String filename) async {
    var asset = await rootBundle.load(filename);
    return asset.buffer.asUint8List();
  }

  ///选择文件对话框，适用于所有的平台
  static Future<List<XFile>> pickFiles({
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
    List<XFile> xfiles = [];
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
      for (var file in result.files) {
        XFile xfile = XFile(
          file.path!,
          length: file.size,
          name: file.name,
          mimeType: file.extension,
        );
        xfiles.add(xfile);
      }
    }

    return xfiles;
  }

  ///选择文件对话框,android不适用
  static Future<List<XFile>> selectFiles({
    String? initialDirectory,
    List<String>? allowedExtensions,
    String? confirmButtonText,
  }) async {
    XTypeGroup typeGroup = XTypeGroup(
      extensions: allowedExtensions,
    );
    final List<XFile> files = await openFiles(
        initialDirectory: initialDirectory,
        acceptedTypeGroups: <XTypeGroup>[
          typeGroup,
        ]);

    return files;
  }

  ///选择目录对话框，适用于所有的平台
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

  ///保存文件对话框，适用于所有的平台
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

  ///保存文件
  static Future<String> saveFile(
    String name,
    Uint8List bytes,
    String ext, {
    MimeType mimeType = MimeType.other,
  }) async {
    return await FileSaver.instance
        .saveFile(bytes: bytes, ext: ext, mimeType: mimeType, name: name);
  }

  ///仅支持ios,android，另存为文件
  static Future<String?> saveAsFile(
    String name,
    Uint8List bytes,
    String ext, {
    MimeType mimeType = MimeType.other,
  }) async {
    return await FileSaver.instance
        .saveAs(name: name, bytes: bytes, ext: ext, mimeType: mimeType);
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

  static String? subMimeType(String mimeType) {
    int pos = mimeType.lastIndexOf('/');
    return mimeType.substring(pos + 1);
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

  ///所有平台，对移动平台选择图像或者媒体，返回List<AssetEntity>,
  ///对桌面平台，选择文件，返回List<XFile>,
  static Future<List<dynamic>> pickAssetOrFiles({
    BuildContext? context,
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.image,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    AssetPickerConfig pickerConfig = const AssetPickerConfig(),
  }) async {
    if (platformParams.desktop) {
      List<XFile> xfiles = await FileUtil.pickFiles(
          dialogTitle: dialogTitle,
          initialDirectory: initialDirectory,
          allowedExtensions: allowedExtensions,
          allowCompression: allowCompression,
          allowMultiple: allowMultiple,
          withData: withData,
          withReadStream: withReadStream,
          lockParentWindow: lockParentWindow,
          type: FileType.image);
      return xfiles;
    } else if (platformParams.mobile && context != null) {
      List<AssetEntity>? assets =
          await AssetUtil.pickAssets(context, pickerConfig: pickerConfig);
      assets = assets ?? [];

      return assets;
    }

    return [];
  }

  ///从图像，音频，录音，视频，文件系统等各种方式选择文件
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
    void Function(List<String>)? onSelectedFilenames,
    void Function(List<Uint8List>)? onSelectedBytes,
    void Function(int)? onError,
  }) {
    Language language = Language.copy(
      camera: AppLocalizations.t('camera'),
      selectFile: AppLocalizations.t('selectFile'),
      file: AppLocalizations.t('file'),
      voiceRecorder: AppLocalizations.t('voiceRecorder'),
      gallery: AppLocalizations.t('gallery'),
      cropper: AppLocalizations.t('cropper'),
      url: AppLocalizations.t('url'),
      enterURL: AppLocalizations.t('enterURL'),
      ok: AppLocalizations.t('ok'),
      cancel: AppLocalizations.t('cancel'),
      on: AppLocalizations.t('on'),
      off: AppLocalizations.t('off'),
      auto: AppLocalizations.t('auto'),
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
      onSelected: (FullPickerOutput file) {
        if (onSelectedFilenames != null) {
          if (file.name.isNotEmpty) {
            List<String> filenames = [];
            for (String? filename in file.name) {
              if (filename != null) {
                filenames.add(filename);
              }
            }
            onSelectedFilenames(filenames);
          }
        }
        if (onSelectedBytes != null) {
          if (file.bytes.isNotEmpty) {
            List<Uint8List> bytes = [];
            for (Uint8List? byte in file.bytes) {
              if (byte != null) {
                bytes.add(byte);
              }
            }
            onSelectedBytes(bytes);
          }
        }
      },
    );
  }

  static Future<Map<String, dynamic>> toJson(XFile file) async {
    Map<String, dynamic> json = {};
    json['path'] = file.path;
    json['name'] = file.name;
    json['mimeType'] = file.mimeType;
    json['length'] = file.length();
    json['lastModified'] = file.lastModified();
    var content = await file.readAsBytes();
    var base64Content = CryptoUtil.encodeBase64(content);
    json['content'] = base64Content;

    return json;
  }

  static Future<XFile> fromJson(Map<String, dynamic> json) async {
    var base64Content = json['content'];
    var content = CryptoUtil.decodeBase64(base64Content);
    var name = json['name'];
    var mimeType = json['mimeType'];
    final dir = await getTemporaryDirectory();
    if (name == null) {
      var uuid = const Uuid();
      name = '${uuid.v4()}.$mimeType';
    }
    String path = p.join(dir.path, name);
    XFile file = XFile.fromData(content,
        mimeType: json['mimeType'],
        name: json['name'],
        length: json['length'],
        lastModified: json['lastModified'],
        path: json['path']);
    file.saveTo(path);

    return file;
  }
}
