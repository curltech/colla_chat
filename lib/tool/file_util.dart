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
  static Future<String> writeFileAsBytes(
      List<int> bytes, String filename) async {
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

  static Future<String> writeFileAsString(String str, String filename) async {
    if (!filename.contains(p.separator)) {
      final dir = await PathUtil.getApplicationDirectory();
      filename = p.join(dir!.path, filename);
    }
    var file = File(filename);
    bool exist = await file.exists();
    if (!exist) {
      file = await file.create(recursive: true);
    }
    file.writeAsStringSync(str, flush: true);

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
  static Future<String?> writeTempFileAsBytes(List<int> bytes,
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

  static Future<String?> writeTempFileAsString(String str,
      {String? filename, String? extension}) async {
    String tempFilename =
        await getTempFilename(filename: filename, extension: extension);
    final file = File(tempFilename);
    bool exist = await file.exists();
    if (exist) {
      file.deleteSync();
    }
    file.writeAsStringSync(str, flush: true);
    exist = await file.exists();
    if (!exist) {
      return null;
    }

    return tempFilename;
  }

  ///读文件内容
  static Future<Uint8List?> readFileAsBytes(String filename) async {
    if (filename.startsWith('assets')) {
      return await _readAssetData(filename);
    } else {
      return await _readFileBytes(filename);
    }
  }

  static Future<Uint8List?> _readFileBytes(String filename) async {
    File file = File(filename);
    bool exists = await file.exists();
    if (exists) {
      Uint8List bytes = file.readAsBytesSync();

      return bytes;
    }
    return null;
  }

  static Future<Uint8List> _readAssetData(String filename) async {
    var asset = await rootBundle.load(filename);
    return asset.buffer.asUint8List();
  }

  static Future<String?> readFileAsString(String filename) async {
    File file = File(filename);
    bool exists = await file.exists();
    if (exists) {
      Uint8List bytes;
      return file.readAsStringSync();
    }
    return null;
  }

  /// 使用原生的选择文件对话框，适用于所有的平台，在ios平台上只能访问
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
    if (initialDirectory == null) {
      Directory dir = await PathUtil.getApplicationDocumentsDirectory();
      initialDirectory = dir.path;
    }
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
    if (initialDirectory == null) {
      Directory? dir = await PathUtil.getApplicationDirectory();
      initialDirectory = dir?.path;
    }
    if (platformParams.android) {
      return await pickFiles(
          initialDirectory: initialDirectory,
          type: FileType.custom,
          allowedExtensions: allowedExtensions);
    }
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

  /// 自定义的界面在文件系统中打开单个文件
  static Future<XFile?> open({
    required BuildContext context,
    Directory? rootDirectory,
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
    List<FilesystemPickerShortcut> shortcuts = [
      FilesystemPickerShortcut(
          name: 'Documents',
          path: await PathUtil.getApplicationDocumentsDirectory(),
          icon: Icons.snippet_folder),
      FilesystemPickerShortcut(
          name: 'Temporary', path: await PathUtil.getTemporaryDirectory()),
      FilesystemPickerShortcut(
          name: 'Library',
          path: await PathUtil.getLibraryDirectory(),
          icon: Icons.snippet_folder),
      FilesystemPickerShortcut(
          name: 'Support',
          path: await PathUtil.getApplicationSupportDirectory(),
          icon: Icons.snippet_folder),
    ];
    Directory? downloadsDirectory = await PathUtil.getDownloadsDirectory();
    if (downloadsDirectory != null) {
      shortcuts.add(
        FilesystemPickerShortcut(name: 'Downloads', path: downloadsDirectory),
      );
    }
    Directory? externalStorageDirectory =
        await PathUtil.getExternalStorageDirectory();
    if (externalStorageDirectory != null) {
      shortcuts.add(
        FilesystemPickerShortcut(
            name: 'ExternalStorage', path: externalStorageDirectory),
      );
    }
    if (rootDirectory == null) {
      if (platformParams.windows) {
        rootDirectory = Directory('C:/');
      } else {
        rootDirectory = Directory('/');
      }
    }
    shortcuts.add(
      FilesystemPickerShortcut(name: 'Root', path: rootDirectory),
    );
    String? path = await FilesystemPicker.open(
      title: AppLocalizations.t('Open file'),
      context: context,
      directory: directory,
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
      shortcuts: shortcuts,
    );
    if (path != null) {
      return XFile(path);
    }

    return null;
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

  ///根据文件名获取类型
  static String? mimeType(String filename) {
    return lookupMimeType(filename);
  }

  ///image/jpeg的子类型，image
  static String mainMimeType(String mimeType) {
    int pos = mimeType.lastIndexOf('/');
    return mimeType.substring(0, pos);
  }

  ///image/jpeg的子类型，jpeg
  static String subMimeType(String mimeType) {
    int pos = mimeType.lastIndexOf('/');
    return mimeType.substring(pos + 1);
  }

  ///image/jpeg的子类型，jpeg
  static String extensionFromMime(String mime) {
    return subMimeType(mime);
  }

  ///获取扩展名
  static String? extension(String filename) {
    int pos = filename.lastIndexOf(p.separator);
    int dotPos = filename.lastIndexOf('.');
    if (dotPos > pos) {
      return filename.substring(dotPos + 1);
    }
    return null;
  }

  ///获取全路径下的文件名部分
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

  ///各种文件的输入方式，文件采用pickFiles
  ///在macos下相机不能用，layout也有问题
  static Future<List<String>?> fullSelectFiles({
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
  }) async {
    List<String>? filenames;
    fullPicker(
        context: context,
        image: image,
        video: video,
        file: file,
        voiceRecorder: voiceRecorder,
        imageCamera: imageCamera,
        videoCamera: videoCamera,
        videoCompressor: videoCompressor,
        prefixName: prefixName,
        imageCropper: imageCropper,
        multiFile: multiFile,
        onSelectedFilenames: (fs) async {
          filenames = fs;
        });

    return filenames;
  }

  static Future<List<Uint8List>?> fullSelectBytes({
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
  }) async {
    List<Uint8List>? data;
    fullPicker(
        context: context,
        image: image,
        video: video,
        file: file,
        voiceRecorder: voiceRecorder,
        imageCamera: imageCamera,
        videoCamera: videoCamera,
        prefixName: prefixName,
        videoCompressor: videoCompressor,
        imageCropper: imageCropper,
        multiFile: multiFile,
        onSelectedBytes: (bytes) async {
          data = bytes;
        });

    return data;
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
    FullPickerLanguage language = FullPickerLanguage.copy(
      camera: AppLocalizations.t('Camera'),
      selectFile: AppLocalizations.t('SelectFile'),
      file: AppLocalizations.t('File'),
      voiceRecorder: AppLocalizations.t('VoiceRecorder'),
      gallery: AppLocalizations.t('Gallery'),
      cropper: AppLocalizations.t('Cropper'),
      url: AppLocalizations.t('Url'),
      enterURL: AppLocalizations.t('EnterURL'),
      ok: AppLocalizations.t('Ok'),
      cancel: AppLocalizations.t('Cancel'),
      on: AppLocalizations.t('On'),
      off: AppLocalizations.t('Off'),
      auto: AppLocalizations.t('Auto'),
      onCompressing: AppLocalizations.t('OnCompressing'),
      tapForPhotoHoldForVideo: AppLocalizations.t('TapForPhotoHoldForVideo'),
      cameraNotFound: AppLocalizations.t('CameraNotFound'),
      noVoiceRecorded: AppLocalizations.t('NoVoiceRecorded'),
      denyAccessPermission: AppLocalizations.t('DenyAccessPermission'),
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
      onSelected: (FullPickerOutput fileOut) {
        if (onSelectedFilenames != null) {
          List<File?> files = fileOut.file;
          if (files.isNotEmpty) {
            List<String> filenames = [];
            for (File? file in files) {
              if (file != null) {
                filenames.add(file.path);
              }
            }
            onSelectedFilenames(filenames);
          }
        }
        if (onSelectedBytes != null) {
          List<Uint8List?> fileBytes = fileOut.bytes;
          if (fileBytes.isNotEmpty) {
            List<Uint8List> bytes = [];
            for (Uint8List? byte in fileBytes) {
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
