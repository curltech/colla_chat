import 'dart:async';

import 'package:colla_chat/provider/myself.dart';
import 'package:colla_chat/widgets/common/animated_progress_bar.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  success,
  warning,
  error,
  info,
  custom,
}

enum AnimationType {
  fromLeft,
  fromRight,
  fromTop,
  fromBottom,
}

class StackedOptions {
  /// 并行通知的key
  final String key;

  /// 显示偏移量
  final Offset itemOffset;

  /// 放大因子
  final double scaleFactor;

  /// 并行类型
  final StackedType type;

  StackedOptions({
    required this.key,
    this.itemOffset = const Offset(0, 0),
    this.scaleFactor = 0,
    this.type = StackedType.same,
  });
}

enum StackedType {
  /// 显示上面
  above,

  /// 显示下面
  below,

  /// 同位置
  same
}

/// 平台定制的overlay浮动框
// ignore: must_be_immutable
class OverlayNotification extends StatefulWidget {
  static final Map<String, OverlayNotification> _platformOverlays = {};

  late Widget? child;
  final double top;
  final bool isDraggable;

  ///通知的标题
  final Widget? title;

  ///通知的描述
  final Widget? description;

  ///描述的下面显示
  final Widget? action;

  ///图标
  final Widget? icon;

  ///T图标大小
  final double iconSize;

  ///通知的动画类型
  final AnimationType animation;

  ///动画的时间
  final Duration animationDuration;

  final Curve animationCurve;

  final Color? background;

  final BorderRadius? borderRadius;

  final BoxBorder? border;

  final Duration toastDuration;

  final BoxShadow? shadow;

  final bool showProgressIndicator;

  final Color? progressIndicatorColor;

  final double? progressBarWidth;

  final double? progressBarHeight;

  final EdgeInsetsGeometry? progressBarPadding;

  final Color? progressIndicatorBackground;

  final bool displayCloseButton;

  final Widget Function(
      void Function(OverlayNotification self) dismissNotification)? closeButton;

  final void Function(OverlayNotification self)? onCloseButtonPressed;

  final void Function(OverlayNotification self)? onProgressFinished;

  final void Function(OverlayNotification self)? onNotificationPressed;

  final Function(OverlayNotification self)? onDismiss;

  final bool autoDismiss;

  final DismissDirection dismissDirection;

  final Alignment position;

  final double? width;

  final double? height;

  final bool isDismissable;

  final double notificationMargin;

  final StackedOptions? stackedOptions;

  final NotificationType notificationType;
  OverlayEntry? overlayEntry;
  String? id;
  late Timer _closeTimer;
  late Animation<Offset> _offsetAnimation;
  late AnimationController _slideController;

  OverlayNotification(
      {super.key,
      this.title,
      this.description,
      this.icon,
      this.background = Colors.white,
      this.borderRadius,
      this.border,
      this.showProgressIndicator = true,
      this.closeButton,
      this.stackedOptions,
      this.notificationMargin = 20,
      this.progressIndicatorColor,
      this.toastDuration = const Duration(milliseconds: 3000),
      this.displayCloseButton = true,
      this.onCloseButtonPressed,
      this.onProgressFinished,
      this.position = Alignment.topRight,
      this.animation = AnimationType.fromTop,
      this.animationDuration = const Duration(milliseconds: 600),
      this.iconSize = 24.0,
      this.action,
      this.autoDismiss = true,
      this.height,
      this.width,
      this.progressBarHeight,
      this.progressBarWidth,
      this.progressBarPadding,
      this.onDismiss,
      this.isDismissable = true,
      this.dismissDirection = DismissDirection.horizontal,
      this.progressIndicatorBackground,
      this.onNotificationPressed,
      this.animationCurve = Curves.ease,
      this.shadow,
      this.top = 20.0,
      this.isDraggable = false,
      this.notificationType = NotificationType.custom,
      this.child});

  /// overlay的数目
  int get _overlaysLength {
    return _platformOverlays.keys.length;
  }

  /// overlay的位置
  int get _index {
    int i = 0;
    for (String key in _platformOverlays.keys.toList()) {
      if (key == id) {
        return i;
      }
      i++;
    }
    return 0;
  }

  /// 高度
  double _height(BuildContext context) {
    return height ?? MediaQuery.of(context).size.height * 0.12;
  }

  /// 宽度
  double _width(BuildContext context) {
    return width ?? MediaQuery.of(context).size.width * 0.9;
  }

