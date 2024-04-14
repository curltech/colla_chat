
import 'package:colla_chat/l10n/localization.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcUtil {
  /// Check availability
  static Future<bool> isAvailable() async {
    var availability = await FlutterNfcKit.nfcAvailability;
    return availability == NFCAvailability.available;
  }

  static Future<NFCTag> poll() async {
    NFCTag tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 10),
        iosMultipleTagMessage: AppLocalizations.t('Multiple tags found!'),
        iosAlertMessage: AppLocalizations.t('Scan your tag'));

    return tag;
  }

  static Future<String> transceive(String data) async {
    String result = await FlutterNfcKit.transceive(data,
        timeout: const Duration(seconds: 5));
    return result;
  }

  static Future<List<ndef.NDEFRecord>> read() async {
    return await FlutterNfcKit.readNDEFRecords(cached: false);
  }

  static write(String data) async {
    List<ndef.NDEFRecord> records = [];
    ndef.NDEFRecord record = ndef.TextRecord(text: data);
    records.add(record);
    await FlutterNfcKit.writeNDEFRecords(records);
  }

  static finish() async {
    await FlutterNfcKit.finish();
  }
}
