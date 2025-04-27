#import "PlayerView.h"

#import <AVKit/AVKit.h>

@interface PlayerView ()

@property(nonatomic, strong)
    AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;

@property(nonatomic, strong) NSArray<UIImage *> *images;
@property(nonatomic, strong) NSTimer *loopTimer;
@property(nonatomic, strong) id timeObserver;

@end

@implementation PlayerView

+ (Class)layerClass {
  return [AVSampleBufferDisplayLayer class];
}

- (AVSampleBufferDisplayLayer *)sampleBufferDisplayLayer {
  return (AVSampleBufferDisplayLayer *)self.layer;
}

- (instancetype)init {
  if (self = [super init]) {
    CMTimebaseRef timebase;
    CMTimebaseCreateWithSourceClock(nil, CMClockGetHostTimeClock(), &timebase);
    CMTimebaseSetTime(timebase, kCMTimeZero);
    CMTimebaseSetRate(timebase, 1);
    self.sampleBufferDisplayLayer.controlTimebase = timebase;
    if (timebase) {
      CFRelease(timebase);
    }

    [self play];
  }
  return self;
}

- (void)play {
  if (!self.isPlaying) {
    __block NSInteger index = 0;
    __weak typeof(self) weakSelf = self;
    self.loopTimer = [NSTimer
        scheduledTimerWithTimeInterval:2.0
                               repeats:YES
                                 block:^(NSTimer *_Nonnull timer) {
                                   CVPixelBufferRef pxbuffer =
                                       [PlayerView CVPixelBufferRefFromUiImage:
                                                       weakSelf.images[index]];
                                   [weakSelf __displayPixelBuffer:pxbuffer];

                                   index++;

                                   if (index >= weakSelf.images.count) {
                                     index = 0;
                                   }
                                 }];
    [self.loopTimer fire];
  }
}

- (void)pause {
  if (self.isPlaying) {
    [self.loopTimer invalidate];
    self.loopTimer = nil;
  }
}

- (BOOL)isPlaying {
  return self.loopTimer != nil;
}

- (CMTime)duration {
  return CMTimeMake(self.images.count * 2, 1);
}

- (NSArray<UIImage *> *)images {
  if (!_images) {
    NSMutableArray<UIImage *> *images = @[].mutableCopy;
    [@[ @"PIP1", @"PIP2", @"PIP3" ]
        enumerateObjectsUsingBlock:^(NSString *imgName, NSUInteger idx,
                                     BOOL *_Nonnull stop) {
          NSString *imagePath = [[NSBundle mainBundle] pathForResource:imgName
                                                                ofType:@"png"];
          UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
          [images addObject:image];
        }];
    _images = [images copy];
  }
  return _images;
}

- (void)__displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
  if (!pixelBuffer) {
    return;
  }

  CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
  CMVideoFormatDescriptionRef videoInfo = NULL;
  OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(
      NULL, pixelBuffer, &videoInfo);

  CMSampleBufferRef sampleBuffer = NULL;
  result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer,
                                              true, NULL, NULL, videoInfo,
                                              &timing, &sampleBuffer);
  CFRelease(pixelBuffer);
  CFRelease(videoInfo);

  CFArrayRef attachments =
      CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
  CFMutableDictionaryRef dict =
      (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
  CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately,
                       kCFBooleanTrue);

  if (self.sampleBufferDisplayLayer.status ==
      AVQueuedSampleBufferRenderingStatusFailed) {
    [self.sampleBufferDisplayLayer flush];
  }

  [self.sampleBufferDisplayLayer enqueueSampleBuffer:sampleBuffer];
  CFRelease(sampleBuffer);
}

#pragma mark - Convert UIImage to CVPixelBuffer

static OSType inputPixelFormat() { return kCVPixelFormatType_32BGRA; }

static uint32_t bitmapInfoWithPixelFormatType(OSType inputPixelFormat,
                                              bool hasAlpha) {

  if (inputPixelFormat == kCVPixelFormatType_32BGRA) {
    uint32_t bitmapInfo =
        kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
    if (!hasAlpha) {
      bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host;
    }
    return bitmapInfo;
  } else if (inputPixelFormat == kCVPixelFormatType_32ARGB) {
    uint32_t bitmapInfo =
        kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big;
    return bitmapInfo;
  } else {
    NSLog(@"不支持此格式");
    return 0;
  }
}

// alpha的判断
static BOOL CGImageRefContainsAlpha(CGImageRef imageRef) {
  if (!imageRef) {
    return NO;
  }
  CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
  BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                    alphaInfo == kCGImageAlphaNoneSkipFirst ||
                    alphaInfo == kCGImageAlphaNoneSkipLast);
  return hasAlpha;
}

// 此方法能还原真实的图片
+ (CVPixelBufferRef)CVPixelBufferRefFromUiImage:(UIImage *)img {
  CGSize size = img.size;
  CGImageRef image = [img CGImage];

  BOOL hasAlpha = CGImageRefContainsAlpha(image);
  CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0,
                                             &kCFTypeDictionaryKeyCallBacks,
                                             &kCFTypeDictionaryValueCallBacks);

  NSDictionary *options = [NSDictionary
      dictionaryWithObjectsAndKeys:
          [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
          [NSNumber numberWithBool:YES],
          kCVPixelBufferCGBitmapContextCompatibilityKey, empty,
          kCVPixelBufferIOSurfacePropertiesKey, nil];
  CVPixelBufferRef pxbuffer = NULL;
  CVReturn status = CVPixelBufferCreate(
      kCFAllocatorDefault, size.width, size.height, inputPixelFormat(),
      (__bridge CFDictionaryRef)options, &pxbuffer);

  NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

  CVPixelBufferLockBaseAddress(pxbuffer, 0);
  void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
  NSParameterAssert(pxdata != NULL);

  CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();

  uint32_t bitmapInfo =
      bitmapInfoWithPixelFormatType(inputPixelFormat(), (bool)hasAlpha);

  CGContextRef context = CGBitmapContextCreate(
      pxdata, size.width, size.height, 8, CVPixelBufferGetBytesPerRow(pxbuffer),
      rgbColorSpace, bitmapInfo);
  NSParameterAssert(context);

  CGContextDrawImage(
      context,
      CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
  CVPixelBufferUnlockBaseAddress(pxbuffer, 0);

  CGColorSpaceRelease(rgbColorSpace);
  CGContextRelease(context);

  return pxbuffer;
}

@end
