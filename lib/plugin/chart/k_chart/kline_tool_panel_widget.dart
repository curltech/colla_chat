import 'package:colla_chat/constant/base.dart';
import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/chart/k_chart/kline_controller.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KlineToolPanelWidget extends StatelessWidget {
  const KlineToolPanelWidget({super.key});

  Widget _buildToolPanelWidget(BuildContext context) {
    return Obx(() {
      List<Widget> btns = [
        Transform.scale(
            scale: 0.7,
            child: ToggleButtons(
              color: Colors.grey,
              fillColor: myself.primary,
              borderRadius: borderRadius,
              onPressed: (int value) {
                multiKlineController.online.value = value == 0 ? true : false;
              },
              isSelected: [
                multiKlineController.online.value,
                !multiKlineController.online.value
              ],
              children: [
                TextButton(
                    onPressed: () {
                      multiKlineController.online.value = true;
                    },
                    child: Text(
                      AppLocalizations.t('online'),
                      style: const TextStyle(color: Colors.white),
                    )),
                TextButton(
                    onPressed: () {
                      multiKlineController.online.value = false;
                    },
                    child: Text(AppLocalizations.t('offline'),
                        style: const TextStyle(color: Colors.white)))
              ],
            )),
        TextButton(
            onPressed: multiKlineController.lineType.value != 100
                ? () {
                    multiKlineController.lineType.value = 100;
                  }
                : null,
            child: Text(
              AppLocalizations.t('minline'),
              style: TextStyle(
                color: multiKlineController.lineType.value == 100
                    ? myself.primary
                    : Colors.white,
              ),
            )),
        TextButton(
            onPressed: multiKlineController.lineType.value != 101
                ? () {
                    multiKlineController.lineType.value = 101;
                  }
                : null,
            child: Text(
              AppLocalizations.t('dayline'),
              style: TextStyle(
                color: multiKlineController.lineType.value == 101
                    ? myself.primary
                    : Colors.white,
              ),
            )),
        TextButton(
            onPressed: multiKlineController.lineType.value != 102
                ? () {
                    multiKlineController.lineType.value = 102;
                  }
                : null,
            child: Text(
              AppLocalizations.t('weekline'),
              style: TextStyle(
                color: multiKlineController.lineType.value == 102
                    ? myself.primary
                    : Colors.white,
              ),
            )),
        TextButton(
            onPressed: multiKlineController.lineType.value != 103
                ? () {
                    multiKlineController.lineType.value = 103;
                  }
                : null,
            child: Text(
              AppLocalizations.t('monthline'),
              style: TextStyle(
                color: multiKlineController.lineType.value == 103
                    ? myself.primary
                    : Colors.white,
              ),
            )),
        TextButton(
            onPressed: multiKlineController.lineType.value != 104
                ? () {
                    multiKlineController.lineType.value = 104;
                  }
                : null,
            child: Text(
              AppLocalizations.t('quatarline'),
              style: TextStyle(
                color: multiKlineController.lineType.value == 104
                    ? myself.primary
                    : Colors.white,
              ),
            )),
        TextButton(
            onPressed: multiKlineController.lineType.value != 105
                ? () {
                    multiKlineController.lineType.value = 105;
                  }
                : null,
            child: Text(
              AppLocalizations.t('halfyearline'),
              style: TextStyle(
                color: multiKlineController.lineType.value == 105
                    ? myself.primary
                    : Colors.white,
              ),
            )),
        TextButton(
            onPressed: multiKlineController.lineType.value != 106
                ? () {
                    multiKlineController.lineType.value = 106;
                  }
                : null,
            child: Text(
              AppLocalizations.t('yearline'),
              style: TextStyle(
                color: multiKlineController.lineType.value == 106
                    ? myself.primary
                    : Colors.white,
              ),
            )),
        IconButton(
          tooltip: AppLocalizations.t('Previous'),
          onPressed: () async {
            await multiKlineController.previous();
          },
          icon: Icon(Icons.skip_previous_outlined, color: myself.primary),
        ),
        IconButton(
            tooltip: AppLocalizations.t('Next'),
            onPressed: () async {
              await multiKlineController.next();
            },
            icon: Icon(Icons.skip_next_outlined, color: myself.primary)),
      ];

      return Row(
        children: btns,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.grey, child: _buildToolPanelWidget(context));
  }
}
