import 'package:colla_chat/l10n/localization.dart';
import 'package:colla_chat/plugin/overlay/overlay_notification.dart';
import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/common_widget.dart';
import 'package:flutter/material.dart';
import 'package:stacked_notification_cards/stacked_notification_cards.dart';
import 'package:toastification/toastification.dart';

class NotificationUtil {
  static OverlayNotification show(BuildContext context,
      {Key? key,
      Widget? title,
      required Widget description,
      Widget? icon,
      Color? background,
      BorderRadius? borderRadius,
      BoxBorder? border,
      bool showProgressIndicator = true,
      Widget Function(void Function(OverlayNotification self))? closeButton,
      StackedOptions? stackedOptions,
      double notificationMargin = 20,
      Color? progressIndicatorColor,
      Duration toastDuration = const Duration(milliseconds: 3000),
      bool displayCloseButton = true,
      void Function(OverlayNotification self)? onCloseButtonPressed,
      void Function(OverlayNotification self)? onProgressFinished,
      Alignment position = Alignment.topCenter,
      AnimationType animation = AnimationType.fromTop,
      Duration animationDuration = const Duration(milliseconds: 600),
      double iconSize = 24,
      Widget? action,
      bool autoDismiss = true,
      double? height,
      double? width,
      double? progressBarHeight,
      double? progressBarWidth,
      EdgeInsetsGeometry? progressBarPadding,
      dynamic Function(OverlayNotification self)? onDismiss,
      bool isDismissable = true,
      DismissDirection dismissDirection = DismissDirection.horizontal,
      Color? progressIndicatorBackground,
      void Function(OverlayNotification self)? onNotificationPressed,
      Curve animationCurve = Curves.ease,
      BoxShadow? shadow,
      NotificationType notificationType = NotificationType.custom}) {
    OverlayNotification overlayNotification = OverlayNotification(
        key: key,
        title: title,
        description: description,
        icon: icon,
        background: background,
        borderRadius: borderRadius,
        border: border,
        showProgressIndicator: showProgressIndicator,
        closeButton: closeButton,
        stackedOptions: stackedOptions,
        notificationMargin: notificationMargin,
        progressIndicatorColor: progressIndicatorColor ?? myself.primary,
        toastDuration: toastDuration,
        displayCloseButton: displayCloseButton,
        onCloseButtonPressed: onCloseButtonPressed,
        onProgressFinished: onProgressFinished,
        position: position,
        animation: animation,
        animationDuration: animationDuration,
        iconSize: iconSize,
        action: action,
        autoDismiss: autoDismiss,
        height: height,
        width: width,
        progressBarHeight: progressBarHeight,
        progressBarWidth: progressBarWidth,
        progressBarPadding: progressBarPadding,
        onDismiss: onDismiss,
        isDismissable: isDismissable,
        dismissDirection: dismissDirection,
        progressIndicatorBackground: progressIndicatorBackground,
        onNotificationPressed: onNotificationPressed,
        animationCurve: animationCurve,
        shadow: shadow,
        notificationType: notificationType);
    overlayNotification.show(context);

    return overlayNotification;
  }

  static OverlayNotification info(
    BuildContext context, {
    String? title,
    required String description,
    Widget? icon,
    bool showProgressIndicator = false,
  }) {
    OverlayNotification overlayNotification = OverlayNotification(
      title: CommonAutoSizeText(AppLocalizations.t(title ?? '')),
      description: CommonAutoSizeText(AppLocalizations.t(description)),
      icon: icon,
      showProgressIndicator: showProgressIndicator,
      notificationType: NotificationType.info,
      displayCloseButton: false,
    );
    overlayNotification.show(context);

    return overlayNotification;
  }

  static OverlayNotification success(
    BuildContext context, {
    String? title,
    required String description,
    Widget? icon,
    bool showProgressIndicator = false,
  }) {
    OverlayNotification overlayNotification = OverlayNotification(
      title: CommonAutoSizeText(AppLocalizations.t(title ?? '')),
      description: CommonAutoSizeText(AppLocalizations.t(description)),
      icon: icon,
      showProgressIndicator: showProgressIndicator,
      notificationType: NotificationType.success,
      displayCloseButton: false,
    );
    overlayNotification.show(context);

    return overlayNotification;
  }

  static OverlayNotification error(
    BuildContext context, {
    String? title,
    required String description,
    Widget? icon,
    bool showProgressIndicator = false,
  }) {
    OverlayNotification overlayNotification = OverlayNotification(
      title: CommonAutoSizeText(AppLocalizations.t(title ?? '')),
      description: CommonAutoSizeText(AppLocalizations.t(description)),
      icon: icon,
      showProgressIndicator: showProgressIndicator,
      notificationType: NotificationType.error,
      displayCloseButton: false,
    );
    overlayNotification.show(context);

    return overlayNotification;
  }

