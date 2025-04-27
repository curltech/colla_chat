import 'package:colla_chat/plugin/talker_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io';
import 'package:pip/pip.dart';
import 'package:native_plugin/native_plugin.dart';

typedef PlatformViewCreatedCallback = void Function(
    int viewId, int internalViewId);

/// 潜在平台视图
class NativeViewWidget extends StatelessWidget {
  NativeViewWidget({super.key, required this.onPlatformViewCreated});

  final PlatformViewCreatedCallback onPlatformViewCreated;

  MethodChannel? _methodChannel;

  int internalViewId = 0;

  @override
  Widget build(BuildContext context) {
    const String viewType = 'native_view';
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (id) async {
        _methodChannel = MethodChannel('native_plugin/native_view_$id');
        internalViewId =
            await _methodChannel!.invokeMethod<int>('getInternalView') as int;
        onPlatformViewCreated(id, internalViewId);
      },
    );
  }
}

class BackgroundPipController {
  final RxBool autoEnterEnabled = true.obs;

  // android only
  final RxInt aspectRatioX = 16.obs;
  final RxInt aspectRatioY = 9.obs;

  // ios only
  final RxInt playerView = 0.obs;
  final RxInt pipContentView = 0.obs;
  final RxInt preferredContentWidth = 900.obs;
  final RxInt preferredContentHeight = 1600.obs;
  final RxInt controlStyle = 2.obs;

  final RxBool isPipSupported = false.obs;
  final RxBool isPipAutoEnterSupported = false.obs;
  final RxBool isPipActive = false.obs;
}

/// 后台画中画的组件
class BackgroundPipWidget extends StatefulWidget {
  const BackgroundPipWidget({super.key});

  @override
  State<BackgroundPipWidget> createState() => _BackgroundPipWidgetState();
}

