import 'dart:io';

import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:colla_chat/tool/download_file_util.dart';
import 'package:colla_chat/tool/file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

class SherpaConfigUtil {
  static String? _sherpaModelInstallationPath;

  static String? get sherpaModelInstallationPath {
    return _sherpaModelInstallationPath;
  }

  static set sherpaModelInstallationPath(String? sherpaModelInstallationPath) {
    _sherpaModelInstallationPath = sherpaModelInstallationPath;
    if (StringUtil.isNotEmpty(sherpaModelInstallationPath)) {
      localSecurityStorage.save(
          'sherpaModelInstallationPath', sherpaModelInstallationPath!);
    } else {
      localSecurityStorage.remove('sherpaModelInstallationPath');
    }
  }

  /// 产生波形wav文件名
  static Future<String> generateWaveFilename([String suffix = '']) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    DateTime now = DateTime.now();
    final filename =
        '${now.year.toString()}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}$suffix.wav';

    return p.join(directory.path, filename);
  }

  /// 列出asset文件名
  static Future<List<String>> getAllAssetFiles() async {
    final AssetManifest assetManifest =
        await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> assets = assetManifest.listAssets();

    return assets;
  }

  /// 从前开始获取分割的路径名
  static String stripLeadingDirectory(String src, {int n = 1}) {
    return p.joinAll(p.split(src).sublist(n));
  }

  static Future<void> copyAllAssetFiles() async {
    final allFiles = await getAllAssetFiles();
    for (final src in allFiles) {
      final dst = stripLeadingDirectory(src);
      await copyAssetFile(src, dst);
    }
  }

  /// 拷贝asset文件
  static Future<String> copyAssetFile(String src, [String? dst]) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    dst ??= p.basename(src);
    final target = p.join(directory.path, dst);
    bool exists = await File(target).exists();

    if (!exists) {
      final data = await rootBundle.load(src);
      final List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await (await File(target).create(recursive: true)).writeAsBytes(bytes);
    }

    return target;
  }

  static Float32List convertBytesToFloat32(Uint8List bytes,
      [endian = Endian.little]) {
    final values = Float32List(bytes.length ~/ 2);

    final data = ByteData.view(bytes.buffer);

    for (var i = 0; i < bytes.length; i += 2) {
      int short = data.getInt16(i, endian);
      values[i ~/ 2] = short / 32678.0;
    }

    return values;
  }

  /// 判断Sherpa模型是否在本地的安装
  static Future<bool> initializeSherpaModel() async {
    bool exist = false;
    String? sherpaModelInstallationPath =
        await localSecurityStorage.get('sherpaModelInstallationPath');
    if (StringUtil.isEmpty(sherpaModelInstallationPath)) {
      Directory appDir = await getApplicationDocumentsDirectory();
      _sherpaModelInstallationPath = p.join(appDir.path, 'sherpa-onnx');
      await localSecurityStorage.save(
          'sherpaModelInstallationPath', _sherpaModelInstallationPath!);
    } else {
      _sherpaModelInstallationPath = sherpaModelInstallationPath;
    }
    Directory dir = Directory(_sherpaModelInstallationPath!);
    List<FileSystemEntity> entities = dir.listSync();
    if (entities.isNotEmpty) {
      logger.i('initialize sherpa model successfully');
      return true;
    }

    return exist;
  }

  static Map<String, String> sherpaTtsModelDownloadUrl = {
    'sherpa-onnx-vits-zh-ll':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/sherpa-onnx-vits-zh-ll.tar.bz2',
    'vits-zh-aishell3':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-aishell3.tar.bz2',
    'vits-zh-hf-abyssinvoker':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-abyssinvoker.tar.bz2',
    'vits-zh-hf-bronya':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-bronya.tar.bz2',
    'vits-zh-hf-doom':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-doom.tar.bz2',
    'vits-zh-hf-echo':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-echo.tar.bz2',
    'vits-zh-hf-eula':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-eula.tar.bz2',
    'vits-zh-hf-fanchen-C':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-fanchen-C.tar.bz2',
    'vits-zh-hf-fanchen-unity':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-fanchen-unity.tar.bz2',
    'vits-zh-hf-fanchen-wnj':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-fanchen-wnj.tar.bz2',
    'vits-zh-hf-fanchen-ZhiHuiLaoZhe':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-fanchen-ZhiHuiLaoZhe.tar.bz2',
    'vits-zh-hf-fanchen-ZhiHuiLaoZhe_new':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-fanchen-ZhiHuiLaoZhe_new.tar.bz2',
    'vits-zh-hf-keqing':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-keqing.tar.bz2',
    'vits-zh-hf-theresa':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-theresa.tar.bz2',
    'vits-zh-hf-zenyatta':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-zh-hf-zenyatta.tar.bz2',
  };
  static Map<String, String> sherpaAsrModelDownloadUrl = {
    'sherpa-onnx-conformer-zh':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-conformer-zh-2023-05-23.tar.bz2',
    'sherpa-onnx-conformer-zh-stateless2':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-conformer-zh-stateless2-2023-05-23.tar.bz2',
    'sherpa-onnx-lstm-zh':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-lstm-zh-2023-02-20.tar.bz2',
    'sherpa-onnx-paraformer-zh':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-paraformer-zh-2024-03-09.tar.bz2',
    'sherpa-onnx-paraformer-zh-small':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-paraformer-zh-small-2024-03-09.tar.bz2',
    'sherpa-onnx-streaming-conformer-zh':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-conformer-zh-2023-05-23.tar.bz2',
    'sherpa-onnx-streaming-paraformer-bilingual-zh-en':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2',
    'sherpa-onnx-streaming-paraformer-trilingual-zh-cantonese-en':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-paraformer-trilingual-zh-cantonese-en.tar.bz2',
    'sherpa-onnx-streaming-zipformer-ctc-multi-zh-hans':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-ctc-multi-zh-hans-2023-12-13.tar.bz2',
    'sherpa-onnx-streaming-zipformer-multi-zh-hans':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-multi-zh-hans-2023-12-12.tar.bz2',
    'sherpa-onnx-streaming-zipformer-small-bilingual-zh-en':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-small-bilingual-zh-en-2023-02-16.tar.bz2',
    'sherpa-onnx-streaming-zipformer-zh-14M':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-zh-14M-2023-02-23.tar.bz2',
    'sherpa-onnx-telespeech-ctc-zh':
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-telespeech-ctc-zh-2024-06-04.tar.bz2',
  };

  /// 下载并安装中文asr或者tts模型
  static Future<bool> setupSherpaModel(
    String modelName, {
    CancelToken? cancelToken,
    void Function(DownloadProgress progress)? onProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    bool exist = await initializeSherpaModel();
    if (exist) {
      return true;
    }
    Directory tempDir = await getTemporaryDirectory();
    String tempFolderPath = p.join(tempDir.path, 'sherpa-onnx');
    tempDir = Directory(tempFolderPath);
    if (await tempDir.exists() == false) {
      await tempDir.create(recursive: true);
    }
    Directory installationDir = Directory(_sherpaModelInstallationPath!);
    if (await installationDir.exists() == false) {
      await installationDir.create(recursive: true);
    }
    String? modelFilename;
    String? downloadUrl = sherpaAsrModelDownloadUrl[modelName];
    if (downloadUrl != null) {
      modelFilename = FileUtil.filename(downloadUrl);
    } else {
      downloadUrl = sherpaTtsModelDownloadUrl[modelName];
      if (downloadUrl != null) {
        modelFilename = FileUtil.filename(downloadUrl);
      }
    }
    if (modelFilename == null) {
      logger.e('modelFilename is not exist');
      return false;
    }
    final String ttsModelZipPath = p.join(tempFolderPath, modelFilename);
    final File tempZipFile = File(ttsModelZipPath);
    if (await tempZipFile.exists() == false) {
      try {
        Dio dio = Dio();
        Response response = await dio.download(
          downloadUrl!,
          ttsModelZipPath,
          cancelToken: cancelToken,
          onReceiveProgress: (int received, int total) {
            onProgress?.call(DownloadProgress(
              downloaded: received,
              fileSize: total,
              phase: DownloadProgressPhase.downloading,
            ));
          },
          queryParameters: queryParameters,
        );
        if (response.statusCode == HttpStatus.ok) {
          onProgress?.call(DownloadProgress(
            downloaded: 0,
            fileSize: 0,
            phase: DownloadProgressPhase.decompressing,
          ));
          await compute(DownloadFileUtil.extractZipFileIsolate, {
            'zipFile': tempZipFile.path,
            'targetPath': _sherpaModelInstallationPath,
          });
          onProgress?.call(DownloadProgress(
            downloaded: 0,
            fileSize: 0,
            phase: DownloadProgressPhase.inactive,
          ));
          return true;
        } else {
          onProgress?.call(DownloadProgress(
            downloaded: 0,
            fileSize: 0,
            phase: DownloadProgressPhase.inactive,
          ));
          return false;
        }
      } catch (e) {
        onProgress?.call(DownloadProgress(
          downloaded: 0,
          fileSize: 0,
          phase: DownloadProgressPhase.inactive,
        ));
        return false;
      }
    } else {
      onProgress?.call(DownloadProgress(
        downloaded: 0,
        fileSize: 0,
        phase: DownloadProgressPhase.decompressing,
      ));
      try {
        await compute(DownloadFileUtil.extractZipFileIsolate, {
          'zipFile': tempZipFile.path,
          'targetPath': _sherpaModelInstallationPath,
        });
        onProgress?.call(DownloadProgress(
          downloaded: 0,
          fileSize: 0,
          phase: DownloadProgressPhase.inactive,
        ));
        return true;
      } catch (e) {
        onProgress?.call(DownloadProgress(
          downloaded: 0,
          fileSize: 0,
          phase: DownloadProgressPhase.inactive,
        ));
        return false;
      }
    }
  }

  /// 创建离线的TTS,以sherpa-onnx-vits-zh-ll为中文例子
  static Future<OfflineTts> createOfflineTts(
      {String modelPath = 'sherpa-onnx-vits-zh-ll'}) async {
    initBindings();

    String modelFilename =
        p.join(_sherpaModelInstallationPath!, modelPath, 'model.onnx');
    String lexicon =
        p.join(_sherpaModelInstallationPath!, modelPath, 'lexiconFilename.txt');
    String dataDir = p.join(_sherpaModelInstallationPath!, modelPath, '');
    String dictDir = p.join(_sherpaModelInstallationPath!, modelPath, 'dict');
    final String tokens =
        p.join(_sherpaModelInstallationPath!, modelPath, 'tokens.txt');

    String ruleFstFilenames = 'phone.fst,date.fst,number.fst';
    if (ruleFstFilenames != '') {
      final all = ruleFstFilenames.split(',');
      var tmp = <String>[];
      for (final f in all) {
        tmp.add(p.join(_sherpaModelInstallationPath!, modelPath, f));
      }
      ruleFstFilenames = tmp.join(',');
    }

    String ruleFars = '';
    if (ruleFars != '') {
      final all = ruleFars.split(',');
      var tmp = <String>[];
      for (final f in all) {
        tmp.add(p.join(_sherpaModelInstallationPath!, modelPath, f));
      }
      ruleFars = tmp.join(',');
    }

    final vits = OfflineTtsVitsModelConfig(
      model: modelFilename,
      lexicon: lexicon,
      tokens: tokens,
      dataDir: dataDir,
      dictDir: dictDir,
    );

    final modelConfig = OfflineTtsModelConfig(
      vits: vits,
      numThreads: 2,
      debug: true,
      provider: 'cpu',
    );

    final config = OfflineTtsConfig(
      model: modelConfig,
      ruleFsts: ruleFstFilenames,
      ruleFars: ruleFars,
      maxNumSenetences: 1,
    );

    final OfflineTts tts = OfflineTts(config);

    return tts;
  }

  static Future<OnlineRecognizer> createOnlineRecognizer(
      {String modelPath = 'sherpa-onnx-conformer-zh'}) async {
    final String encoder =
        p.join(_sherpaModelInstallationPath!, modelPath, 'encoder.onnx');
    final String decoder =
        p.join(_sherpaModelInstallationPath!, modelPath, 'decoder.onnx');
    final String joiner =
        p.join(_sherpaModelInstallationPath!, modelPath, 'joiner.onnx');
    final String tokens =
        p.join(_sherpaModelInstallationPath!, modelPath, 'tokens.txt');
    final String ruleFsts =
        p.join(_sherpaModelInstallationPath!, modelPath, 'number.fst');

    final OnlineTransducerModelConfig transducer = OnlineTransducerModelConfig(
      encoder: encoder,
      decoder: decoder,
      joiner: joiner,
    );

    final OnlineModelConfig modelConfig = OnlineModelConfig(
      transducer: transducer,
      tokens: tokens,
      debug: true,
      numThreads: 1,
    );
    final OnlineRecognizerConfig config = OnlineRecognizerConfig(
      model: modelConfig,
      ruleFsts: ruleFsts,
    );
    final OnlineRecognizer recognizer = OnlineRecognizer(config);

    return recognizer;
  }

  static Future<OfflineRecognizer> createOfflineRecognizer(
      {String modelPath = 'sherpa-onnx-conformer-zh'}) async {
    final String encoder =
        p.join(_sherpaModelInstallationPath!, modelPath, 'encoder.onnx');
    final String decoder =
        p.join(_sherpaModelInstallationPath!, modelPath, 'decoder.onnx');
    final String joiner =
        p.join(_sherpaModelInstallationPath!, modelPath, 'joiner.onnx');
    final String tokens =
        p.join(_sherpaModelInstallationPath!, modelPath, 'tokens.txt');

    final OfflineTransducerModelConfig transducer =
        OfflineTransducerModelConfig(
      encoder: encoder,
      decoder: decoder,
      joiner: joiner,
    );

    final OfflineModelConfig modelConfig = OfflineModelConfig(
      transducer: transducer,
      tokens: tokens,
      debug: true,
      numThreads: 1,
    );
    final OfflineRecognizerConfig config =
        OfflineRecognizerConfig(model: modelConfig);
    final OfflineRecognizer recognizer = OfflineRecognizer(config);

    return recognizer;
  }
}
