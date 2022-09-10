import 'dart:async';

import 'package:colla_chat/plugin/logger.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';

class PackageInfoUtil {
  Future<PackageInfo> getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    // String appName = packageInfo.appName;
    // String packageName = packageInfo.packageName;
    // String version = packageInfo.version;
    // String buildNumber = packageInfo.buildNumber;

    return packageInfo;
  }
}

class TraceUtil {
  DateTime start(String msg) {
    DateTime t = DateTime.now().toUtc();
    logger.i('$msg, trace start:${t.toIso8601String()}');
    return t;
  }

  Duration end(DateTime start, String msg) {
    DateTime t = DateTime.now().toUtc();
    Duration diff = t.difference(start);
    logger.i('$msg, trace end:${t.toIso8601String()}, interval $diff');
    return diff;
  }
}

class CollectUtil {
  ///判断List是否为空
  static bool listNoEmpty(List? list) {
    if (list == null) return false;

    if (list.isEmpty) return false;

    return true;
  }
}

class StandardMessageCodecUtil {
  static Uint8List encode(Object o) {
    final ByteData? data = const StandardMessageCodec().encodeMessage(o);
    return data!.buffer.asUint8List();
  }

  static Uint8List decode(List<int> raw) {
    var data = Uint8List.fromList(raw);
    final dynamic o =
        const StandardMessageCodec().decodeMessage(ByteData.view(data.buffer));

    return o;
  }
}

class XFileUtil {
  static XFile open(String filename) {
    final file = XFile(filename);

    return file;
  }
}