  static OverlayNotification warning(
    BuildContext context, {
    String? title,
    required String description,
    Widget? icon,
    bool showProgressIndicator = false,
  }) {
    OverlayNotification overlayNotification = OverlayNotification(
      title: CommonAutoSizeText(AppLocalizations.t(title ?? '')),
      description: CommonAutoSizeText(AppLocalizations.t(description)),
      icon: icon,
      showProgressIndicator: showProgressIndicator,
      notificationType: NotificationType.warning,
      displayCloseButton: false,
    );
    overlayNotification.show(context);

    return overlayNotification;
  }

  static ToastificationItem toast({
    BuildContext? context,
    AlignmentGeometry? alignment,
    Duration? autoCloseDuration,
    OverlayState? overlayState,
    Widget Function(BuildContext, Animation<double>, Alignment, Widget)?
        animationBuilder,
    ToastificationType? type,
    ToastificationStyle? style,
    Widget? title,
    Duration? animationDuration,
    Widget? description,
    Widget? icon,
    Color? primaryColor,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadiusGeometry? borderRadius,
    BorderSide? borderSide,
    List<BoxShadow>? boxShadow,
    TextDirection? direction,
    bool? showProgressBar,
    ProgressIndicatorThemeData? progressBarTheme,
    CloseButtonShowType? closeButtonShowType,
    bool? closeOnClick,
    bool? dragToClose,
    DismissDirection? dismissDirection,
    bool? pauseOnHover,
    bool? applyBlurEffect,
    ToastificationCallbacks callbacks = const ToastificationCallbacks(),
  }) {
    ToastificationItem item = toastification.show(
      context: context,
      alignment: alignment,
      autoCloseDuration: autoCloseDuration,
      overlayState: overlayState,
      animationBuilder: animationBuilder,
      type: type,
      style: style,
      title: title,
      animationDuration: animationDuration,
      description: description,
      icon: icon,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      borderSide: borderSide,
      boxShadow: boxShadow,
      direction: direction,
      showProgressBar: showProgressBar,
      progressBarTheme: progressBarTheme,
      closeButtonShowType: closeButtonShowType,
      closeOnClick: closeOnClick,
      dragToClose: dragToClose,
      dismissDirection: dismissDirection,
      pauseOnHover: pauseOnHover,
      applyBlurEffect: applyBlurEffect,
      callbacks: callbacks,
    );

    return item;
  }

  static ToastificationItem toastCustom({
    BuildContext? context,
    AlignmentGeometry? alignment,
    TextDirection? direction,
    required Widget Function(BuildContext, ToastificationItem) builder,
    Widget Function(BuildContext, Animation<double>, Alignment, Widget)?
        animationBuilder,
    Duration? animationDuration,
    Duration? autoCloseDuration,
    OverlayState? overlayState,
    DismissDirection? dismissDirection,
    ToastificationCallbacks callbacks = const ToastificationCallbacks(),
  }) {
    ToastificationItem item = toastification.showCustom(
      context: context,
      alignment: alignment,
      autoCloseDuration: autoCloseDuration,
      overlayState: overlayState,
      animationBuilder: animationBuilder,
      animationDuration: animationDuration,
      direction: direction,
      dismissDirection: dismissDirection,
      callbacks: callbacks,
      builder: builder,
    );

    return item;
  }

  static StackedNotificationCards buildStackedNotificationCards({
    Key? key,
    required List<NotificationCard> notificationCards,
    required Color cardColor,
    required String notificationCardTitle,
    required void Function() onTapClearAll,
    required Widget clearAllNotificationsAction,
    required Widget clearAllStacked,
    required Widget cardClearButton,
    required Widget cardViewButton,
    required void Function(int) onTapClearCallback,
    required void Function(int) onTapViewCallback,
    required Widget actionTitle,
    required Widget showLessAction,
    List<BoxShadow>? boxShadow,
    TextStyle titleTextStyle = const TextStyle(fontWeight: FontWeight.w500),
    TextStyle? subtitleTextStyle,
    double cardCornerRadius = 8,
    double cardsSpacing = 10,
    double padding = 0,
  }) {
    return StackedNotificationCards(
      key: key,
      notificationCards: notificationCards,
      cardColor: cardColor,
      notificationCardTitle: notificationCardTitle,
      onTapClearAll: onTapClearAll,
      clearAllNotificationsAction: clearAllNotificationsAction,
      clearAllStacked: clearAllStacked,
      cardClearButton: cardClearButton,
      cardViewButton: cardViewButton,
      onTapClearCallback: onTapClearCallback,
      onTapViewCallback: onTapViewCallback,
      actionTitle: actionTitle,
      showLessAction: showLessAction,
      boxShadow: boxShadow,
      titleTextStyle: titleTextStyle,
      subtitleTextStyle: subtitleTextStyle,
      cardCornerRadius: cardCornerRadius,
      cardsSpacing: cardsSpacing,
      padding: padding,
    );
  }
}
