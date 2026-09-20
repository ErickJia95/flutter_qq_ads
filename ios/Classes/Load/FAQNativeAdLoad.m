#import <TargetConditionals.h>
#if TARGET_OS_SIMULATOR
// ZW_ARM64_SIMULATOR_STUB
#import "FAQNativeAdLoad.h"

@implementation FAQNativeAdLoad
- (void)loadNativeAdList:(FlutterMethodCall *)call result:(FlutterResult)result eventSink:(FlutterEventSink)events {
    result(@[]);
}
@end

#else
//
//  FAQNativeAdLoad.m
//  flutter_qq_ads
//

#import "FAQNativeAdLoad.h"
#import "FAQNativeAdManager.h"
#import <GDTMobSDK/GDTUnifiedNativeAd.h>
#import <GDTMobSDK/GDTUnifiedNativeAdDataObject.h>

@interface FAQNativeAdLoad()<GDTUnifiedNativeAdDelegate>
@property (strong, nonatomic) GDTUnifiedNativeAd *ad;
@property (copy, nonatomic) FlutterResult result;
@end

@implementation FAQNativeAdLoad

- (void)loadNativeAdList:(FlutterMethodCall *)call result:(FlutterResult)result eventSink:(FlutterEventSink)events {
    self.result = result;
    [self showAd:call eventSink:events];
}

- (void)loadAd:(FlutterMethodCall *)call {
    NSInteger count = [call.arguments[@"count"] integerValue];
    self.ad = [[GDTUnifiedNativeAd alloc] initWithPlacementId:self.posId];
    self.ad.delegate = self;
    [self.ad loadAdWithAdCount:count];
}

- (void)gdt_unifiedNativeAdLoaded:(NSArray<GDTUnifiedNativeAdDataObject *> *)unifiedNativeAdDataObjects
                            error:(NSError *)error {
    if (error != nil) {
        [self sendErrorEvent:error.code withErrMsg:error.localizedDescription ?: @"native load error"];
        self.result(@[]);
        return;
    }
    NSMutableArray *resultList = [NSMutableArray array];
    for (GDTUnifiedNativeAdDataObject *dataObject in unifiedNativeAdDataObjects) {
        if (dataObject == nil || !dataObject.isAdValid) {
            continue;
        }
        if (dataObject.isVideoAd) {
            continue;
        }
        NSNumber *key = @([dataObject hash]);
        [FAQNativeAdManager.share putAd:key value:dataObject];
        [resultList addObject:[self nativeMap:key ad:dataObject]];
    }
    [self sendEventAction:onAdLoaded];
    self.result(resultList);
}

- (NSDictionary *)nativeMap:(NSNumber *)key ad:(GDTUnifiedNativeAdDataObject *)ad {
    NSArray *imgUrls = ad.imageUrl.length > 0 ? @[ad.imageUrl] : @[];
    return @{
        @"adId": key,
        @"title": ad.title ?: @"",
        @"desc": ad.desc ?: @"",
        @"iconUrl": ad.iconUrl ?: @"",
        @"imgUrls": imgUrls,
        @"buttonText": ad.buttonText ?: @"",
        @"source": @"",
        @"patternType": @"NATIVE_1IMAGE_2TEXT",
        @"ecpm": @([ad eCPM]),
        @"isAppAd": @(ad.isAppAd),
        @"hasApp": @(ad.isAppAd ? 1 : 0),
    };
}

@end

#endif
