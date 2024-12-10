import 'dart:io';

import 'package:archive/archive_io.dart';

class ArchiveUtil {
  ///压缩目录到一个文件，根据扩展名选择算法
  ///tar.gz, tgz, tar.bz2, tbz, tar.xz, txz, tar or zip
  static compress(
    String inputPath,
    String outputPath, {
    String? password,
    bool asyncWrite = false,
    int? bufferSize,
  }) async {
    Archive archive = createArchiveFromDirectory(Directory(inputPath));
    extractArchiveToDisk(archive, outputPath);
  }

  ///把压缩的文件解压到一个目录，根据扩展名选择算法
  static uncompress(
    String inputPath,
    String outputPath, {
    String? password,
    bool asyncWrite = false,
    int? bufferSize,
  }) async {
    await extractFileToDisk(inputPath, outputPath);
  }

  static zip(String inputPath, String outputPath) {
    var encoder = ZipFileEncoder();
    encoder.zipDirectory(Directory(inputPath), filename: outputPath);
  }

  static unZip(String inputPath, String outputPath) {
    final InputFileStream inputStream = InputFileStream(inputPath);
    final Archive archive = ZipDecoder().decodeStream(inputStream);
    extractArchiveToDisk(archive, outputPath);
  }
}
