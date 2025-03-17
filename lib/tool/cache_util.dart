import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 文件缓存
class CacheUtil {
  /// 获取文件，如果不在缓存中则
  static Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    return await DefaultCacheManager()
        .getSingleFile(url, key: key, headers: headers);
  }

  static Future<File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    return await DefaultCacheManager().putFile(url, fileBytes,
        key: key, eTag: eTag, maxAge: maxAge, fileExtension: fileExtension);
  }

  /// from web
  static Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) async {
    return await DefaultCacheManager()
        .downloadFile(url, key: key, authHeaders: authHeaders, force: force);
  }

  static Future<FileInfo?> getFileFromCache(String key,
      {bool ignoreMemCache = false}) async {
    return await DefaultCacheManager()
        .getFileFromCache(key, ignoreMemCache: ignoreMemCache);
  }

  static Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    return DefaultCacheManager().getFileStream(url,
        key: key, headers: headers, withProgress: withProgress);
  }

  static Future<FileInfo?> getFileFromMemory(String key) async {
    return await DefaultCacheManager().getFileFromMemory(key);
  }

  static Stream<FileResponse> getImageFile(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
    int? maxHeight,
    int? maxWidth,
  }) {
    return DefaultCacheManager().getImageFile(url,
        key: key,
        headers: headers,
        withProgress: withProgress,
        maxHeight: maxHeight,
        maxWidth: maxWidth);
  }

  static Future<File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) {
    return DefaultCacheManager().putFileStream(
      url,
      source,
      key: key,
      eTag: eTag,
      maxAge: maxAge,
      fileExtension: fileExtension,
    );
  }

  static Future<void> emptyCache() {
    return DefaultCacheManager().emptyCache();
  }

  static Future<void> removeFile(String key) {
    return DefaultCacheManager().removeFile(
      key,
    );
  }
}
