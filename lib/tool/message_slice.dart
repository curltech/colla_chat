import 'dart:math';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/plugin/logger.dart';

///把二进制消息分片和汇总
class MessageSlice {
  int sliceSize;

  Map<int, List<int>> sliceBuffer = {};
  int sliceBufferId = 0;

  MessageSlice({this.sliceSize = 32 * 1024 * 1024});

  /// 返回分片的数据，每一个分片的索引为map的键值，withPrefix表示是否带有12位的前缀
  Map<int, List<int>> slice(List<int> message, {bool withPrefix = true}) {
    int total = message.length;
    int remainder = total % sliceSize;
    int sliceCount = total ~/ sliceSize;
    if (remainder > 0) {
      sliceCount++;
    }

    /// 随机数表示同一数据的唯一编号
    Random random = Random.secure();
    int randomNum = random.nextInt(1 << 32);
    Map<int, List<int>> slices = {};
    for (int i = 0; i < sliceCount; ++i) {
      List<int> data = [];
      if (withPrefix) {
        Uint8List prefix = Uint8List(12);
        prefix.buffer.asUint32List(0, 1)[0] = randomNum;
        prefix.buffer.asUint32List(4, 1)[0] = sliceCount;
        prefix.buffer.asUint32List(8, 1)[0] = i;
        data = prefix.toList();
      }
      int start = i * sliceSize;
      int end = (i + 1) * sliceSize;
      if (end < total) {
        data = CryptoUtil.concat(data, message.sublist(start, end));
      } else {
        data = CryptoUtil.concat(data, message.sublist(start));
      }
      slices[i] = data;
    }

    return slices;
  }

  /// 合并分片，所有的分片都有的时候返回汇总的数据，否则返回null，在类的内部暂存，withPrefix表示是否带有12位的前缀
  List<int>? merge(List<int> slice) {
    Uint8List prefix = Uint8List.fromList(slice.sublist(0, 12));
    int id = slice[0] +
        slice[1] * 256 +
        slice[2] * 256 * 256 +
        slice[3] * 256 * 256 * 256;
    if (id != sliceBufferId) {
      sliceBufferId = id;
      sliceBuffer = {};
    }
    int sliceCount = slice[4] +
        slice[5] * 256 +
        slice[6] * 256 * 256 +
        slice[7] * 256 * 256 * 256;
    int i = slice[8] +
        slice[9] * 256 +
        slice[10] * 256 * 256 +
        slice[11] * 256 * 256 * 256;
    if (sliceCount == 1) {
      sliceBufferId = 0;
      sliceBuffer = {};
      return slice.sublist(12);
    } else {
      List<int>? sliceData = sliceBuffer[i];
      if (sliceData == null) {
        sliceBuffer[i] = slice;
      }
      int sliceBufferSize = sliceBuffer.length;
      if (sliceBufferSize == sliceCount) {
        List<int> slices = [];
        var start = DateTime.now().millisecondsSinceEpoch;
        for (int j = 0; j < sliceBufferSize; ++j) {
          sliceData = sliceBuffer[j];
          if (sliceData != null) {
            slices = CryptoUtil.concat(slices, sliceData.sublist(12));
          }
        }
        var end = DateTime.now().millisecondsSinceEpoch;
        logger.i(
            'merge size:$sliceBufferSize sliceCount:$sliceCount time:${end - start}');
        sliceBufferId = 0;
        sliceBuffer = {};
        return slices;
      }
    }
    return null;
  }

  List<int>? concat(List<List<int>> slices) {
    List<int> data = [];
    for (List<int> slice in slices) {
      data = CryptoUtil.concat(data, slice);
    }
    return data;
  }
}
