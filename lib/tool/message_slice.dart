import 'dart:math';
import 'dart:typed_data';

import 'package:colla_chat/crypto/util.dart';
import 'package:colla_chat/plugin/logger.dart';

const int sliceSize = 16 * 1024;

///把二进制消息分片和汇总
class MessageSlice {
  Map<int, List<int>> sliceBuffer = {};
  int sliceBufferId = 0;

  Map<int, List<int>> slice(List<int> message) {
    int total = message.length;
    int remainder = total % sliceSize;
    int sliceCount = total ~/ sliceSize;
    if (remainder > 0) {
      sliceCount++;
    }
    var random = Random.secure();
    int randomNum = random.nextInt(1 << 32);
    Map<int, List<int>> slices = {};
    for (int i = 0; i < sliceCount; ++i) {
      Uint8List prefix = Uint8List(12);
      prefix.buffer.asUint32List(0, 1)[0] = randomNum;
      prefix.buffer.asUint32List(4, 1)[0] = sliceCount;
      prefix.buffer.asUint32List(8, 1)[0] = i;
      List<int> data = prefix.toList();
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

  List<int>? merge(List<int> data) {
    Uint8List prefix = Uint8List.fromList(data.sublist(0, 12));
    int id = data[0] +
        data[1] * 256 +
        data[2] * 256 * 256 +
        data[3] * 256 * 256 * 256;
    if (id != sliceBufferId) {
      sliceBufferId = id;
      sliceBuffer = {};
    }
    int sliceCount = data[4] +
        data[5] * 256 +
        data[6] * 256 * 256 +
        data[7] * 256 * 256 * 256;
    int i = data[8] +
        data[9] * 256 +
        data[10] * 256 * 256 +
        data[11] * 256 * 256 * 256;
    if (sliceCount == 1) {
      sliceBufferId = 0;
      sliceBuffer = {};
      return data.sublist(12);
    } else {
      List<int>? sliceData = sliceBuffer[i];
      if (sliceData == null) {
        sliceBuffer[i] = data;
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
        logger.i('merge size:$sliceBufferSize time:${end - start}');
        sliceBufferId = 0;
        sliceBuffer = {};
        return slices;
      }
    }
    return null;
  }
}
