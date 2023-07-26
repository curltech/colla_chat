import 'dart:convert';
import 'dart:typed_data';

import 'package:colla_chat/plugin/logger.dart';
import 'package:nfc_manager/nfc_manager.dart';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcUtil {
  static NfcManager nfcManager = NfcManager.instance;

  /// Check availability
  static Future<bool> isAvailable() async {
    return await nfcManager.isAvailable();
  }

  /// Start Session
  /// onDiscovered的tag.data获取标签数据
  static startSession({
    required Future<void> Function(NfcTag) onDiscovered,
    Set<NfcPollingOption>? pollingOptions,
    String? alertMessage,
    bool? invalidateAfterFirstRead = true,
    Future<void> Function(NfcError)? onError,
  }) async {
    await nfcManager.startSession(
        onDiscovered: onDiscovered,
        pollingOptions: pollingOptions,
        alertMessage: alertMessage,
        invalidateAfterFirstRead: invalidateAfterFirstRead,
        onError: onError);
  }

  /// Stop Session
  static stopSession({String? alertMessage, String? errorMessage}) async {
    await nfcManager.stopSession(
        alertMessage: alertMessage, errorMessage: errorMessage);
  }

  ///get Ndef instance
  static Ndef? from(NfcTag tag) {
    Ndef? ndef = Ndef.from(tag);

    return ndef;
  }

  ///发现后读Ndef消息
  static void read(Function(Map<String, dynamic> data) onRead) {
    nfcManager.startSession(onDiscovered: (NfcTag tag) async {
      onRead(tag.data);
      nfcManager.stopSession();
    });
  }

  ///发现后写Ndef消息
  static void writeNdef(
      {String? text,
      String? url,
      String? domain,
      String? type,
      Uint8List? data}) {
    nfcManager.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        logger.e('Tag is not ndef writable');
        nfcManager.stopSession(errorMessage: 'Tag is not ndef writable');
        return;
      }

      List<NdefRecord> records = [];
      if (text != null) {
        records.add(NdefRecord.createText(text));
      }
      if (url != null) {
        records.add(NdefRecord.createUri(Uri.parse(url)));
      }
      if (domain != null && type != null && data != null) {
        records.add(
            NdefRecord.createExternal(domain, type, Uint8List.fromList(data)));
      } else if (type != null && data != null) {
        records.add(NdefRecord.createMime(type, Uint8List.fromList(data)));
      }
      NdefMessage message = NdefMessage(records);

      try {
        await ndef.write(message);
        logger.i('Success to "Ndef Write"');
        nfcManager.stopSession();
      } catch (e) {
        logger.e('Ndef write failure:$e');
        nfcManager.stopSession(errorMessage: '$e');
        return;
      }
    });
  }

  test() async {
    var availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      // oh-no
    }

    // timeout only works on Android, while the latter two messages are only for iOS
    var tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Scan your tag");

    print(jsonEncode(tag));
    if (tag.type == NFCTagType.iso7816) {
      var result = await FlutterNfcKit.transceive("00B0950000",
          timeout: const Duration(
              seconds:
                  5)); // timeout is still Android-only, persist until next change
      print(result);
    }
    // iOS only: set alert message on-the-fly
    // this will persist until finish()
    await FlutterNfcKit.setIosAlertMessage("hi there!");

    // read NDEF records if available
    bool? ndefAvailable = tag.ndefAvailable;
    if (ndefAvailable != null && ndefAvailable) {
      /// decoded NDEF records (see [ndef.NDEFRecord] for details)
      /// `UriRecord: id=(empty) typeNameFormat=TypeNameFormat.nfcWellKnown type=U uri=https://github.com/nfcim/ndef`
      for (var record in await FlutterNfcKit.readNDEFRecords(cached: false)) {
        print(record.toString());
      }

      /// raw NDEF records (data in hex string)
      /// `{identifier: "", payload: "00010203", type: "0001", typeNameFormat: "nfcWellKnown"}`
      for (var record
          in await FlutterNfcKit.readNDEFRawRecords(cached: false)) {
        print(jsonEncode(record).toString());
      }
    }

    // write NDEF records if applicable
    bool? ndefWritable = tag.ndefWritable;
    if (ndefWritable != null && ndefWritable) {
      // decoded NDEF records
      await FlutterNfcKit.writeNDEFRecords([
        ndef.UriRecord.fromUri(
            Uri.parse("https://github.com/nfcim/flutter_nfc_kit"))
      ]);
      // raw NDEF records
      await FlutterNfcKit.writeNDEFRawRecords(
          [NDEFRawRecord("00", "0001", "0002", ndef.TypeNameFormat.unknown)]);
    }

    // Call finish() only once
    await FlutterNfcKit.finish();
    // iOS only: show alert/error message on finish
    await FlutterNfcKit.finish(iosAlertMessage: "Success");
    // or
    await FlutterNfcKit.finish(iosErrorMessage: "Failed");
  }
}