  /// 第x个距离顶部高度的偏移量
  double _top(BuildContext context) {
    if (stackedOptions?.type == StackedType.above) {
      return -(_height(context) * _index) +
          (stackedOptions?.itemOffset.dy ?? 0) * _index;
    } else if (stackedOptions?.type == StackedType.below) {
      return (_height(context) * _index) +
          (stackedOptions?.itemOffset.dy ?? 0) * _index;
    } else {
      return (stackedOptions?.itemOffset.dy ?? 0) *
          (_overlaysLength - 1 - _index);
    }
  }

  /// 距离左边的宽度
  double _left(BuildContext context) {
    if (position.x == 1) {
      return MediaQuery.of(context).size.width -
          _width(context) -
          notificationMargin;
    } else if (position.x == -1) {
      return notificationMargin;
    } else {
      return ((position.x + 1) / 2) * MediaQuery.of(context).size.width -
          (_width(context) / 2);
    }
  }

  /// 第一个组件距离顶部高度
  double _firstTop(BuildContext context) {
    if (position.y == 1) {
      return MediaQuery.of(context).size.height -
          _height(context) -
          notificationMargin;
    } else if (position.y == -1) {
      return notificationMargin;
    } else {
      return ((position.y + 1) / 2) * MediaQuery.of(context).size.height -
          (_height(context) / 2);
    }
  }

  /// 保证取值在范围之间
  double _clampDouble(double x, double min, double max) {
    assert(min <= max && !max.isNaN && !min.isNaN);
    if (x < min) {
      return min;
    }
    if (x > max) {
      return max;
    }
    if (x.isNaN) {
      return max;
    }
    return x;
  }

  /// 放大系数
  double _scale() {
    if (stackedOptions?.scaleFactor != null) {
      return _clampDouble(
        (1 -
            (stackedOptions?.scaleFactor ?? 0) *
                (_overlaysLength - (_index + 1))),
        0,
        1,
      );
    } else {
      return 1.0;
    }
  }

  /// 创建定制（child不为空）或者notification的浮动框
  /// 计算显示位置，包含本组件
  OverlayEntry _buildFloatWidget() {
    return OverlayEntry(
      opaque: false,
      builder: (context) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          left: _left(context) +
              (stackedOptions?.itemOffset.dx ?? 0) *
                  (_overlaysLength - 1 - _index),
          top: _firstTop(context) + _top(context),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: _scale(),
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: this,
            ),
          ),
        );
      },
    );
  }

  /// 根据title和description创建通知组件的中心内容部分
  Widget _buildNotification(BuildContext context) {
    bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return Row(
      children: [
        Padding(
          padding: isRtl
              ? const EdgeInsets.only(right: 10.0)
              : const EdgeInsets.only(left: 10.0),
          child: _getNotificationIcon(),
        ),
        const SizedBox(
          width: 15,
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 20,
          ),
          child: Container(
            width: 1,
            color: myself.primary,
          ),
        ),
        const SizedBox(
          width: 15,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (title != null) ...[
                title!,
                const SizedBox(
                  height: 5,
                ),
              ],
              Expanded(child: description ?? Container()),
              if (action != null) ...[
                const SizedBox(
                  height: 5,
                ),
                action!,
              ],
            ],
          ),
        ),
        Visibility(
          visible: displayCloseButton,
          child: closeButton?.call(onCloseButtonPressed!) ??
              InkWell(
                onTap: () {
                  _onCloseButtonPressed();
                },
                child: Padding(
                  padding: isRtl
                      ? const EdgeInsets.only(
                          top: 10.0,
                          left: 10.0,
                        )
                      : const EdgeInsets.only(
                          top: 10.0,
                          right: 10.0,
                        ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.close,
                        color: myself.primary,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ],
    );
  }

  Widget _getNotificationIcon() {
    switch (notificationType) {
      case NotificationType.success:
        return const Icon(Icons.check_circle, color: Colors.blue);
      case NotificationType.error:
        return const Icon(Icons.error, color: Colors.red);
      case NotificationType.warning:
        return const Icon(
          Icons.error,
          color: Colors.yellow,
        );
      case NotificationType.info:
        return const Icon(Icons.info, color: Colors.green);
      default:
        return icon!;
    }
  }

  /// 根据title和description创建通知组件，加上支持点击，进度条等辅助支持
  Widget _buildNotificationWidget(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Dismissible(
        key: UniqueKey(),
        direction: isDismissable ? dismissDirection : DismissDirection.none,
        onDismissed: (direction) {
          dismiss();
        },
        child: InkWell(
            onTap: () {
              if (onNotificationPressed != null) {
                onNotificationPressed!(this);
              }
              dismiss();
            },
            child: SizedBox(
              width: _width(context),
              height: _height(context),
              child: Card(
                  elevation: 0.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: borderRadius ?? BorderRadius.circular(8.0)),
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildNotification(context),
                      ),
                      if (showProgressIndicator)
                        Padding(
                          padding:
                              progressBarPadding ?? const EdgeInsets.all(0),
                          child: SizedBox(
                            width: progressBarWidth,
                            height: progressBarHeight,
                            child: AnimatedProgressBar(
                              foregroundColor:
                                  progressIndicatorColor ?? myself.primary,
                              duration: toastDuration,
                              backgroundColor:
                                  progressIndicatorBackground ?? Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  )),
            )),
      ),
    );
  }

  /// 增加并显示一个新的浮动框，用于外部调用
  String show(BuildContext context) {
    Key uniqueKey = UniqueKey();
    id = uniqueKey.toString();
    overlayEntry = _buildFloatWidget();
    _platformOverlays[id!] = this;
    Overlay.of(context).insert(overlayEntry!);

    return id!;
  }

  void _onCloseButtonPressed() {
    if (onCloseButtonPressed != null) {
      onCloseButtonPressed!(this);
      dismiss();
    }
  }

  /// 关闭，用于外部调用
  void close() {
    if (id != null) {
      _platformOverlays.remove(id!);
      overlayEntry!.remove();
      overlayEntry!.dispose();
      id = null;
      overlayEntry = null;
    }
  }

  /// 中断计时器，调用onDismiss方法，然后关闭，用于外部调用
  Future<void> dismiss() {
    _closeTimer.cancel();
    return _slideController.reverse().then((value) {
      if (onDismiss != null) {
        onDismiss!(this);
      }
      close();
    });
  }

  @override
  State createState() => OverlayNotificationState();
}