class _BackgroundPipWidgetState extends State<BackgroundPipWidget>
    with WidgetsBindingObserver {
  final formKey = GlobalKey<FormState>();
  final BackgroundPipController backgroundPipController =
      BackgroundPipController();
  final pip = Pip();
  final _nativePlugin = NativePlugin();

  AppLifecycleState lastAppLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
  }

  /// APP被放入后台或者前台的时候调用
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    logger.i("[didChangeAppLifecycleState]: $state");

    if (state == AppLifecycleState.inactive) {
      // 在IOS，如果设置根视图作为源视图，调用pipStart进入pip模式
      // 然而，PlatformView被创建后调用pipSetup，会有问题
      // 原因是源视图需要时间准备，因此，最好是设置autoEnterEnabled为true，调用pipStart在resumed状态.
      if (lastAppLifecycleState != AppLifecycleState.paused &&
          !backgroundPipController.isPipAutoEnterSupported.value) {
        await pip.start();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!Platform.isAndroid) {
        // Android,不支持pipStop，pipStop仅仅是将activity带入后台
        await pip.stop();
      }
    }

    // AppLifecycleState.hidden在Flutter 3.13.0引入，为了支持Flutter 3.7.0+，容许安全地忽略hidden状态，
    // 避免在APP从暂停时恢复不期待进入Pip
    // See: https://docs.flutter.dev/release/breaking-changes/add-applifecyclestate-hidden
    switch (state) {
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (lastAppLifecycleState != state) {
          setState(() {
            lastAppLifecycleState = state;
          });
        }
        break;
      default:
        break;
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    bool pipIsSupported = false;
    bool pipIsAutoEnterSupported = false;
    bool isPipActived = false;
    try {
      var platformVersion = await _nativePlugin.getPlatformVersion();
      logger.i('[platformVersion]: $platformVersion');
      pipIsSupported = await pip.isSupported();
      pipIsAutoEnterSupported = await pip.isAutoEnterSupported();
      isPipActived = await pip.isActived();
      await pip.registerStateChangedObserver(PipStateChangedObserver(
        onPipStateChanged: (state, error) {
          logger.i('[onPipStateChanged] state: $state, error: $error');
          setState(() {
            isPipActived = state == PipState.pipStateStarted;
          });

          if (state == PipState.pipStateFailed) {
            logger.i('[onPipStateChanged] state: $state, error: $error');
            // if you destroy the source view of pip controller, some error may happen,
            // so we need to dispose the pip controller here.
            pip.dispose();
          }
        },
      ));
    } on PlatformException {
      pipIsSupported = false;
      pipIsAutoEnterSupported = false;
      isPipActived = false;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      backgroundPipController.isPipSupported.value = pipIsSupported;
      backgroundPipController.isPipAutoEnterSupported.value =
          pipIsAutoEnterSupported;
      backgroundPipController.isPipActive.value = isPipActived;

      // set the autoEnterEnabled to true if the pip is auto enter supported
      backgroundPipController.autoEnterEnabled.value = pipIsAutoEnterSupported;
    });
  }

  Future<void> _setupPip() async {
    if (formKey.currentState!.validate()) {
      if (Platform.isIOS && backgroundPipController.pipContentView.value == 0) {
        backgroundPipController.pipContentView.value =
            await _nativePlugin.createPipContentView();
        logger.i(
            '[createPipContentView]: ${backgroundPipController.pipContentView.value}');

        setState(() {
          backgroundPipController.pipContentView.value =
              backgroundPipController.pipContentView.value;
        });
      }
      final options = PipOptions(
        autoEnterEnabled: backgroundPipController.autoEnterEnabled.value,

        // android only
        aspectRatioX: backgroundPipController.aspectRatioX.value,
        aspectRatioY: backgroundPipController.aspectRatioY.value,

        // ios only
        contentView: backgroundPipController.pipContentView.value,
        sourceContentView: backgroundPipController.playerView.value,
        preferredContentWidth: 900,
        preferredContentHeight: 1600,
        controlStyle: 2,
      );

      try {
        final success = await pip.setup(options);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PiP Setup ${success ? 'successful' : 'failed'}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PiP Setup error: $e')),
        );
      }
    }
  }

  /// 创建Pip的视图
  Widget _buildPipView() {
    // 不是Android平台
    if (!Platform.isAndroid) {
      return SizedBox(
        height: 200,
        child: NativeViewWidget(
          onPlatformViewCreated: (id, internalViewId) {
            logger.i(
                'Platform view created: $id, internalViewId: $internalViewId');
            setState(() {
              backgroundPipController.playerView.value = internalViewId;
            });
          },
        ),
      );
    }

    // IOS平台
    return Center(
      child: Builder(
        builder: (context) {
          try {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Text('player content');
              },
            );
          } catch (e) {
            logger.e('Exception while loading image: $e');
            return Text('Exception: $e');
          }
        },
      ),
    );
  }

  Widget _buildPipFunctions() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.start,
      children: [
        Text(
          'Supported: $backgroundPipController.isPipSupported\n'
          'Auto Enter Supported: $backgroundPipController.isPipAutoEnterSupported\n'
          'Actived: $backgroundPipController.isPipActived',
          style: const TextStyle(fontSize: 16),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto Enter Enabled'),
          value: backgroundPipController.autoEnterEnabled.value,
          onChanged: (value) => setState(() =>
              backgroundPipController.autoEnterEnabled.value = value ?? false),
        ),
        ElevatedButton(
          onPressed: _setupPip,
          child: const Text('Setup PiP'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              final success = await pip.start();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('PiP Start ${success ? 'successful' : 'failed'}')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PiP Start error: $e')),
              );
            }
          },
          child: const Text('Start PiP'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await pip.stop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PiP Stopped')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PiP Stop error: $e')),
              );
            }
          },
          child: const Text('Stop PiP'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await pip.dispose();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PiP Disposed')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PiP Dispose error: $e')),
              );
            }
          },
          child: const Text('Dispose PiP'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 支持Pip
    if (backgroundPipController.isPipSupported.value) {
      // 是Android并且Pip被激活
      if (Platform.isAndroid && backgroundPipController.isPipActive.value) {
        return _buildPipView();
      } else {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPipView(),
                  // 不是Android或者没有激活
                  if (!(Platform.isAndroid &&
                      backgroundPipController.isPipActive.value)) ...[
                    _buildPipFunctions(),
                  ],
                ],
              ),
            ),
          ),
        );
      }
    } else {
      return const Center(
        child: Text('Pip is not supported'),
      );
    }
  }

  @override
  void dispose() {
    if (Platform.isIOS && backgroundPipController.pipContentView.value != 0) {
      _nativePlugin
          .disposePipContentView(backgroundPipController.pipContentView.value);
    }

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
