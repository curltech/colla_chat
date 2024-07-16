import 'dart:io';
import 'dart:typed_data';

import 'package:colla_chat/plugin/security_storage.dart';
import 'package:colla_chat/tool/download_file_util.dart';
import 'package:colla_chat/tool/string_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

class SherpaConfigUtil {
  static String? _ttsModelInstallationPath;

  static String? get ttsModelInstallationPath {
    return _ttsModelInstallationPath;
  }

  static set ttsModelInstallationPath(String? ttsModelInstallationPath) {
    _ttsModelInstallationPath = ttsModelInstallationPath;
    if (StringUtil.isNotEmpty(ttsModelInstallationPath)) {
      localSecurityStorage.save(
          'ttsModelInstallationPath', ttsModelInstallationPath!);
    } else {
      localSecurityStorage.remove('ttsModelInstallationPath');
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

  /// 下载模型文件到../assets
  static Future<OnlineModelConfig> getOnlineModelConfig(
      {required int type}) async {
    switch (type) {
      case 0:
        const modelDir =
            'assets/sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20';
        return OnlineModelConfig(
          transducer: OnlineTransducerModelConfig(
            encoder: await copyAssetFile(
                '$modelDir/encoder-epoch-99-avg-1.int8.onnx'),
            decoder:
                await copyAssetFile('$modelDir/decoder-epoch-99-avg-1.onnx'),
            joiner: await copyAssetFile('$modelDir/joiner-epoch-99-avg-1.onnx'),
          ),
          tokens: await copyAssetFile('$modelDir/tokens.txt'),
          modelType: 'zipformer',
        );
      case 1:
        const modelDir = 'assets/sherpa-onnx-streaming-zipformer-en-2023-06-26';
        return OnlineModelConfig(
          transducer: OnlineTransducerModelConfig(
            encoder: await copyAssetFile(
                '$modelDir/encoder-epoch-99-avg-1-chunk-16-left-128.int8.onnx'),
            decoder: await copyAssetFile(
                '$modelDir/decoder-epoch-99-avg-1-chunk-16-left-128.onnx'),
            joiner: await copyAssetFile(
                '$modelDir/joiner-epoch-99-avg-1-chunk-16-left-128.onnx'),
          ),
          tokens: await copyAssetFile('$modelDir/tokens.txt'),
          modelType: 'zipformer2',
        );
      case 2:
        const modelDir =
            'assets/icefall-asr-zipformer-streaming-wenetspeech-20230615';
        return OnlineModelConfig(
          transducer: OnlineTransducerModelConfig(
            encoder: await copyAssetFile(
                '$modelDir/exp/encoder-epoch-12-avg-4-chunk-16-left-128.int8.onnx'),
            decoder: await copyAssetFile(
                '$modelDir/exp/decoder-epoch-12-avg-4-chunk-16-left-128.onnx'),
            joiner: await copyAssetFile(
                '$modelDir/exp/joiner-epoch-12-avg-4-chunk-16-left-128.onnx'),
          ),
          tokens: await copyAssetFile('$modelDir/data/lang_char/tokens.txt'),
          modelType: 'zipformer2',
        );
      case 3:
        const modelDir = 'assets/sherpa-onnx-streaming-zipformer-fr-2023-04-14';
        return OnlineModelConfig(
          transducer: OnlineTransducerModelConfig(
            encoder: await copyAssetFile(
                '$modelDir/encoder-epoch-29-avg-9-with-averaged-model.int8.onnx'),
            decoder: await copyAssetFile(
                '$modelDir/decoder-epoch-29-avg-9-with-averaged-model.onnx'),
            joiner: await copyAssetFile(
                '$modelDir/joincoder-epoch-29-avg-9-with-averaged-model.onnx'),
          ),
          tokens: await copyAssetFile('$modelDir/tokens.txt'),
          modelType: 'zipformer',
        );
      default:
        throw ArgumentError('Unsupported type: $type');
    }
  }

  /// 初始化tts模型的安装目录
  static Future<bool> initializeTtsModel() async {
    bool exist = false;
    String? ttsModelInstallationPath =
        await localSecurityStorage.get('ttsModelInstallationPath');
    if (StringUtil.isEmpty(ttsModelInstallationPath)) {
      Directory appDir = await getApplicationDocumentsDirectory();
      _ttsModelInstallationPath = p.join(appDir.path, 'sherpa-onnx');
      await localSecurityStorage.save(
          'ttsModelInstallationPath', _ttsModelInstallationPath!);
    } else {
      _ttsModelInstallationPath = ttsModelInstallationPath;
    }
    File model = File(p.join(_ttsModelInstallationPath!, 'model.onnx'));
    if ((await model.exists())) {
      exist = true;
    }

    return exist;
  }

  static Future<bool> setupTtsModel({
    CancelToken? cancelToken,
    void Function(DownloadProgress progress)? onProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    bool exist = await initializeTtsModel();
    if (exist) {
      return true;
    }
    Directory tempDir = await getTemporaryDirectory();
    String tempFolderPath = p.join(tempDir.path, 'sherpa-onnx');
    tempDir = Directory(tempFolderPath);
    if (await tempDir.exists() == false) {
      await tempDir.create(recursive: true);
    }
    Directory installationDir = Directory(_ttsModelInstallationPath!);
    if (await installationDir.exists() == false) {
      await installationDir.create(recursive: true);
    }
    final String ttsModelZipPath =
        p.join(tempFolderPath, "sherpa-onnx-vits-zh-ll.tar.bz2");
    final File tempZipFile = File(ttsModelZipPath);
    if (await tempZipFile.exists() == false) {
      try {
        Dio dio = Dio();
        Response response = await dio.download(
          'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/sherpa-onnx-vits-zh-ll.tar.bz2',
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
            'targetPath': _ttsModelInstallationPath,
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
          'targetPath': _ttsModelInstallationPath,
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
  static Future<OfflineTts> createOfflineTts() async {
    initBindings();
    String modelName = 'model.onnx';
    String ruleFsts =
        'sherpa-onnx-vits-zh-ll/phone.fst,sherpa-onnx-vits-zh-ll/date.fst,./sherpa-onnx-vits-zh-ll/number.fst';
    String ruleFars = '';
    String lexicon = 'lexicon.txt';
    String dataDir = '';
    String dictDir = 'dict';

    // Example 1:
    // modelDir = 'vits-vctk';
    // modelName = 'vits-vctk.onnx';
    // lexicon = 'lexicon.txt';

    // Example 2:
    // https://github.com/k2-fsa/sherpa-onnx/releases/tag/tts-models
    // https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-amy-low.tar.bz2
    // modelDir = 'vits-piper-en_US-amy-low';
    // modelName = 'en_US-amy-low.onnx';
    // dataDir = 'vits-piper-en_US-amy-low/espeak-ng-data';

    // Example 3:
    // https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-icefall-zh-aishell3.tar.bz2
    // modelDir = 'vits-icefall-zh-aishell3';
    // modelName = 'model.onnx';
    // ruleFsts = 'vits-icefall-zh-aishell3/phone.fst,vits-icefall-zh-aishell3/date.fst,vits-icefall-zh-aishell3/number.fst,vits-icefall-zh-aishell3/new_heteronym.fst';
    // ruleFars = 'vits-icefall-zh-aishell3/rule.far';
    // lexicon = 'lexicon.txt';

    // Example 4:
    // https://k2-fsa.github.io/sherpa/onnx/tts/pretrained_models/vits.html#csukuangfj-vits-zh-hf-fanchen-c-chinese-187-speakers
    // modelDir = 'vits-zh-hf-fanchen-C';
    // modelName = 'vits-zh-hf-fanchen-C.onnx';
    // lexicon = 'lexicon.txt';
    // dictDir = 'vits-zh-hf-fanchen-C/dict';

    // Example 5:
    // https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-coqui-de-css10.tar.bz2
    // modelDir = 'vits-coqui-de-css10';
    // modelName = 'model.onnx';

    // Example 6
    // https://github.com/k2-fsa/sherpa-onnx/releases/tag/tts-models
    // https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-libritts_r-medium.tar.bz2
    // modelDir = 'vits-piper-en_US-libritts_r-medium';
    // modelName = 'en_US-libritts_r-medium.onnx';
    // dataDir = 'vits-piper-en_US-libritts_r-medium/espeak-ng-data';

    if (modelName == '') {
      throw Exception(
          'You are supposed to select a model by changing the code before you run the app');
    }

    modelName = p.join(_ttsModelInstallationPath!, modelName);

    if (ruleFsts != '') {
      final all = ruleFsts.split(',');
      var tmp = <String>[];
      for (final f in all) {
        tmp.add(p.join(_ttsModelInstallationPath!, f));
      }
      ruleFsts = tmp.join(',');
    }

    if (ruleFars != '') {
      final all = ruleFars.split(',');
      var tmp = <String>[];
      for (final f in all) {
        tmp.add(p.join(_ttsModelInstallationPath!, f));
      }
      ruleFars = tmp.join(',');
    }

    if (lexicon != '') {
      lexicon = p.join(_ttsModelInstallationPath!, lexicon);
    }

    if (dataDir != '') {
      dataDir = p.join(_ttsModelInstallationPath!, dataDir);
    }

    if (dictDir != '') {
      dictDir = p.join(_ttsModelInstallationPath!, dictDir);
    }

    final String tokens = p.join(_ttsModelInstallationPath!, 'tokens.txt');

    final vits = OfflineTtsVitsModelConfig(
      model: modelName,
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
      ruleFsts: ruleFsts,
      ruleFars: ruleFars,
      maxNumSenetences: 1,
    );

    final OfflineTts tts = OfflineTts(config);

    return tts;
  }

  static Future<OnlineRecognizer> createOnlineRecognizer() async {
    const type = 0;

    final modelConfig = await getOnlineModelConfig(type: type);
    final config = OnlineRecognizerConfig(
      model: modelConfig,
      ruleFsts: '',
    );

    return OnlineRecognizer(config);
  }
}