class OverlayNotificationState extends State<OverlayNotification>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _initTimer();
    _initializeAnimation();
  }

  _initTimer() {
    widget._closeTimer = Timer(widget.toastDuration, () {
      widget._slideController.reverse();
      widget._slideController.addListener(() {
        if (widget._slideController.isDismissed) {
          if (widget.onProgressFinished != null) {
            widget.onProgressFinished!(widget);
          }
          widget.close();
        }
      });
    });
    if (!widget.autoDismiss) {
      widget._closeTimer.cancel();
    }
  }

  void _initializeAnimation() {
    widget._slideController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    switch (widget.animation) {
      case AnimationType.fromLeft:
        widget._offsetAnimation = Tween<Offset>(
          begin: const Offset(-2, 0),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(
            parent: widget._slideController,
            curve: widget.animationCurve,
          ),
        );
        break;
      case AnimationType.fromRight:
        widget._offsetAnimation = Tween<Offset>(
          begin: const Offset(2, 0),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(
            parent: widget._slideController,
            curve: widget.animationCurve,
          ),
        );
        break;
      case AnimationType.fromTop:
        widget._offsetAnimation = Tween<Offset>(
          begin: const Offset(0, -7),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(
            parent: widget._slideController,
            curve: widget.animationCurve,
          ),
        );
        break;
      case AnimationType.fromBottom:
        widget._offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 4),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(
            parent: widget._slideController,
            curve: widget.animationCurve,
          ),
        );
        break;
      default:
        widget._offsetAnimation = Tween<Offset>(
          begin: const Offset(-2, 0),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(
            parent: widget._slideController,
            curve: widget.animationCurve,
          ),
        );
        break;
    }

    /// ! To support Flutter < 3.0.0
    /// This allows a value of type T or T?
    /// to be treated as a value of type T?.
    ///
    /// We use this so that APIs that have become
    /// non-nullable can still be used with `!` and `?`
    /// to support older versions of the API as well.
    T? ambiguate<T>(T? value) => value;

    ambiguate(WidgetsBinding.instance)?.addPostFrameCallback(
      (_) => widget._slideController.forward(),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// 如果定制组件为空，而且是通知组件，创建通知组件设置为child
    if (widget.child == null && widget.description != null) {
      widget.child = widget._buildNotificationWidget(context);
    }
    return widget.child!;
  }

  @override
  void dispose() {
    widget._slideController.dispose();
    widget._closeTimer.cancel();
    super.dispose();
  }
}
