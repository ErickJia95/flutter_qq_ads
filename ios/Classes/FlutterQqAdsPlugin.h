#import <Flutter/Flutter.h>
#import "FAQSplashPage.h"
#import "FAQInterstitialPage.h"
#import "FAQRewardVideoPage.h"
#import "FAQFeedAdLoad.h"
#import "FAQFeedAdManager.h"
#import "FAQNativeAdLoad.h"
#import "FAQNativeAdManager.h"

@interface FlutterQqAdsPlugin : NSObject<FlutterPlugin,FlutterStreamHandler>
@property (strong, nonatomic) FlutterEventSink eventSink;
@property (strong, nonatomic) FAQSplashPage *sad;
@property (strong, nonatomic) FAQInterstitialPage *iad;
@property (strong, nonatomic) FAQRewardVideoPage *rvad;
@property (strong, nonatomic) FAQFeedAdLoad *fad;
@property (strong, nonatomic) FAQNativeAdLoad *nad;

extern NSString *const kFAQAdBannerViewId;
extern NSString *const kFAQAdFeedViewId;
extern NSString *const kFAQAdNativeViewId;
@end
