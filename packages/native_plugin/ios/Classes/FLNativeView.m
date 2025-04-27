#import "FLNativeView.h"
#import "PlayerView.h"

@implementation FLNativeViewFactory {
  NSObject<FlutterBinaryMessenger> *_messenger;
}

- (instancetype)initWithMessenger:
    (NSObject<FlutterBinaryMessenger> *)messenger {
  self = [super init];
  if (self) {
    _messenger = messenger;
  }
  return self;
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id _Nullable)args {
  return [[FLNativeView alloc] initWithFrame:frame
                              viewIdentifier:viewId
                                   arguments:args
                             binaryMessenger:_messenger];
}

/// Implementing this method is only necessary when the `arguments` in
/// `createWithFrame` is not `nil`.
- (NSObject<FlutterMessageCodec> *)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

@end

@implementation FLNativeView {
  PlayerView *_view;
  FlutterMethodChannel *_methodChannel;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger {
  if (self = [super init]) {
    _view = [[PlayerView alloc] init];
    _methodChannel = [FlutterMethodChannel
        methodChannelWithName:
            [NSString
                stringWithFormat:@"native_plugin/native_view_%lld", viewId]
              binaryMessenger:messenger];
    __weak typeof(self) weakSelf = self;
    [_methodChannel setMethodCallHandler:^(FlutterMethodCall *_Nonnull call,
                                           FlutterResult _Nonnull result) {
      typeof(self) strongSelf = weakSelf;
      if (strongSelf != nil) {
        [strongSelf onMethodCall:call result:result];
      }
    }];
  }
  return self;
}

- (UIView *)view {
  return _view;
}

- (void)onMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"getInternalView" isEqualToString:call.method]) {
    result(@((uint64_t)(_view)));
  } else {
    result(@(0));
  }
}

@end
