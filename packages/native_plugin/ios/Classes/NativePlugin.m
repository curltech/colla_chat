#import "NativePlugin.h"
#import "FLNativeView.h"
#import "PlayerView.h"

#import <AVKit/AVKit.h>

@interface NativePlugin ()

@property(nonatomic, strong) NSMutableArray *_Nonnull pipContentViewArray;

@end

@implementation NativePlugin

+ (void)updateAudioSession {
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  NSError *categoryError = nil;
  if (@available(iOS 14.5, *)) {
    [audioSession
        setCategory:AVAudioSessionCategoryPlayback
               mode:AVAudioSessionModeMoviePlayback
            options:
                AVAudioSessionCategoryOptionOverrideMutedMicrophoneInterruption
              error:&categoryError];
  } else {
    // Fallback on earlier versions
  }
  if (categoryError) {
    NSLog(@"Set audio session category error: %@",
          categoryError.localizedDescription);
  }
  NSError *activeError = nil;
  [audioSession setActive:YES error:&activeError];
  if (activeError) {
    NSLog(@"Set audio session active error: %@",
          activeError.localizedDescription);
  }
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  // must call this, otherwise pip will not possible
  // https://github.com/jazzychad/PiPBugDemo
  [NativePlugin updateAudioSession];

  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"native_plugin"
                                  binaryMessenger:[registrar messenger]];
  NativePlugin *instance = [[NativePlugin alloc] init];

  FLNativeViewFactory *factory =
      [[FLNativeViewFactory alloc] initWithMessenger:registrar.messenger];
  [registrar registerViewFactory:factory withId:@"native_view"];

  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _pipContentViewArray = [NSMutableArray array];
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS "
        stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"createPipContentView" isEqualToString:call.method]) {
    PlayerView *playerView = [[PlayerView alloc] init];

    // should control the play state by event of pip, optimize it later
    [playerView play];

    [self.pipContentViewArray addObject:playerView];

    result(@((uint64_t)playerView));
  } else if ([@"disposePipContentView" isEqualToString:call.method]) {
    uint64_t viewId = [call.arguments unsignedLongLongValue];
    for (PlayerView *playerView in self.pipContentViewArray) {
      if ((uint64_t)playerView == viewId) {
        [playerView pause];
        [self.pipContentViewArray removeObject:playerView];
        break;
      }
    }
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
