import 'base.dart';

final brightnessOptions = [
  Option('Auto', 'auto'),
  Option('Light', 'light'),
  Option('Dark', 'dark')
];

final brightnessOptionsZH = [
  Option('自动', brightnessOptions[0].value),
  Option('亮', brightnessOptions[1].value),
  Option('黑', brightnessOptions[2].value)
];
final brightnessOptionsTW = [
  Option('自動', brightnessOptions[0].value),
  Option('亮', brightnessOptions[1].value),
  Option('黑', brightnessOptions[2].value)
];
final brightnessOptionsJA = [
  Option('自動', brightnessOptions[0].value),
  Option('明るい', brightnessOptions[1].value),
  Option('黒', brightnessOptions[2].value)
];
final brightnessOptionsKO = [
  Option('자동적 인', brightnessOptions[0].value),
  Option('선명한', brightnessOptions[1].value),
  Option('검정', brightnessOptions[2].value)
];
final brightnessOptionsISO = {
  'zh_CN': brightnessOptionsZH,
  'zh_TW': brightnessOptionsTW,
  'en_US': brightnessOptionsZH,
  'ja_JP': brightnessOptionsJA,
  'ko_KR': brightnessOptionsKO
};
